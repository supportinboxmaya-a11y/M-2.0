import os
from config.settings import env_first
from typing import List, Dict, Optional
import google.generativeai as genai

class GeminiProvider:
    def __init__(self):
        genai.configure(api_key=env_first("GEMINI_KEY", "GEMINI_API_KEY"))
        self.default_model = "gemini-1.5-flash"
        self.available_models = ["gemini-1.5-flash", "gemini-1.5-pro", "gemini-pro"]

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        try:
            m = genai.GenerativeModel(model or self.default_model)
            history = []
            last_user = ""
            for msg in messages:
                if msg["role"] == "system":
                    last_user = msg["content"] + "\n"
                elif msg["role"] == "user":
                    last_user += msg["content"]
                elif msg["role"] == "assistant":
                    history.append({"role": "model", "parts": [msg["content"]]})
            chat = m.start_chat(history=history)
            response = chat.send_message(last_user)
            return response.text
        except Exception as e:
            raise Exception(f"Gemini error: {e}")

    def stream_chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000):
        """Yield response text chunks as they arrive (native streaming)."""
        try:
            m = genai.GenerativeModel(model or self.default_model)
            history = []
            last_user = ""
            for msg in messages:
                if msg["role"] == "system":
                    last_user = msg["content"] + "\n"
                elif msg["role"] == "user":
                    last_user += msg["content"]
                elif msg["role"] == "assistant":
                    history.append({"role": "model", "parts": [msg["content"]]})
            chat = m.start_chat(history=history)
            for chunk in chat.send_message(last_user, stream=True):
                if getattr(chunk, "text", ""):
                    yield chunk.text
        except Exception as e:
            raise Exception(f"Gemini streaming error: {e}")

    def is_available(self) -> bool:
        return bool(env_first("GEMINI_KEY", "GEMINI_API_KEY"))
