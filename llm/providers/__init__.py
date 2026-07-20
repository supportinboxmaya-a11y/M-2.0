"""
Maya 2.0 — LLM Provider Registry

Resilient import hub.  Every provider's hard SDK dependency is wrapped in
a try/except so a missing package never crashes the server.  When the SDK
is absent the registry substitutes a stub that reports *is_available()=False*
and raises a clear "pip install …" message only when the user actually calls
chat() or stream_chat().
"""

import os
from typing import Dict, Type

from config.settings import STORAGE_DIR

# ── Stub base ─────────────────────────────────────────────────────────────

class _StubProvider:
    """Stand-in for a provider whose SDK is not installed on this host."""

    def __init__(self, provider_name: str, sdk_package: str):
        self._name = provider_name
        self._sdk = sdk_package

    def is_available(self) -> bool:
        return False

    def chat(self, *args, **kwargs) -> str:
        raise Exception(
            f"{self._name} is not available: the '{self._sdk}' package is not "
            f"installed.  Run: pip install {self._sdk}"
        )

    def stream_chat(self, *args, **kwargs):
        raise Exception(
            f"{self._name} is not available: the '{self._sdk}' package is not "
            f"installed.  Run: pip install {self._sdk}"
        )


# ── Per-provider metadata (label + env-var key) ───────────────────────────

PROVIDER_INFO: Dict[str, dict] = {
    "groq":       {"label": "Groq",        "env_key": "GROQ_KEY"},
    "cerebras":   {"label": "Cerebras",    "env_key": "CEREBRAS_KEY"},
    "openrouter": {"label": "OpenRouter",  "env_key": "OPENROUTER_KEY"},
    "gemini":     {"label": "Gemini",      "env_key": "GEMINI_KEY"},
    "openai":     {"label": "OpenAI",      "env_key": "OPENAI_KEY"},
    "claude":     {"label": "Anthropic",   "env_key": "ANTHROPIC_KEY"},
    "deepseek":   {"label": "DeepSeek",    "env_key": "DEEPSEEK_KEY"},
    "nvidia_nim": {"label": "NVIDIA NIM",  "env_key": "NVIDIA_NIM_KEY"},
    "local":      {"label": "Local LLM",   "env_key": ""},
}

PROVIDER_STATE_FILE: str = str(STORAGE_DIR / "provider_state.json")


# ── Soft-fallible imports ─────────────────────────────────────────────────
# Each provider file does a "from <sdk> import …" at module level.  If the
# SDK is missing that raises ImportError, which we catch here and substitute
# a stub that still looks like the real class to the rest of the code.

try:
    from llm.providers.groq import GroqProvider as _RealGroq
    GroqProvider = _RealGroq
except ImportError:
    print("WARNING: Groq SDK not installed – GroqProvider will use a stub.")
    class GroqProvider(_StubProvider):                          # type: ignore
        def __init__(self):
            super().__init__("Groq", "groq")

try:
    from llm.providers.cerebras import CerebrasProvider as _RealCerebras
    CerebrasProvider = _RealCerebras
except ImportError:
    print("WARNING: Cerebras SDK (openai) not installed – CerebrasProvider will use a stub.")
    class CerebrasProvider(_StubProvider):                      # type: ignore
        def __init__(self):
            super().__init__("Cerebras", "openai")

try:
    from llm.providers.openrouter import OpenRouterProvider as _RealOpenRouter
    OpenRouterProvider = _RealOpenRouter
except ImportError:
    print("WARNING: OpenRouter SDK (openai) not installed – OpenRouterProvider will use a stub.")
    class OpenRouterProvider(_StubProvider):                    # type: ignore
        def __init__(self):
            super().__init__("OpenRouter", "openai")

try:
    from llm.providers.gemini import GeminiProvider as _RealGemini
    GeminiProvider = _RealGemini
except ImportError:
    print("WARNING: Gemini SDK (google-generativeai) not installed – GeminiProvider will use a stub.")
    class GeminiProvider(_StubProvider):                        # type: ignore
        def __init__(self):
            super().__init__("Gemini", "google-generativeai")

try:
    from llm.providers.openai import OpenAIProvider as _RealOpenAI
    OpenAIProvider = _RealOpenAI
except ImportError:
    print("WARNING: OpenAI SDK not installed – OpenAIProvider will use a stub.")
    class OpenAIProvider(_StubProvider):                        # type: ignore
        def __init__(self):
            super().__init__("OpenAI", "openai")

try:
    from llm.providers.claude import ClaudeProvider as _RealClaude
    AnthropicProvider = _RealClaude
except ImportError:
    print("WARNING: Anthropic SDK not installed – AnthropicProvider will use a stub.")
    class AnthropicProvider(_StubProvider):                     # type: ignore
        def __init__(self):
            super().__init__("Anthropic", "anthropic")

try:
    from llm.providers.deepseek import DeepSeekProvider as _RealDeepSeek
    DeepSeekProvider = _RealDeepSeek
except ImportError:
    print("WARNING: DeepSeek SDK (openai) not installed – DeepSeekProvider will use a stub.")
    class DeepSeekProvider(_StubProvider):                      # type: ignore
        def __init__(self):
            super().__init__("DeepSeek", "openai")

try:
    from llm.providers.nvidia_nim import NvidiaNimProvider as _RealNvidiaNim
    NvidiaNimProvider = _RealNvidiaNim
except ImportError:
    print("WARNING: NVIDIA NIM SDK (openai) not installed – NvidiaNimProvider will use a stub.")
    class NvidiaNimProvider(_StubProvider):                     # type: ignore
        def __init__(self):
            super().__init__("NvidiaNim", "openai")

try:
    from llm.providers.local_llm import LocalLLMProvider as _RealLocal
    LocalLLMProvider = _RealLocal
except ImportError:
    print("WARNING: LocalLLM SDK (requests) not installed – LocalLLMProvider will use a stub.")
    class LocalLLMProvider(_StubProvider):                      # type: ignore
        def __init__(self):
            super().__init__("LocalLLM", "requests")


# ── Name → class mapping (used by router.set_key for hot-reload) ──────────

PROVIDER_CLASSES: Dict[str, Type] = {
    "groq": GroqProvider,
    "cerebras": CerebrasProvider,
    "openrouter": OpenRouterProvider,
    "gemini": GeminiProvider,
    "openai": OpenAIProvider,
    "claude": AnthropicProvider,
    "deepseek": DeepSeekProvider,
    "nvidia_nim": NvidiaNimProvider,
    "local": LocalLLMProvider,
}


# ── Explicit public API ───────────────────────────────────────────────────

__all__ = [
    "GroqProvider",
    "CerebrasProvider",
    "OpenRouterProvider",
    "GeminiProvider",
    "OpenAIProvider",
    "AnthropicProvider",
    "DeepSeekProvider",
    "NvidiaNimProvider",
    "LocalLLMProvider",
    "PROVIDER_INFO",
    "PROVIDER_CLASSES",
    "PROVIDER_STATE_FILE",
]
