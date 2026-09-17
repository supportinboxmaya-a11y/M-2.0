import os
from config.settings import env_first
from typing import List, Dict, Optional, Generator
from openai import OpenAI

from llm.providers.base import BaseProvider, RetryConfig


class OpenAIProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="OPENAI_KEY",
            default_model="gpt-4o-mini",
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=60.0,
        )

    def _initialize_client(self):
        key = env_first("OPENAI_KEY", "OPENAI_API_KEY")
        if key:
            try:
                self.client = OpenAI(api_key=key)
                self.api_key = key
            except Exception:
                self.client = None
                self.api_key = None

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("OpenAI error: OPENAI_KEY not configured")
        use_model = self._get_model(model)
        response = self.client.chat.completions.create(
            model=use_model,
            messages=messages,
            max_tokens=max_tokens,
        )
        self._report_usage(use_model, response)
        return response.choices[0].message.content

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("OpenAI error: OPENAI_KEY not configured")
        use_model = self._get_model(model)
        stream = self.client.chat.completions.create(
            model=use_model,
            messages=messages,
            max_tokens=max_tokens,
            stream=True,
        )
        for chunk in stream:
            delta = chunk.choices[0].delta.content
            if delta:
                yield delta

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None