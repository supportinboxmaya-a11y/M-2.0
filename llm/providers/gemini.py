"""
Gemini Provider using the new google.genai SDK (replaces deprecated google.generativeai).
"""
import os
from typing import List, Dict, Optional, Generator

from config.settings import env_first


class GeminiProvider:
    def __init__(self):
        self.api_key = env_first("GEMINI_KEY", "GEMINI_API_KEY")
        if not self.api_key:
            self.client = None
        else:
            try:
                from google import genai
                self.client = genai.Client(api_key=self.api_key)
            except Exception:
                self.client = None
        self.default_model = "gemini-2.5-flash"

    def chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> str:
        if not self.client:
            raise Exception("Gemini error: GEMINI_KEY not configured")
        try:
            from google.genai import types

            use_model = model or self.default_model

            # Convert messages to google-genai format
            contents = []
            system_instruction = None
            for msg in messages:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                if role == "system":
                    system_instruction = content
                elif role == "user":
                    contents.append(types.Content(role="user", parts=[types.Part(text=content)]))
                elif role == "assistant":
                    contents.append(types.Content(role="model", parts=[types.Part(text=content)]))

            config = types.GenerateContentConfig(
                max_output_tokens=max_tokens,
                temperature=0.7,
            )
            if system_instruction:
                config.system_instruction = system_instruction

            response = self.client.models.generate_content(
                model=use_model,
                contents=contents,
                config=config,
            )
            return response.text or ""
        except Exception as e:
            raise Exception(f"Gemini error: {e}")

    def stream_chat(self, messages: List[Dict], model: Optional[str] = None, max_tokens: int = 8000) -> Generator[str, None, None]:
        """Yield response text chunks as they arrive (native streaming)."""
        if not self.client:
            raise Exception("Gemini error: GEMINI_KEY not configured")
        try:
            from google.genai import types

            use_model = model or self.default_model

            contents = []
            system_instruction = None
            for msg in messages:
                role = msg.get("role", "user")
                content = msg.get("content", "")
                if role == "system":
                    system_instruction = content
                elif role == "user":
                    contents.append(types.Content(role="user", parts=[types.Part(text=content)]))
                elif role == "assistant":
                    contents.append(types.Content(role="model", parts=[types.Part(text=content)]))

            config = types.GenerateContentConfig(
                max_output_tokens=max_tokens,
                temperature=0.7,
            )
            if system_instruction:
                config.system_instruction = system_instruction

            for chunk in self.client.models.generate_content_stream(
                model=use_model,
                contents=contents,
                config=config,
            ):
                if chunk.text:
                    yield chunk.text
        except Exception as e:
            raise Exception(f"Gemini streaming error: {e}")

    def is_available(self) -> bool:
        return self.client is not None and self.api_key is not None