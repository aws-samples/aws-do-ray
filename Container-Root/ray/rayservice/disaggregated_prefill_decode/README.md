# Disaggregated Prefill/Decode Serving

This example demonstrates **disaggregated prefill/decode** serving for LLMs using [Ray Serve LLM](https://docs.ray.io/en/latest/serve/llm/user-guides/prefill-decode.html) with vLLM's [NIXLConnector](https://docs.vllm.ai/en/stable/features/nixl_connector_usage.html).

## What is Disaggregated Serving?

Traditional LLM inference colocates two phases on the same GPU:

1. **Prefill** — processes the full input prompt in parallel (compute-bound, high FLOPS)
2. **Decode** — generates tokens one at a time autoregressively (memory-bandwidth-bound)

When colocated, these phases interfere with each other: a long prefill blocks decode and increases inter-token latency (ITL), while ongoing decode delays new prefill requests and increases time-to-first-token (TTFT).

**Disaggregated serving** separates them onto dedicated instances connected via high-speed KV cache transfer (NIXL), enabling:

| Benefit | Description |
|---|---|
| **Independent scaling** | Scale prefill and decode replicas separately based on demand |
| **Reduced interference** | Prefill doesn't block decode and vice versa |
| **Cost optimization** | Use different instance types for different workloads |
| **Better latency** | Optimize TTFT and ITL independently |

## Architecture

```
                    ┌─────────────────┐
                    │   Ray Serve     │
                    │   Router        │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
     ┌────────▼────────┐          ┌────────▼────────┐
     │  Prefill Pool   │   NIXL   │  Decode Pool    │
     │  (compute-bound)│ ──────►  │  (memory-bound) │
     │  1-2 replicas   │ KV cache │  1-4 replicas   │
     └─────────────────┘ transfer └─────────────────┘
```

## Files

| File | Description |
|---|---|
| `disaggregated_prefill_decode.py` | Python deployment script (can run standalone) |
| `rayservice.disaggregated_prefill_decode.yaml` | KubeRay RayService manifest for Kubernetes |
| `disaggregated_prefill_decode_req.py` | Test client with chat completion and streaming |

## Prerequisites

- **Ray** >= 2.44 with `ray[serve]`
- **vLLM** v1 (default engine in Ray Serve LLM)
- **NIXL**: `pip install nixl` (pre-installed in `rayproject/ray-llm` images)
- **GPU nodes** with sufficient VRAM (e.g., NVIDIA A10G for Llama-3.1-8B)
- **HuggingFace token** with access to `meta-llama/Llama-3.1-8B-Instruct`

## Quick Start

### Option 1: Kubernetes (RayService)

```bash
# From the rayservice directory
./rayservice-create.sh disaggregated_prefill_decode

# Check status
./rayservice-status.sh

# Wait for pods to be ready, then test
./rayservice-test.sh disaggregated_prefill_decode
```

### Option 2: Direct Python

```bash
# Install dependencies
pip install "ray[serve]" vllm nixl

# Set HuggingFace token
export HF_TOKEN=<your-token>

# Deploy
python disaggregated_prefill_decode.py

# In another terminal, test
python disaggregated_prefill_decode_req.py
```

### Option 3: Ray Serve CLI

```bash
# Deploy from YAML (extract the serveConfigV2 section)
serve deploy rayservice.disaggregated_prefill_decode.yaml

# Test
curl -X POST http://localhost:8000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "meta-llama/Llama-3.1-8B-Instruct",
    "messages": [{"role": "user", "content": "Hello!"}],
    "max_tokens": 64
  }'
```

## Configuration

### Changing the Model

Update `model_id` in both the prefill and decode configs:

```yaml
prefill_config:
  model_loading_config:
    model_id: your-org/your-model
decode_config:
  model_loading_config:
    model_id: your-org/your-model
```

### Scaling

Adjust `min_replicas` / `max_replicas` independently for each phase. A typical pattern is more decode replicas than prefill, since decode is the longer-running phase:

```yaml
prefill_config:
  deployment_config:
    autoscaling_config:
      min_replicas: 2
      max_replicas: 4

decode_config:
  deployment_config:
    autoscaling_config:
      min_replicas: 6
      max_replicas: 10
```

### GPU Instance Types (AWS)

| Instance | GPU | VRAM | Best For |
|---|---|---|---|
| g5.xlarge | 1x A10G | 24 GB | Small models (7-8B) |
| g5.2xlarge | 1x A10G | 24 GB | Small models, more CPU/RAM |
| p4d.24xlarge | 8x A100 | 320 GB | Large models (70B+) |
| p5.48xlarge | 8x H100 | 640 GB | Largest models, highest throughput |

### Alternative KV Transfer Backends

This example uses NIXLConnector. For advanced caching, you can switch to LMCacheConnectorV1:

```yaml
engine_kwargs:
  kv_transfer_config:
    kv_connector: LMCacheConnectorV1
    kv_role: kv_producer  # or kv_consumer
```

See the [Ray Serve docs](https://docs.ray.io/en/latest/serve/llm/user-guides/prefill-decode.html) for LMCache and Mooncake backend configurations.

## References

- [Ray Serve Prefill/Decode Disaggregation Guide](https://docs.ray.io/en/latest/serve/llm/user-guides/prefill-decode.html)
- [vLLM NIXLConnector Usage](https://docs.vllm.ai/en/stable/features/nixl_connector_usage.html)
- [DistServe Paper — Disaggregated Inference](https://arxiv.org/abs/2401.09670)
- [Anyscale Blog — Wide-EP and Disaggregated Serving](https://www.anyscale.com/blog/ray-serve-llm-anyscale-apis-wide-ep-disaggregated-serving-vllm)
