import os
import json
import httpx
from config.settings import env_first
from typing import List, Dict, Optional, Generator

from llm.providers.base import BaseProvider, RetryConfig


NVIDIA_NIM_BASE_URL = "https://integrate.api.nvidia.com/v1"


class NvidiaNimProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="NVIDIA_NIM_KEY",
            default_model=os.environ.get("NVIDIA_NIM_MODEL", "meta/llama-3.3-70b-instruct"),
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=float(os.environ.get("NVIDIA_NIM_TIMEOUT", "180")),
        )

    def _initialize_client(self):
        key = env_first("NVIDIA_NIM_KEY", "NVIDIA_NIM_API_KEY")
        if key:
            self.api_key = key
            self.client = httpx.Client(base_url=NVIDIA_NIM_BASE_URL, timeout=60.0)

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("NVIDIA NIM error: NVIDIA_NIM_KEY not configured")
        use_model = self._get_model(model)
        payload = {
            "model": use_model,
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
        _u = data.get("usage") or {}
        self._report_usage_json(use_model if "use_model" in dir() else data.get("model", ""), _u)
        return data["choices"][0]["message"]["content"]

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("NVIDIA NIM error: NVIDIA_NIM_KEY not configured")
        use_model = self._get_model(model)
        payload = {
            "model": use_model,
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
                    try:
                        data = json.loads(chunk)
                        choices = data.get("choices", [])
                        if choices:
                            delta = choices[0].get("delta", {})
                            content = delta.get("content")
                            if content:
                                yield content
                    except json.JSONDecodeError:
                        continue

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None