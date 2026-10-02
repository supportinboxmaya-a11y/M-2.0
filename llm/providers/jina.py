import os
from config.settings import env_first
from typing import List, Dict, Optional, Generator
import requests

from llm.providers.base import BaseProvider, RetryConfig


class JinaProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="JINA_API_KEY",
            default_model=os.environ.get("JINA_MODEL", "jina-embeddings-v3"),
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=60.0,
        )

    def _initialize_client(self):
        key = env_first("JINA_API_KEY", "JINA_API_KEY")
        if key:
            self.api_key = key
            self.client = requests.Session()
            self.client.headers.update({
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
            })
            self.base_url = "https://api.jina.ai/v1"
        else:
            self.client = None
            self.api_key = None

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("Jina error: JINA_API_KEY not configured")
        use_model = self._get_model(model)
        response = self.client.post(
            f"{self.base_url}/chat/completions",
            json={
                "model": use_model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.7,
            },
            timeout=self.timeout,
        )
        response.raise_for_status()
        data = response.json()
        self._report_usage_json(use_model, data.get("usage", {}))
        return data["choices"][0]["message"]["content"]

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("Jina error: JINA_API_KEY not configured")
        use_model = self._get_model(model)
        response = self.client.post(
            f"{self.base_url}/chat/completions",
            json={
                "model": use_model,
                "messages": messages,
                "max_tokens": max_tokens,
                "temperature": 0.7,
                "stream": True,
            },
            stream=True,
            timeout=self.timeout,
        )
        response.raise_for_status()
        for line in response.iter_lines():
            if line:
                line = line.decode("utf-8")
                if line.startswith("data: "):
                    data_str = line[6:]
                    if data_str == "[DONE]":
                        break
                    try:
                        import json
                        data = json.loads(data_str)
                        delta = data["choices"][0]["delta"].get("content")
                        if delta:
                            yield delta
                    except Exception:
                        pass

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None