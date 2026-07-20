import os
import json
import httpx
from config.settings import env_first
from typing import List, Dict, Optional, Generator

# NVIDIA NIM exposes an OpenAI-compatible endpoint.
NVIDIA_NIM_BASE_URL = "https://integrate.api.nvidia.com/v1"


class NvidiaNimProvider:
    def __init__(self):
        self.api_key = None
        self.client = None
        key = env_first("NVIDIA_NIM_KEY", "NVIDIA_NIM_API_KEY")
        if key:
            self.api_key = key
            self.client = httpx.Client(base_url=NVIDIA_NIM_BASE_URL, timeout=60.0)
        self.default_model = os.environ.get(
            "NVIDIA_NIM_MODEL", "deepseek-ai/deepseek-v4-pro"
        )

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("NVIDIA NIM error: NVIDIA_NIM_KEY not configured")
        try:
            payload = {
                "model": model or self.default_model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.7,
            }
            response = self.client.post(
                "/chat/completions",
                json=payload,
                headers={"Authorization": f"Bearer {self.api_key}"},
            )
            response.raise_for_status()
            data = response.json()
            return data["choices"][0]["message"]["content"]
        except Exception as e:
            raise Exception(f"NVIDIA NIM error: {e}")

    def stream_chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("NVIDIA NIM error: NVIDIA_NIM_KEY not configured")
        try:
            payload = {
                "model": model or self.default_model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.7,
                "stream": True,
            }
            with self.client.stream(
                "POST",
                "/chat/completions",
                json=payload,
                headers={"Authorization": f"Bearer {self.api_key}"},
            ) as response:
                response.raise_for_status()
                for line in response.iter_lines():
                    if line.startswith("data: "):
                        chunk = line[6:]
                        if chunk.strip() == "[DONE]":
                            break
                        data = json.loads(chunk)
                        delta = data["choices"][0].get("delta", {}).get("content")
                        if delta:
                            yield delta
        except Exception as e:
            raise Exception(f"NVIDIA NIM streaming error: {e}")

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None
