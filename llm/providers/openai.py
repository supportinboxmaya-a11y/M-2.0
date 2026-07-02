import os
from config.settings import env_first
from typing import List, Dict, Optional
from openai import OpenAI

class OpenAIProvider:
    def __init__(self):
        self.client = None
        key = env_first("OPENAI_KEY", "OPENAI_API_KEY")
        if key:
            try:
                self.client = OpenAI(api_key=key)
            except Exception:
                self.client = None
        self.default_model = "gpt-4o-mini"

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("OpenAI error: OPENAI_KEY not configured")
        try:
            response = self.client.chat.completions.create(
                model=model or self.default_model,
                messages=messages,
                max_tokens=max_tokens,
            )
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"OpenAI error: {e}")

    def is_available(self) -> bool:
        return self.client is not None
