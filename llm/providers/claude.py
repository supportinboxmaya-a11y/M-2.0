import os
from typing import List, Dict, Optional
import anthropic

class ClaudeProvider:
    def __init__(self):
        self.client = anthropic.Anthropic(api_key=os.environ.get("ANTHROPIC_KEY", ""))
        self.default_model = "claude-3-haiku-20240307"

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
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
        return bool(os.environ.get("ANTHROPIC_KEY", ""))
