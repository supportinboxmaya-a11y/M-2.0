
import os
from config.settings import env_first
from typing import List, Dict, Optional
from openai import OpenAI

# OpenRouter is OpenAI-compatible and exposes 190+ models with a ":free"
# suffix that cost nothing. One key, many fallback models.
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"


class OpenRouterProvider:
    def __init__(self, http_fn=None):
        self.client = None
        self._http_fn = http_fn
        key = env_first("OPENROUTER_KEY", "OPENROUTER_API_KEY")
        if key:
            try:
                # The referer/title headers are optional but recommended by
                # OpenRouter for free-tier attribution.
                self.client = OpenAI(
                    api_key=key,
                    base_url=OPENROUTER_BASE_URL,
                    default_headers={
                        "HTTP-Referer": "https://m-2-0-1.onrender.com",
                        "X-Title": "Maya",
                    },
                )
            except Exception:
                self.client = None
        # Overridable via env; default to a free Llama model.
        self.default_model = os.environ.get(
            "OPENROUTER_MODEL", "meta-llama/llama-3.3-70b-instruct:free"
        )

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("OpenRouter error: OPENROUTER_KEY not configured")
        try:
            if self._http_fn:
                # Use injected HTTP function for testing
                response = self._http_fn(
                    f"{OPENROUTER_BASE_URL}/chat/completions",
                    {"model": model or self.default_model, "messages": messages, "max_tokens": max_tokens},
                    key=env_first("OPENROUTER_KEY", "OPENROUTER_API_KEY") or "",
                )
                return response["choices"][0]["message"]["content"]
            response = self.client.chat.completions.create(
                model=model or self.default_model,
                messages=messages,
                max_tokens=max_tokens,
                temperature=0.7,
            )
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"OpenRouter error: {e}")

    def stream_chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000):
        if not self.client:
            raise Exception("OpenRouter error: OPENROUTER_KEY not configured")
        try:
            stream = self.client.chat.completions.create(
                model=model or self.default_model,
                messages=messages,
                max_tokens=max_tokens,
                temperature=0.7,
                stream=True,
            )
            for chunk in stream:
                delta = chunk.choices[0].delta.content
                if delta:
                    yield delta
        except Exception as e:
            raise Exception(f"OpenRouter streaming error: {e}")

    def is_available(self) -> bool:
        return self.client is not None
