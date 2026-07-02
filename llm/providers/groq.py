
import os
from config.settings import env_first
from typing import List, Dict, Optional
from groq import Groq

class GroqProvider:
    def __init__(self):
        self.client = None
        key = env_first("GROQ_KEY", "GROQ_API_KEY")
        if key:
            try:
                self.client = Groq(api_key=key)
            except Exception:
                self.client = None
        self.default_model = os.environ.get("PRIMARY_MODEL", "llama-3.3-70b-versatile")
        self.available_models = [
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant",
            "gemma2-9b-it",
        ]

    def chat(self, messages, model=None, max_tokens=8000):
        if not self.client:
            raise Exception("Groq error: GROQ_KEY not configured")
        use_model = model or self.default_model
        old_models = {
            "llama3-8b-8192": "llama-3.1-8b-instant",
            "llama3-70b-8192": "llama-3.3-70b-versatile",
            "mixtral-8x7b-32768": "llama-3.3-70b-versatile",
            "gemma-7b-it": "gemma2-9b-it",
        }
        use_model = old_models.get(use_model, use_model)
        try:
            response = self.client.chat.completions.create(
                model=use_model,
                messages=messages,
                max_tokens=max_tokens,
                temperature=0.7,
            )
            return response.choices[0].message.content
        except Exception as e:
            raise Exception(f"Groq error: {e}")

    def is_available(self):
        return self.client is not None
