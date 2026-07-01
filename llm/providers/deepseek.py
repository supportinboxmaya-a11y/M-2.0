import os
from typing import List, Dict, Optional
from openai import OpenAI

class DeepSeekProvider:
    def __init__(self):
        self.client = None
        key = os.environ.get("DEEPSEEK_KEY", "")
        if key:
            try:
                self.client = OpenAI(api_key=key, base_url="https://api.deepseek.com")
            except Exception:
                self.client = None
        self.default_model = "deepseek-chat"

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("DeepSeek error: DEEPSEEK_KEY not configured")
        try:
            response = self.client.chat.completions.create(
                model=model or self.default_model,
                messages=messages,
                max_tokens=max_tokens,
            )
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"DeepSeek error: {e}")

    def is_available(self) -> bool:
        return self.client is not None
