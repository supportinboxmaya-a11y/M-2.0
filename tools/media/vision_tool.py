"""
Maya 2.0 - Vision Tool (Real Multimodal)
----------------------------------------
Sends the actual image bytes to a multimodal LLM. Provider chain
(first configured wins, next tried on failure):

    Gemini (gemini-flash-latest) → OpenAI (gpt-4o-mini) → Claude (haiku)

Also provides OCR: local pytesseract when installed, otherwise the
vision LLM with a strict transcription prompt.

Accepted image inputs: raw base64, data URLs
(data:image/png;base64,...), or a file path inside the workspace.
"""

import base64
import os
from typing import Dict, Optional, Tuple

from config.settings import env_first, WORKSPACE_DIR

_MEDIA_TYPES = {".png": "image/png", ".jpg": "image/jpeg", ".jpeg": "image/jpeg",
                ".gif": "image/gif", ".webp": "image/webp"}
MAX_IMAGE_BYTES = 20 * 1024 * 1024
_OCR_PROMPT = ("Transcribe ALL text visible in this image exactly as written. "
               "Preserve line breaks. Output ONLY the transcribed text, "
               "no commentary. If there is no text, output: [no text found]")


class VisionTool:
    """Multimodal image analysis + OCR with provider fallback."""

    # ── input handling ────────────────────────────────────────────
    @staticmethod
    def load_image(image: str) -> Tuple[bytes, str]:
        """Return (raw_bytes, media_type) from base64 / data URL / path."""
        image = (image or "").strip()
        if not image:
            raise ValueError("No image provided")

        if image.startswith("data:"):                       # data URL
            header, _, payload = image.partition(",")
            media = header[5:].split(";")[0] or "image/png"
            raw = base64.b64decode(payload)
        elif os.path.splitext(image)[1].lower() in _MEDIA_TYPES:
            # Base64 never contains '.', so an image extension reliably
            # marks this as a file path rather than encoded data.
            full = os.path.abspath(os.path.join(str(WORKSPACE_DIR), image))
            if not full.startswith(str(WORKSPACE_DIR)):
                raise PermissionError("Image path outside workspace")
            if not os.path.isfile(full):
                raise FileNotFoundError(f"Image not found: {image}")
            media = _MEDIA_TYPES.get(os.path.splitext(full)[1].lower(), "image/png")
            with open(full, "rb") as f:
                raw = f.read()
        else:                                               # raw base64
            raw = base64.b64decode(image)
            media = "image/png"
            if raw[:3] == b"\xff\xd8\xff":
                media = "image/jpeg"
            elif raw[:4] == b"RIFF":
                media = "image/webp"

        if len(raw) > MAX_IMAGE_BYTES:
            raise ValueError(f"Image exceeds {MAX_IMAGE_BYTES // (1024*1024)}MB limit")
        return raw, media

    # ── analysis ──────────────────────────────────────────────────
    def analyze(self, image: str, prompt: str = "Describe this image in detail.") -> Dict:
        """Send the image to the first available multimodal provider."""
        raw, media = self.load_image(image)
        errors = []
        for name, fn in (("gemini", self._gemini), ("openai", self._openai),
                         ("claude", self._claude)):
            try:
                text = fn(raw, media, prompt)
                if text:
                    return {"success": True, "provider": name, "result": text}
            except _NotConfigured:
                continue
            except Exception as e:
                errors.append(f"{name}: {e}")
        if errors:
            return {"success": False,
                    "error": "All vision providers failed — " + " | ".join(errors)}
        return {"success": False,
                "error": "No vision-capable provider configured. Set GEMINI_KEY, "
                         "OPENAI_KEY, or ANTHROPIC_KEY to enable vision."}

    def ocr(self, image: str) -> Dict:
        """Extract text: local pytesseract first, vision LLM otherwise."""
        try:
            import pytesseract
            from PIL import Image as _Img
            import io
            raw, _ = self.load_image(image)
            text = pytesseract.image_to_string(_Img.open(io.BytesIO(raw)))
            text = (text or "").strip()
            if text:
                return {"success": True, "provider": "tesseract", "result": text}
        except ImportError:
            pass
        except Exception:
            pass                     # tesseract present but failed → LLM fallback
        return self.analyze(image, _OCR_PROMPT)

    # ── tool-registry entry point ─────────────────────────────────
    def run(self, action: str = "analyze", image: str = "",
            prompt: str = "Describe this image in detail.", **kwargs) -> str:
        if not image:
            return "Error: image required (base64, data URL, or workspace path)"
        r = self.ocr(image) if action == "ocr" else self.analyze(image, prompt)
        return str(r.get("result") if r.get("success") else f"Error: {r.get('error')}")

    # ── providers ─────────────────────────────────────────────────
    @staticmethod
    def _gemini(raw: bytes, media: str, prompt: str) -> str:
        key = env_first("GEMINI_KEY", "GEMINI_API_KEY")
        if not key:
            raise _NotConfigured()
        import google.generativeai as genai
        genai.configure(api_key=key)
        model = genai.GenerativeModel("gemini-flash-latest")
        resp = model.generate_content([{"mime_type": media, "data": raw}, prompt])
        return (resp.text or "").strip()

    @staticmethod
    def _openai(raw: bytes, media: str, prompt: str) -> str:
        key = env_first("OPENAI_KEY", "OPENAI_API_KEY")
        if not key:
            raise _NotConfigured()
        from openai import OpenAI
        client = OpenAI(api_key=key)
        b64 = base64.b64encode(raw).decode()
        resp = client.chat.completions.create(
            model="gpt-4o-mini", max_tokens=2000,
            messages=[{"role": "user", "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url",
                 "image_url": {"url": f"data:{media};base64,{b64}"}}]}])
        return (resp.choices[0].message.content or "").strip()

    @staticmethod
    def _claude(raw: bytes, media: str, prompt: str) -> str:
        key = env_first("ANTHROPIC_KEY", "ANTHROPIC_API_KEY")
        if not key:
            raise _NotConfigured()
        import anthropic
        client = anthropic.Anthropic(api_key=key)
        b64 = base64.b64encode(raw).decode()
        resp = client.messages.create(
            model="claude-haiku-4-5-20251001", max_tokens=2000,
            messages=[{"role": "user", "content": [
                {"type": "image", "source": {"type": "base64",
                                             "media_type": media, "data": b64}},
                {"type": "text", "text": prompt}]}])
        return "".join(b.text for b in resp.content
                       if getattr(b, "type", "") == "text").strip()


class _NotConfigured(Exception):
    """Provider key absent — silently try the next provider."""

