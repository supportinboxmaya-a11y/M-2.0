import os
from typing import List, Dict, Optional
from openai import OpenAI

class OpenAIProvider:
    def __init__(self):
        self.client = OpenAI(api_key=os.environ.get("OPENAI_KEY", ""))
        self.default_model = "gpt-4o-mini"

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
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
        return bool(os.environ.get("OPENAI_KEY", ""))
