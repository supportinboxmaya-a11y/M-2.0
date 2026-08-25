import os
from config.settings import env_first
from typing import List, Dict, Optional, Generator
import anthropic

from llm.providers.base import BaseProvider, RetryConfig


class ClaudeProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="ANTHROPIC_KEY",
            default_model="claude-3-5-sonnet-20241022",
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=60.0,
        )

    def _initialize_client(self):
        key = env_first("ANTHROPIC_KEY", "ANTHROPIC_API_KEY")
        if key:
            try:
                self.client = anthropic.Anthropic(api_key=key)
                self.api_key = key
            except Exception:
                self.client = None
                self.api_key = None

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("Claude error: ANTHROPIC_KEY not configured")
        use_model = self._get_model(model)
        system = ""
        filtered = []
        for msg in messages:
            if msg["role"] == "system":
                system = msg["content"]
            else:
                filtered.append(msg)
        response = self.client.messages.create(
            model=use_model,
            max_tokens=max_tokens,
            system=system,
            messages=filtered,
        )
        return response.content[0].text

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("Claude error: ANTHROPIC_KEY not configured")
        use_model = self._get_model(model)
        system = ""
        filtered = []
        for msg in messages:
            if msg["role"] == "system":
                system = msg["content"]
            else:
                filtered.append(msg)
        with self.client.messages.stream(
            model=use_model,
            max_tokens=max_tokens,
            system=system,
            messages=filtered,
        ) as stream:
            for text in stream.text_stream:
                if text:
                    yield text

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None