

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
        self.default_model = os.environ.get("PRIMARY_MODEL", "openai/gpt-oss-120b")
        self.available_models = [
            "openai/gpt-oss-120b",
            "openai/gpt-oss-20b",
            "llama-3.1-8b-instant",
        ]

    def chat(self, messages, model=None, max_tokens=8000):
        if not self.client:
            raise Exception("Groq error: GROQ_KEY not configured")
        use_model = model or self.default_model
        old_models = {
            "llama3-8b-8192": "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile": "openai/gpt-oss-120b",
            "llama3-70b-8192": "openai/gpt-oss-120b",
            "mixtral-8x7b-32768": "openai/gpt-oss-120b",
            "gemma-7b-it": "llama-3.1-8b-instant",
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

    def stream_chat(self, messages, model=None, max_tokens=8000):
        """Yield response text chunks as they arrive (native streaming)."""
        if not self.client:
            raise Exception("Groq error: GROQ_KEY not configured")
        use_model = model or self.default_model
        old_models = {
            "llama3-8b-8192": "llama-3.1-8b-instant",
            "llama-3.3-70b-versatile": "openai/gpt-oss-120b",
            "llama3-70b-8192": "openai/gpt-oss-120b",
            "mixtral-8x7b-32768": "openai/gpt-oss-120b",
            "gemma-7b-it": "llama-3.1-8b-instant",
        }
        use_model = old_models.get(use_model, use_model)
        try:
            stream = self.client.chat.completions.create(
                model=use_model,
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
            raise Exception(f"Groq streaming error: {e}")

    def is_available(self):
        return self.client is not None
