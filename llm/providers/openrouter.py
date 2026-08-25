import os
from config.settings import env_first
from typing import List, Dict, Optional, Generator, Callable
from openai import OpenAI

from llm.providers.base import BaseProvider, RetryConfig


OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"


class OpenRouterProvider(BaseProvider):
    def __init__(self, http_fn: Optional[Callable] = None):
        super().__init__(
            api_key_env="OPENROUTER_KEY",
            # meta-llama/llama-3.3-70b-instruct:free was retired from the
            # free tier (404, 2026-08); nemotron-3-super-120b verified live.
            default_model=os.environ.get(
                "OPENROUTER_MODEL", "nvidia/nemotron-3-super-120b-a12b:free"),
            retry_config=RetryConfig(max_retries=3, base_delay=1.0, max_delay=30.0),
            timeout=60.0,
        )
        self._http_fn = http_fn

    def _initialize_client(self):
        key = env_first("OPENROUTER_KEY", "OPENROUTER_API_KEY")
        if key:
            try:
                self.client = OpenAI(
                    api_key=key,
                    base_url=OPENROUTER_BASE_URL,
                    default_headers={
                        "HTTP-Referer": "https://m-2-0-1.onrender.com",
                        "X-Title": "Maya",
                    },
                )
                self.api_key = key
            except Exception:
                self.client = None
                self.api_key = None

    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        if not self.client:
            raise Exception("OpenRouter error: OPENROUTER_KEY not configured")
        use_model = self._get_model(model)
        if self._http_fn:
            response = self._http_fn(
                f"{OPENROUTER_BASE_URL}/chat/completions",
                {"model": use_model, "messages": messages, "max_tokens": max_tokens},
                key=self.api_key,
            )
            return response["choices"][0]["message"]["content"]
        response = self.client.chat.completions.create(
            model=use_model,
            messages=messages,
            max_tokens=max_tokens,
            temperature=0.7,
        )
        return response.choices[0].message.content

    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        if not self.client:
            raise Exception("OpenRouter error: OPENROUTER_KEY not configured")
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