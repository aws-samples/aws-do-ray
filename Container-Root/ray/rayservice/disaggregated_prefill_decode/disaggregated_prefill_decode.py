"""
Disaggregated Prefill/Decode Serving with Ray Serve LLM

This example demonstrates how to deploy an LLM with prefill/decode
disaggregation using Ray Serve's built-in LLM APIs and vLLM's
NIXLConnector for KV cache transfer.

Disaggregated serving separates the prefill phase (processing input
prompts) from the decode phase (generating tokens), enabling:

  - Independent scaling of prefill and decode replicas
  - Reduced interference between compute-bound prefill and
    memory-bound decode
  - Cost optimization via heterogeneous hardware

Prerequisites:
  - Ray >= 2.44 with ray[serve] installed
  - vLLM v1 (default engine)
  - NIXL: pip install nixl (pre-installed in ray-llm images)
  - GPU workers with enough VRAM for the model

Usage:
  # Deploy via Ray Serve config (recommended for Kubernetes)
  serve deploy rayservice.disaggregated_prefill_decode.yaml

  # Or run directly with Python
  python disaggregated_prefill_decode.py

  # Test the endpoint
  python disaggregated_prefill_decode_req.py
"""

from ray.serve.llm import LLMConfig, build_pd_openai_app
import ray.serve as serve

# Model to serve — change to any HuggingFace model you have access to.
MODEL_ID = "meta-llama/Llama-3.1-8B-Instruct"

# ── Prefill instance configuration ──────────────────────────────────
# The prefill instance processes input prompts and produces KV cache
# entries that are transferred to decode instances via NIXL.
prefill_config = LLMConfig(
    model_loading_config={
        "model_id": MODEL_ID,
    },
    deployment_config={
        "autoscaling_config": {
            "min_replicas": 1,
            "max_replicas": 2,
        }
    },
    accelerator_type="A10G",
    engine_kwargs={
        "kv_transfer_config": {
            "kv_connector": "NixlConnector",
            "kv_role": "kv_both",
        },
    },
)

# ── Decode instance configuration ───────────────────────────────────
# The decode instance generates tokens autoregressively, consuming
# KV cache entries produced by the prefill instance.
decode_config = LLMConfig(
    model_loading_config={
        "model_id": MODEL_ID,
    },
    deployment_config={
        "autoscaling_config": {
            "min_replicas": 1,
            "max_replicas": 4,
        }
    },
    accelerator_type="A10G",
    engine_kwargs={
        "kv_transfer_config": {
            "kv_connector": "NixlConnector",
            "kv_role": "kv_both",
        },
    },
)

# ── Build and deploy ────────────────────────────────────────────────
# build_pd_openai_app creates an OpenAI-compatible API with a router
# that directs requests to prefill instances first, then hands off
# KV cache to decode instances for token generation.
pd_config = dict(
    prefill_config=prefill_config,
    decode_config=decode_config,
)

app = build_pd_openai_app(pd_config)

if __name__ == "__main__":
    serve.run(app)
    print(f"\nDisaggregated serving is running for {MODEL_ID}")
    print("Send requests to http://localhost:8000/v1/chat/completions")
    print("Press Ctrl+C to stop.\n")

    # Keep the process alive
    import time
    try:
        while True:
            time.sleep(10)
    except KeyboardInterrupt:
        print("Shutting down...")
