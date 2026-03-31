"""
Test client for the disaggregated prefill/decode serving example.

Sends a chat completion request to the Ray Serve endpoint and
streams the response.

Prerequisites:
  - The disaggregated serving deployment must be running
    (see disaggregated_prefill_decode.py or the RayService YAML)
  - Port 8000 must be accessible (use kubectl port-forward for K8s)

Usage:
  python disaggregated_prefill_decode_req.py
"""

import requests
import json
import sys

URL = "http://127.0.0.1:8000/v1/chat/completions"

MODEL_ID = "meta-llama/Llama-3.1-8B-Instruct"


def test_chat_completion():
    """Send a basic chat completion request."""
    payload = {
        "model": MODEL_ID,
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant. Be concise.",
            },
            {
                "role": "user",
                "content": "Explain the benefits of disaggregated prefill and decode for LLM serving in 3 bullet points.",
            },
        ],
        "max_tokens": 256,
        "temperature": 0.7,
    }

    print(f"Sending request to {URL} ...")
    print(f"Model: {MODEL_ID}")
    print("-" * 60)

    try:
        response = requests.post(
            URL,
            headers={"Content-Type": "application/json"},
            json=payload,
            timeout=120,
        )
        response.raise_for_status()
        result = response.json()

        # Print the response
        message = result["choices"][0]["message"]["content"]
        print(f"\nResponse:\n{message}")

        # Print usage stats if available
        if "usage" in result:
            usage = result["usage"]
            print(f"\nTokens — prompt: {usage.get('prompt_tokens', 'N/A')}, "
                  f"completion: {usage.get('completion_tokens', 'N/A')}, "
                  f"total: {usage.get('total_tokens', 'N/A')}")

    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect to the serving endpoint.")
        print("Make sure the deployment is running and port 8000 is forwarded.")
        print("\n  kubectl port-forward svc/<service-name> 8000")
        sys.exit(1)
    except requests.exceptions.HTTPError as e:
        print(f"ERROR: HTTP {e.response.status_code}")
        print(e.response.text)
        sys.exit(1)


def test_streaming():
    """Send a streaming chat completion request."""
    payload = {
        "model": MODEL_ID,
        "messages": [
            {
                "role": "user",
                "content": "Write a haiku about distributed systems.",
            },
        ],
        "max_tokens": 64,
        "temperature": 0.9,
        "stream": True,
    }

    print("\nStreaming request:")
    print("-" * 60)

    try:
        response = requests.post(
            URL,
            headers={"Content-Type": "application/json"},
            json=payload,
            stream=True,
            timeout=120,
        )
        response.raise_for_status()

        for line in response.iter_lines():
            if line:
                decoded = line.decode("utf-8")
                if decoded.startswith("data: "):
                    data = decoded[6:]
                    if data.strip() == "[DONE]":
                        break
                    try:
                        chunk = json.loads(data)
                        delta = chunk["choices"][0].get("delta", {})
                        content = delta.get("content", "")
                        if content:
                            print(content, end="", flush=True)
                    except json.JSONDecodeError:
                        pass
        print("\n")

    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect for streaming.")
        sys.exit(1)


if __name__ == "__main__":
    test_chat_completion()
    test_streaming()
