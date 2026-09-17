"""
Maya 2.0 - Live Translation
---------------------------
Real-time translation between languages using the existing LLM router,
with lightweight script-based language detection and a curated set of
supported languages. Pairs naturally with Maya's TTS so a translation
can be spoken aloud.

Why LLM-based? It handles context, idioms, and Bengali/English
code-mixing far better than a phrase table, and reuses the router's
provider fallback — no new API to configure.

Detection is a cheap heuristic (Unicode script ranges) good enough to
auto-pick source language and to short-circuit "already in target
language" cases; the model does the actual translating.
"""

import re
from typing import Dict, List, Optional

# Curated languages (code -> English name). Kept small and practical.
SUPPORTED = {
    "en": "English", "bn": "Bengali", "hi": "Hindi", "ur": "Urdu",
    "ar": "Arabic", "es": "Spanish", "fr": "French", "de": "German",
    "pt": "Portuguese", "ru": "Russian", "zh": "Chinese", "ja": "Japanese",
    "ko": "Korean", "ta": "Tamil", "te": "Telugu", "pa": "Punjabi",
}

# Unicode script ranges for cheap detection.
_SCRIPTS = [
    ("bn", r"[\u0980-\u09FF]"),          # Bengali
    ("hi", r"[\u0900-\u097F]"),          # Devanagari (Hindi/Marathi)
    ("ar", r"[\u0600-\u06FF]"),          # Arabic/Urdu
    ("zh", r"[\u4E00-\u9FFF]"),          # CJK
    ("ja", r"[\u3040-\u30FF]"),          # Hiragana/Katakana
    ("ko", r"[\uAC00-\uD7AF]"),          # Hangul
    ("ta", r"[\u0B80-\u0BFF]"),          # Tamil
    ("te", r"[\u0C00-\u0C7F]"),          # Telugu
    ("pa", r"[\u0A00-\u0A7F]"),          # Gurmukhi
    ("ru", r"[\u0400-\u04FF]"),          # Cyrillic
]


class Translator:
    """LLM-backed translator with heuristic language detection."""

    def __init__(self, chat_fn=None):
        # chat_fn(messages)->str; typically the LLM router's chat.
        self.chat_fn = chat_fn

    # ── detection ─────────────────────────────────────────────────
    @staticmethod
    def detect(text: str) -> str:
        """Best-effort language code from script. Defaults to 'en' for
        Latin-script text (covers en/es/fr/de/pt without over-guessing)."""
        text = text or ""
        counts = {}
        for code, pattern in _SCRIPTS:
            n = len(re.findall(pattern, text))
            if n:
                counts[code] = n
        if counts:
            return max(counts, key=counts.get)
        return "en"

    @staticmethod
    def language_name(code: str) -> str:
        return SUPPORTED.get(code, code)

    def supported_languages(self) -> List[Dict]:
        return [{"code": c, "name": n} for c, n in SUPPORTED.items()]

    # ── translation ───────────────────────────────────────────────
    def translate(self, text: str, target: str,
                  source: Optional[str] = None) -> Dict:
        """Translate `text` into `target` (a language code or name).
        Auto-detects source when not given. Returns detected source,
        the resolved target, and the translation."""
        text = (text or "").strip()
        if not text:
            raise ValueError("text is required")
        target_code = self._normalize(target)
        if target_code is None:
            raise ValueError(f"unsupported target language: {target}")

        detected = source or self.detect(text)
        # Short-circuit: already in the target language.
        if detected == target_code:
            return {"source": detected, "target": target_code,
                    "source_name": self.language_name(detected),
                    "target_name": self.language_name(target_code),
                    "original": text, "translation": text,
                    "note": "already in target language"}

        if self.chat_fn is None:
            return {"source": detected, "target": target_code,
                    "source_name": self.language_name(detected),
                    "target_name": self.language_name(target_code),
                    "original": text,
                    "translation": f"[no translator configured] {text}"}

        tgt_name = self.language_name(target_code)
        src_name = self.language_name(detected)
        prompt = (
            f"Translate the following text from {src_name} to {tgt_name}. "
            "Output ONLY the translation, with no quotes, no explanation, "
            "and no transliteration.\n\n"
            f"Text: {text}")
        messages = [
            {"role": "system", "content": "You are a precise translator."},
            {"role": "user", "content": prompt},
        ]
        translation = str(self.chat_fn(messages)).strip()
        # Strip stray surrounding quotes some models add.
        if len(translation) >= 2 and translation[0] in "\"'" and \
                translation[-1] == translation[0]:
            translation = translation[1:-1].strip()

        return {"source": detected, "target": target_code,
                "source_name": src_name, "target_name": tgt_name,
                "original": text, "translation": translation}

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _normalize(target: str) -> Optional[str]:
        """Accept a code ('bn') or a name ('Bengali'/'bengali')."""
        if not target:
            return None
        t = target.strip().lower()
        if t in SUPPORTED:
            return t
        for code, name in SUPPORTED.items():
            if name.lower() == t:
                return code
        return None
