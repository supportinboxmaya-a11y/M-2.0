"""
Maya 2.0 - Text-to-Speech Tool
------------------------------
Converts text to spoken audio. Provider chain:

    OpenAI (tts-1) → Groq (playai-tts)

Output: MP3 (OpenAI) / WAV (Groq) saved under workspace/audio/ and
returned as base64 so API clients can play it directly. Clear
configuration messages when no provider key is set (same pattern as
the /voice/transcribe endpoint).
"""

import base64
import os
import time
from typing import Dict

from config.settings import env_first, WORKSPACE_DIR

MAX_TTS_CHARS = 4000
VALID_OPENAI_VOICES = {"alloy", "echo", "fable", "onyx", "nova", "shimmer"}


class TTSTool:
    """Text → speech with provider fallback and workspace persistence."""

    def synthesize(self, text: str, voice: str = "alloy") -> Dict:
        text = (text or "").strip()
        if not text:
            return {"success": False, "error": "No text provided"}
        if len(text) > MAX_TTS_CHARS:
            return {"success": False,
                    "error": f"Text too long ({len(text)} chars, max {MAX_TTS_CHARS})"}

        errors = []
        for name, fn in (("openai", self._openai), ("groq", self._groq)):
            try:
                audio, fmt = fn(text, voice)
                if audio:
                    path = self._save(audio, fmt)
                    return {"success": True, "provider": name, "format": fmt,
                            "path": path,
                            "audio_base64": base64.b64encode(audio).decode()}
            except _NotConfigured:
                continue
            except Exception as e:
                errors.append(f"{name}: {e}")
        if errors:
            return {"success": False,
                    "error": "TTS providers failed — " + " | ".join(errors)}
        return {"success": False,
                "error": "No TTS provider configured. Set OPENAI_KEY (tts-1) or "
                         "GROQ_KEY (playai-tts) to enable text-to-speech."}

    # ── tool-registry entry point ─────────────────────────────────
    def run(self, text: str = "", voice: str = "alloy", **kwargs) -> str:
        r = self.synthesize(text, voice)
        if r.get("success"):
            return f"Audio saved: {r['path']} (provider: {r['provider']})"
        return f"Error: {r.get('error')}"

    # ── providers ─────────────────────────────────────────────────
    @staticmethod
    def _openai(text: str, voice: str):
        key = env_first("OPENAI_KEY", "OPENAI_API_KEY")
        if not key:
            raise _NotConfigured()
        from openai import OpenAI
        client = OpenAI(api_key=key)
        v = voice if voice in VALID_OPENAI_VOICES else "alloy"
        resp = client.audio.speech.create(model="tts-1", voice=v, input=text)
        return resp.content, "mp3"

    @staticmethod
    def _groq(text: str, voice: str):
        key = env_first("GROQ_KEY", "GROQ_API_KEY")
        if not key:
            raise _NotConfigured()
        from groq import Groq
        client = Groq(api_key=key)
        resp = client.audio.speech.create(
            model="playai-tts", voice="Fritz-PlayAI",
            input=text, response_format="wav")
        return resp.read(), "wav"

    # ── output ────────────────────────────────────────────────────
    @staticmethod
    def _save(audio: bytes, fmt: str) -> str:
        out_dir = os.path.join(str(WORKSPACE_DIR), "audio")
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, f"tts_{int(time.time() * 1000)}.{fmt}")
        with open(path, "wb") as f:
            f.write(audio)
        return path


class _NotConfigured(Exception):
    """Provider key absent — silently try the next provider."""
