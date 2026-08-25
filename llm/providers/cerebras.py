import os
from config.settings import env_first
from typing import List, Dict, Optional, Generator
from openai import OpenAI

from llm.providers.base import BaseProvider, RetryConfig


CEREBRAS_BASE_URL = "https://api.cerebras.ai/v1"


class CerebrasProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="CEREBRAS_KEY",
            default_model=os.environ.get("CEREBRAS_MODEL", "llama-3.3-70b"),
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=60.0,
        )

    def _initialize_client(self):
        key = env_first("CEREBRAS_KEY", "CEREBRAS_API_KEY")
        if key:
            try:
                self.client = OpenAI(api_key=key, base_url=CEREBRAS_BASE_URL)
                self.api_key = key
            except Exception:
                self.client = None
                self.api_key = None

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("Cerebras error: CEREBRAS_KEY not configured")
        use_model = self._get_model(model)
        response = self.client.chat.completions.create(
            model=use_model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=0.7,
        )
        return response.choices[0].message.content

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("Cerebras error: CEREBRAS_KEY not configured")
        use_model = self._get_model(model)
        stream = self.client.chat.completions.create(
            model=use_model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=0.7,
            stream=True,
        )
        for chunk in stream:
            delta = chunk.choices[0].delta.content
            if delta:
                yield delta

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None