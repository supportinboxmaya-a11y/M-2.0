
"""
Maya 2.0 - LLM Router
Handles provider management, live configuration, health checks, and automatic fallbacks.
"""

import os
import time
import json
import datetime
import uuid
from typing import List, Dict, Optional
from config.settings import (
    GROQ_KEY, GEMINI_KEY, OPENAI_KEY, ANTHROPIC_KEY, 
    DEEPSEEK_KEY, OPENROUTER_KEY, CEREBRAS_KEY, env_first
)

# Mock/Import provider classes as structured in your framework
# Assumed to be imported or defined in your actual environment context
from llm.providers import (
    GroqProvider, CerebrasProvider, OpenRouterProvider, 
    GeminiProvider, OpenAIProvider, AnthropicProvider, 
    DeepSeekProvider, LocalLLMProvider, PROVIDER_INFO, PROVIDER_CLASSES, PROVIDER_STATE_FILE
)

class LLMRouter:
    DEFAULT_PRIORITY = ["groq", "cerebras", "openrouter", "gemini", "deepseek", "openai", "claude", "local"]

    def __init__(self):
        self.providers = {
            "groq": GroqProvider(),
            "cerebras": CerebrasProvider(),
            "openrouter": OpenRouterProvider(),
            "gemini": GeminiProvider(),
            "openai": OpenAIProvider(),
            "claude": AnthropicProvider(),
            "deepseek": DeepSeekProvider(),
            "local": LocalLLMProvider(),
        }

        # Provider health tracking
        self.health: Dict[str, Dict] = {
            p: {"available": False, "error_count": 0, "last_error": None, "avg_response_time": 0.0}
            for p in self.providers
        }

        # Check availability on startup
        self._check_all_providers()

        # User on/off toggles (persisted across restarts)
        self._enabled_state = self._load_enabled_state()

        # Stats
        self.total_requests = 0
        self.successful_requests = 0
        self.request_log: List[Dict] = []

    def chat(self, messages: List[Dict], provider: Optional[str] = None,
             model: Optional[str] = None, max_tokens: int = 4000,
             task_type: str = "general") -> str:
        """
        Messages channel response generation.
        Auto-selects best provider if not specified.
        """
        self.total_requests += 1

        # Provider select
        selected_provider = provider if provider and self._is_healthy(provider) else self._select_best_provider(task_type)

        if not selected_provider:
            raise Exception("No LLM provider available! Please set at least one API key in .env")

        # Try selected provider first, then fallback
        providers_to_try = [selected_provider] + [
            p for p in self.DEFAULT_PRIORITY
            if p != selected_provider and self._is_healthy(p)
        ]

        last_error = None
        all_errors = []
        for p in providers_to_try:
            try:
                start = time.time()
                response = self.providers[p].chat(messages, model=model, max_tokens=max_tokens)
                elapsed = time.time() - start

                # Update health stats
                self._update_health(p, success=True, response_time=elapsed)
                self.successful_requests += 1

                self._log_request(p, model, len(str(messages)), len(response), elapsed, True)
                return response

            except Exception as e:
                last_error = str(e)
                all_errors.append(f"[{p}]: {last_error}")
                self._update_health(p, success=False, error=last_error)
                self._log_request(p, model, len(str(messages)), 0, 0.0, False, error=last_error)
                print(f"Warning: [{p}] failed: {last_error[:80]}, trying next...")
                continue

        raise Exception(f"All providers failed. Errors: " + " | ".join(all_errors))

    def stream_chat(self, messages: List[Dict], provider: Optional[str] = None,
                    model: Optional[str] = None, max_tokens: int = 4000,
                    task_type: str = "general"):
        """Yield response chunks as they arrive with transparent healthy fallbacks."""
        self.total_requests += 1
        selected = provider if provider and self._is_healthy(provider) else self._select_best_provider(task_type)
        if not selected:
            raise Exception("No LLM provider available! Set at least one API key.")

        providers_to_try = [selected] + [
            p for p in self.DEFAULT_PRIORITY
            if p != selected and self._is_healthy(p)
        ]

        last_error = None
        for p in providers_to_try:
            impl = self.providers.get(p)
            if impl is None:
                continue

            try:
                start = time.time()
                produced = 0
                if hasattr(impl, "stream_chat"):
                    for chunk in impl.stream_chat(messages, model=model, max_tokens=max_tokens):
                        if chunk:
                            produced += len(chunk)
                            yield chunk
                else:
                    text = impl.chat(messages, model=model, max_tokens=max_tokens)
                    produced = len(text or "")
                    if text:
                        yield text

                elapsed = time.time() - start
                self._update_health(p, success=True, response_time=elapsed)
                self.successful_requests += 1
                self._log_request(p, model, len(str(messages)), produced, elapsed, True)
                return
            except Exception as e:
                last_error = str(e)
                self._update_health(p, success=False, error=last_error)
                self._log_request(p, model, len(str(messages)), 0, 0.0, False, error=last_error)
                print(f"Warning: Stream [{p}] failed: {last_error[:80]}, next...")
                continue

        raise Exception(f"All providers failed. Last error: {last_error}")

    def available_providers(self) -> List[str]:
        """Returns list of active and healthy providers."""
        return [p for p in self.DEFAULT_PRIORITY if self._is_healthy(p)]

    def best_provider(self, task_type: str = "general") -> Optional[str]:
        """Wrapper method for picking the best healthy provider."""
        return self._select_best_provider(task_type)

    def secondary_provider(self, exclude: Optional[str] = None) -> Optional[str]:
        """A healthy provider DIFFERENT from 'exclude' (or from the primary)."""
        primary = exclude or self._select_best_provider("general")
        for p in self.available_providers():
            if p != primary:
                return p
        return None

    def get_stats(self) -> Dict:
        """Router statistics endpoint."""
        return {
            "total_requests": self.total_requests,
            "successful_requests": self.successful_requests,
            "success_rate": f"{(self.successful_requests / self.total_requests * 100):.1f}%" if self.total_requests > 0 else "0%",
            "available_providers": self.available_providers(),
            "provider_health": self.health
        }

    def health_check(self) -> Dict:
        """Runs availability routines on all integrated providers."""
        self._check_all_providers()
        return {p: h["available"] for p, h in self.health.items()}

    def list_providers(self) -> List[Dict]:
        """Provides state statuses for control panel layout syncing."""
        out = []
        for name in self.DEFAULT_PRIORITY:
            info = PROVIDER_INFO.get(name, {"label": name, "env_key": ""})
            env_key = info["env_key"]
            configured = bool(env_first(env_key, env_key.replace("_KEY", "_API_KEY"))) if env_key else True
            enabled = self._enabled_state.get(name, True)
            h = self.health.get(name, {})
            out.append({
                "id": name,
                "label": info["label"],
                "configured": configured,
                "enabled": enabled,
                "active": configured and enabled and h.get("available", False),
                "error_count": h.get("error_count", 0),
            })
        return out

    def set_enabled(self, provider: str, enabled: bool) -> bool:
        """Toggles a provider state configuration manually."""
        if provider not in self.providers:
            return False
        self._enabled_state[provider] = bool(enabled)
        self._save_enabled_state()
        return True

    def set_key(self, provider: str, api_key: str) -> bool:
        """Updates a provider's API key at runtime without needing restarts."""
        info = PROVIDER_INFO.get(provider)
        if not info or not info["env_key"] or provider not in PROVIDER_CLASSES:
            return False
        os.environ[info["env_key"]] = api_key
        try:
            self.providers[provider] = PROVIDER_CLASSES[provider]()
        except Exception:
            return False
        self.health[provider] = {"available": False, "error_count": 0, "last_error": None, "avg_response_time": 0.0}
        return True

    def _load_enabled_state(self) -> Dict[str, bool]:
        try:
            if os.path.path.exists(PROVIDER_STATE_FILE):
                with open(PROVIDER_STATE_FILE, "r", encoding="utf-8") as f:
                    return json.load(f)
        except Exception:
            pass
        return {name: True for name in self.providers}

    def _save_enabled_state(self):
        try:
            with open(PROVIDER_STATE_FILE, "w", encoding="utf-8") as f:
                json.dump(self._enabled_state, f)
        except Exception:
            pass

    def _select_best_provider(self, task_type: str = "general") -> Optional[str]:
        """Selects optimal healthy provider based on task routing mapping preferences."""
        preferences = {
            "coding": ["groq", "cerebras", "openrouter", "deepseek", "gemini"],
            "research": ["groq", "cerebras", "openrouter", "gemini", "claude"],
            "fast": ["groq", "cerebras", "openrouter", "gemini", "openai"],
            "analysis": ["groq", "cerebras", "openrouter", "claude", "gemini"],
            "creative": ["groq", "cerebras", "openrouter", "claude", "gemini"],
            "general": self.DEFAULT_PRIORITY
        }
        priority = preferences.get(task_type, self.DEFAULT_PRIORITY)
        for p in priority:
            if self._is_healthy(p):
                return p
        for p in self.DEFAULT_PRIORITY:
            if self._is_healthy(p):
                return p
        return None

    def _is_healthy(self, provider: str) -> bool:
        """Verifies if a specific provider is enabled by user and under error threshold."""
        if provider not in self.health:
            return False
        if not self._enabled_state.get(provider, True):
            return False
        h = self.health[provider]
        return h["available"] and h["error_count"] < 5

    def _check_all_providers(self):
        """Iterates internal check methods on backend client instances."""
        for name, provider in self.providers.items():
            try:
                self.health[name]["available"] = provider.is_available()
            except Exception:
                self.health[name]["available"] = False

    def _update_health(self, provider: str, success: bool, response_time: float = 0, error: str = None):
        """Updates real-time operational availability metadata metrics."""
        if provider not in self.health:
            return
        h = self.health[provider]
        if success:
            h["error_count"] = max(0, h["error_count"] - 1)
            if response_time:
                h["avg_response_time"] = (h["avg_response_time"] + response_time) / 2
        else:
            h["error_count"] += 1
            h["last_error"] = error
            if h["error_count"] >= 5:
                h["available"] = False

    def _log_request(self, provider: str, model: Optional[str], input_len: int, output_len: int,
                     elapsed: float, success: bool, error: str = None):
        self.request_log.append({
            "id": str(uuid.uuid4()),
            "provider": provider,
            "model": model,
            "input_chars": input_len,
            "output_chars": output_len,
            "response_time": round(elapsed, 2),
            "duration_ms": round(elapsed * 1000, 1),
            "success": success,
            "error": error,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        })
        if len(self.request_log) > 100:
            self.request_log = self.request_log[-100:]
