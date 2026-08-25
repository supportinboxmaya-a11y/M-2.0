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

# Import all providers directly - they handle missing SDKs gracefully
from llm.providers.omniroute import OmniRouteProvider
from llm.providers.groq import GroqProvider
from llm.providers.cerebras import CerebrasProvider
from llm.providers.openrouter import OpenRouterProvider
from llm.providers.gemini import GeminiProvider
from llm.providers.openai import OpenAIProvider
from llm.providers.claude import ClaudeProvider as AnthropicProvider
from llm.providers.deepseek import DeepSeekProvider
from llm.providers.nvidia_nim import NvidiaNimProvider
from llm.providers.local_llm import LocalLLMProvider


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