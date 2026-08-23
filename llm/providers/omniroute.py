import os
import json
import httpx
from config.settings import env_first, OMNIROUTE_BASE_URL, OMNIROUTE_API_KEY
from typing import List, Dict, Optional, Generator

# OMNIROUTE_BASE_URL = env_first("OMNIROUTE_BASE_URL", "http://localhost:3000/api/v1")


class OmniRouteProvider:
    def __init__(self):
        self.api_key = None
        self.client = None
        key = OMNIROUTE_API_KEY
        if key:
            self.api_key = key
            self.client = httpx.Client(base_url=OMNIROUTE_BASE_URL, timeout=60.0)
        self.default_model = os.environ.get(
            "OMNIROUTE_MODEL", "nvidia/nemotron-3-ultra-550b-a55b"
        )

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("OmniRoute error: OMNIROUTE_API_KEY not configured")
        try:
            payload = {
                "model": model or self.default_model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.7,
                "stream": False,
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
            raise Exception(f"OmniRoute error: {e}")

    def stream_chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("OmniRoute error: OMNIROUTE_API_KEY not configured")
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
        except Exception as e:
            raise Exception(f"OmniRoute streaming error: {e}")

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None