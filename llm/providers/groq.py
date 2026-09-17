import os
from config.settings import env_first
from typing import List, Dict, Optional, Generator
from groq import Groq

from llm.providers.base import BaseProvider, RetryConfig


class GroqProvider(BaseProvider):
    def __init__(self):
        super().__init__(
            api_key_env="GROQ_KEY",
            default_model=os.environ.get("PRIMARY_MODEL", "openai/gpt-oss-120b"),
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=60.0,
        )

    def _initialize_client(self):
        key = env_first("GROQ_KEY", "GROQ_API_KEY")
        if key:
            try:
                self.client = Groq(api_key=key)
                self.api_key = key
            except Exception as e:
                self.client = None
                self.api_key = None

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("Groq error: GROQ_KEY not configured")
        use_model = self._get_model(model)
        # Map deprecated model names
        old_models = {
            "llama3-8b-8192": "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile": "openai/gpt-oss-120b",
            "llama3-70b-8192": "openai/gpt-oss-120b",
            "mixtral-8x7b-32768": "openai/gpt-oss-120b",
            "gemma-7b-it": "llama-3.1-8b-instant",
        }
        use_model = old_models.get(use_model, use_model)
        response = self.client.chat.completions.create(
            model=use_model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=0.7,
        )
        self._report_usage(use_model, response)
        return response.choices[0].message.content

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("Groq error: GROQ_KEY not configured")
        use_model = self._get_model(model)
        old_models = {
            "llama3-8b-8192": "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile": "openai/gpt-oss-120b",
            "llama3-70b-8192": "openai/gpt-oss-120b",
            "mixtral-8x7b-32768": "openai/gpt-oss-120b",
            "gemma-7b-it": "llama-3.1-8b-instant",
        }
        use_model = old_models.get(use_model, use_model)
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