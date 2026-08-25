"""
Maya 2.0 — LLM Provider Registry

All providers inherit from BaseProvider and handle missing SDKs/keys gracefully
by setting is_available()=False and raising clear errors only when chat() is called.
"""
# Force-load all requests submodules to avoid lazy-loading issues
import requests
import requests.exceptions as _req_exc
import requests.adapters as _req_adapters
import requests.auth as _req_auth
import requests.cookies as _req_cookies
import requests.models as _req_models
import requests.sessions as _req_sessions
import requests.status_codes as _req_status_codes
import requests.structures as _req_structures
import requests.utils as _req_utils
# Force-load by explicit assignment (bypasses lazy loading)
requests.exceptions = _req_exc
requests.adapters = _req_adapters
requests.auth = _req_auth
requests.cookies = _req_cookies
requests.models = _req_models
requests.sessions = _req_sessions
requests.status_codes = _req_status_codes
requests.structures = _req_structures
requests.utils = _req_utils
# Also ensure exceptions module has all needed attributes
_ = _req_exc.RequestException
_ = _req_exc.ConnectionError
_ = _req_exc.ChunkedEncodingError
_ = _req_exc.Timeout
_ = _req_exc.HTTPError
_ = _req_exc.URLRequired
_ = _req_exc.TooManyRedirects
_ = _req_exc.MissingSchema
_ = _req_exc.InvalidSchema
_ = _req_exc.InvalidURL
_ = _req_exc.InvalidHeader
_ = _req_exc.InvalidProxyURL
_ = _req_exc.ProxyError
_ = _req_exc.SSLError
_ = _req_exc.ReadTimeout
_ = _req_exc.ConnectTimeout

import os
from typing import Dict, Type

from config.settings import STORAGE_DIR


class _UnavailableProvider:
    """Stand-in for a provider whose SDK is not installed on this host.

    Model-agnostic resilience: a missing package must never crash the
    import chain (providers -> router -> Maya -> API). The stub reports
    is_available()=False and raises only if actually invoked.
    """

    def __init__(self, provider_name: str, sdk_package: str):
        self._name = provider_name
        self._sdk = sdk_package

    def is_available(self) -> bool:
        return False

    def chat(self, *args, **kwargs) -> str:
        raise Exception(
            f"{self._name} is not available: the '{self._sdk}' package is "
            f"not installed.  Run: pip install {self._sdk}"
        )

    def stream_chat(self, *args, **kwargs):
        raise Exception(
            f"{self._name} is not available: the '{self._sdk}' package is "
            f"not installed.  Run: pip install {self._sdk}"
        )


def _load(provider_name: str, module: str, cls: str, sdk: str) -> Type:
    try:
        mod = __import__(f"llm.providers.{module}", fromlist=[cls])
        return getattr(mod, cls)
    except ImportError as e:
        print(f"WARNING: {provider_name} SDK ({sdk}) not installed – "
              f"{provider_name}Provider will use a disabled stub ({e})")
        return type(f"{cls} (stub)", (_UnavailableProvider,),
                    {"__init__": lambda self, _n=provider_name, _s=sdk:
                     _UnavailableProvider.__init__(self, _n, _s)})


# Resilient per-provider loading — one missing SDK never takes Maya down.
OmniRouteProvider = _load("OmniRoute", "omniroute", "OmniRouteProvider", "httpx")
GroqProvider = _load("Groq", "groq", "GroqProvider", "openai")
CerebrasProvider = _load("Cerebras", "cerebras", "CerebrasProvider", "openai")
OpenRouterProvider = _load("OpenRouter", "openrouter", "OpenRouterProvider", "openai")
GeminiProvider = _load("Gemini", "gemini", "GeminiProvider", "google-genai")
OpenAIProvider = _load("OpenAI", "openai", "OpenAIProvider", "openai")
AnthropicProvider = _load("Anthropic", "claude", "ClaudeProvider", "anthropic")
DeepSeekProvider = _load("DeepSeek", "deepseek", "DeepSeekProvider", "openai")
NvidiaNimProvider = _load("NVIDIA NIM", "nvidia_nim", "NvidiaNimProvider", "openai")
LocalLLMProvider = _load("Local LLM", "local_llm", "LocalLLMProvider", "requests")


# Per-provider metadata (label + env-var key)
PROVIDER_INFO: Dict[str, dict] = {
    "omniroute":  {"label": "OmniRoute",   "env_key": "OMNIROUTE_API_KEY"},
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


# Name → class mapping (used by router.set_key for hot-reload)
PROVIDER_CLASSES: Dict[str, Type] = {
    "omniroute": OmniRouteProvider,
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


# Explicit public API
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
    "OmniRouteProvider",
    "PROVIDER_INFO",
    "PROVIDER_CLASSES",
    "PROVIDER_STATE_FILE",
]