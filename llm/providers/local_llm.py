import os
from typing import List, Dict, Optional
import requests

class LocalLLMProvider:
    def __init__(self):
        self.base_url = os.environ.get("LOCAL_LLM_URL", "http://localhost:11434")
        self.default_model = os.environ.get("LOCAL_MODEL", "llama3")

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        try:
            prompt = "\n".join([f"{m['role']}: {m['content']}" for m in messages])
            response = requests.post(
                f"{self.base_url}/api/generate",
                json={"model": model or self.default_model, "prompt": prompt, "stream": False},
                timeout=120
            )
            return response.json().get("response", "")
        except Exception as e:
            raise Exception(f"Local LLM error: {e}")

    def is_available(self) -> bool:
        try:
            requests.get(f"{self.base_url}/api/tags", timeout=3)
            return True
        except:
            return False
