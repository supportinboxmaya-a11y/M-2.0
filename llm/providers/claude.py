import os
from config.settings import env_first
from typing import List, Dict, Optional
import anthropic

class ClaudeProvider:
    def __init__(self):
        self.client = None
        key = env_first("ANTHROPIC_KEY", "ANTHROPIC_API_KEY")
        if key:
            try:
                self.client = anthropic.Anthropic(api_key=key)
            except Exception:
                self.client = None
        self.default_model = "claude-sonnet-5"

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("Claude error: ANTHROPIC_KEY not configured")
        try:
            system = ""
            filtered = []
            for msg in messages:
                if msg["role"] == "system":
                    system = msg["content"]
                else:
                    filtered.append(msg)
            response = self.client.messages.create(
                model=model or self.default_model,
                max_tokens=max_tokens,
                system=system,
                messages=filtered,
            )
            return response.content[0].text
        except Exception as e:
            raise Exception(f"Claude error: {e}")

    def is_available(self) -> bool:
        return self.client is not None
