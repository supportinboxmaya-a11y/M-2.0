"""
Maya 2.0 - Text-to-Speech Tool
-------------------------------
Converts text to spoken audio using edge-tts (local, no API key needed).
"""

import base64
import os
import time
import asyncio
from typing import Dict, Optional

from config.settings import env_first, WORKSPACE_DIR


class TTSTool:
    """Text -> speech with edge-tts (local, no API key needed)."""

    def __init__(self):
        self.default_model = "tts-1"
        self._initialize_client()

    def _initialize_client(self):
        # edge-tts doesn't need API key
        self.client = True  # Just a marker that we have edge-tts available

    def synthesize(self, text: str, voice: str = "en-US-AriaNeural", model: str = "tts-1") -> Dict:
        text = (text or "").strip()
        if not text:
            return {"success": False, "error": "No text provided"}
        if len(text) > 4096:
            return {"success": False, "error": f"Text too long ({len(text)} chars, max 4096)"}

        # Use edge-tts (local, no API key needed)
        try:
            return self._edge_tts_synthesize(text, voice)
        except Exception as e:
            return {"success": False, "error": f"TTS failed: {str(e)}"}

    async def _edge_tts_synthesize(self, text: str, voice: str) -> bytes:
        import edge_tts
        communicate = edge_tts.Communicate(text, voice)
        audio_data = b""
        async for chunk in communicate.stream():
            if chunk["type"] == "audio":
                audio_data += chunk["data"]
        return audio_data

    def synthesize(self, text: str, voice: str = "en-US-AriaNeural", model: str = "tts-1") -> Dict:
        text = (text or "").strip()
        if not text:
            return {"success": False, "error": "No text provided"}
        if len(text) > 4096:
            return {"success": False, "error": f"Text too long ({len(text)} chars, max 4096)"}

        # Use edge-tts (local, no API key needed)
        try:
            audio = asyncio.run(self._edge_tts_synthesize(text, voice))
            path = self._save(audio, "mp3")
            return {"success": True, "provider": "edge-tts", "format": "mp3", "path": path, "audio_base64": base64.b64encode(audio).decode()}
        except Exception as e:
            return {"success": False, "error": f"TTS failed: {str(e)}"}

    def _save(self, audio: bytes, fmt: str) -> str:
        out_dir = os.path.join(str(WORKSPACE_DIR), "audio")
        os.makedirs(out_dir, exist_ok=True)
        path = os.path.join(out_dir, f"tts_{int(time.time() * 1000)}.{fmt}")
        with open(path, "wb") as f:
            f.write(audio)
        return path

    def run(self, text: str = "", voice: str = "en-US-AriaNeural", model: str = "tts-1", **kwargs) -> str:
        r = self.synthesize(text, voice, model)
        if r.get("success"):
            return f"Audio saved: {r['path']} (provider: {r['provider']})"
        return f"Error: {r.get('error')}"


class _NotConfigured(Exception):
    """Provider key absent -- silently try the next provider."""
    pass

# Required imports
import base64
import os
import time
import asyncio
from typing import Dict, Optional
from config.settings import env_first, WORKSPACE_DIR
import base64