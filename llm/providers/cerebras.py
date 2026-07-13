import os
from config.settings import env_first
from typing import List, Dict, Optional
from openai import OpenAI

# Cerebras exposes an OpenAI-compatible endpoint, so we reuse the openai SDK
# and just point it at their base URL. Free tier: ~1M tokens/day, no card,
# but note the free tier caps context at ~8k tokens, so keep prompts lean.
CEREBRAS_BASE_URL = "https://api.cerebras.ai/v1"


class CerebrasProvider:
    def __init__(self):
        self.client = None
        key = env_first("CEREBRAS_KEY", "CEREBRAS_API_KEY")
        if key:
            try:
                self.client = OpenAI(api_key=key, base_url=CEREBRAS_BASE_URL)
            except Exception:
                self.client = None
        # Model catalog on Cerebras changes over time; let it be overridden
        # via env without a code change.
        self.default_model = os.environ.get("CEREBRAS_MODEL", "llama-3.3-70b")

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("Cerebras error: CEREBRAS_KEY not configured")
        try:
            response = self.client.chat.completions.create(
                model=model or self.default_model,
                messages=messages,
                max_tokens=max_tokens,
                temperature=0.7,
            )
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"Cerebras error: {e}")

    def stream_chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000):
        if not self.client:
            raise Exception("Cerebras error: CEREBRAS_KEY not configured")
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
            raise Exception(f"Cerebras streaming error: {e}")

    def is_available(self) -> bool:
        return self.client is not None
