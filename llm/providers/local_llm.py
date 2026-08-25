import os
import json
import requests
from typing import List, Dict, Optional, Generator

from llm.providers.base import BaseProvider, RetryConfig


class LocalLLMProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="",  # No API key needed
            default_model=os.environ.get("LOCAL_MODEL", "llama3"),
            retry_config=RetryConfig(max_retries=2, base_delay=2.0, max_delay=30.0),
            timeout=120.0,
        )

    def _initialize_client(self):
        self.base_url = os.environ.get("LOCAL_LLM_URL", "http://localhost:11434")
        self.api_key = "local"  # Always "available" if Ollama is running
        self.client = True  # Just a marker

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("Local LLM error: Ollama not available")
        use_model = self._get_model(model)
        prompt = "\n".join([f"{m['role']}: {m['content']}" for m in messages])
        response = requests.post(
            f"{self.base_url}/api/generate",
            json={"model": use_model, "prompt": prompt, "stream": False},
            timeout=self.timeout
        )
        return response.json().get("response", "")

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("Local LLM error: Ollama not available")
        use_model = self._get_model(model)
        prompt = "\n".join([f"{m['role']}: {m['content']}" for m in messages])
        response = requests.post(
            f"{self.base_url}/api/generate",
            json={"model": use_model, "prompt": prompt, "stream": True},
            timeout=self.timeout,
            stream=True
        )
        for line in response.iter_lines():
            if line:
                try:
                    data = json.loads(line)
                    if "response" in data:
                        yield data["response"]
                except json.JSONDecodeError:
                    continue

    def is_available(self) -> bool:
        try:
            requests.get(f"{self.base_url}/api/tags", timeout=3)
            return True
        except Exception:
            return False