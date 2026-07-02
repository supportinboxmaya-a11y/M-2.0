"""
Maya 2.0 - Ultra LLM Router
-----------------------------
সব LLM provider manage করে। Smart routing, fallback, load balancing।
"""

import json
import os
import time
from typing import List, Dict, Optional
from .providers.groq import GroqProvider
from .providers.gemini import GeminiProvider
from .providers.openai import OpenAIProvider
from .providers.claude import ClaudeProvider
from .providers.deepseek import DeepSeekProvider
from .providers.local_llm import LocalLLMProvider
from config.settings import STORAGE_DIR, env_first, env_first, env_first, env_first, env_first, env_first, env_first, env_first, env_first

PROVIDER_STATE_FILE = str(STORAGE_DIR / "provider_state.json")

PROVIDER_INFO = {
    "groq": {"label": "Groq", "env_key": "GROQ_KEY"},
    "gemini": {"label": "Gemini", "env_key": "GEMINI_KEY"},
    "openai": {"label": "GPT (OpenAI)", "env_key": "OPENAI_KEY"},
    "claude": {"label": "Sonnet (Claude)", "env_key": "ANTHROPIC_KEY"},
    "deepseek": {"label": "DeepSeek", "env_key": "DEEPSEEK_KEY"},
    "local": {"label": "Local LLM", "env_key": ""},
}


class LLMRouter:
    """
    Maya-র LLM routing engine.
    - Available providers detect করে
    - Best provider choose করে
    - Automatic fallback করে
    - Rate limit handle করে
    - Response time track করে
    - Provider health monitor করে
    """

    # Provider priority (fast → powerful)
    DEFAULT_PRIORITY = ["groq", "gemini", "deepseek", "openai", "claude", "local"]

    def __init__(self):
        self.providers = {
            "groq": GroqProvider(),
            "gemini": GeminiProvider(),
            "openai": OpenAIProvider(),
            "claude": ClaudeProvider(),
            "deepseek": DeepSeekProvider(),
            "local": LocalLLMProvider(),
        }

        # Provider health tracking
        self.health: Dict[str, Dict] = {
            p: {"available": False, "error_count": 0, "last_error": None, "avg_response_time": 0}
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
        Messages পাঠায় এবং response নেয়।
        Auto-selects best provider if not specified.
        """
        self.total_requests += 1

        # Provider select করি
        selected_provider = provider if provider and self._is_healthy(provider) else self._select_best_provider(task_type)

        if not selected_provider:
            raise Exception("❌ No LLM provider available! Please set at least one API key in .env")

        # Try selected provider first, then fallback
        providers_to_try = [selected_provider] + [
            p for p in self.DEFAULT_PRIORITY
            if p != selected_provider and self._is_healthy(p)
        ]

        last_error = None
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
                self._update_health(p, success=False, error=last_error)
                print(f"   ⚠️ [{p}] failed: {last_error[:80]}, trying next...")
                continue

        raise Exception(f"All providers failed. Last error: {last_error}")

    def available_providers(self) -> List[str]:
        """সব available provider এর list।"""
        return [p for p in self.DEFAULT_PRIORITY if self._is_healthy(p)]

    def best_provider(self, task_type: str = "general") -> Optional[str]:
        """Best provider return করে।"""
        return self._select_best_provider(task_type)

    def get_stats(self) -> Dict:
        """Router statistics।"""
        return {
            "total_requests": self.total_requests,
            "successful_requests": self.successful_requests,
            "success_rate": f"{(self.successful_requests/self.total_requests*100):.1f}%" if self.total_requests > 0 else "0%",
            "available_providers": self.available_providers(),
            "provider_health": self.health
        }

    def health_check(self) -> Dict:
        """সব provider এর health check করে।"""
        self._check_all_providers()
        return {p: h["available"] for p, h in self.health.items()}

    def list_providers(self) -> List[Dict]:
        """Control panel এর জন্য সব provider এর status।"""
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
        """Provider চালু/বন্ধ করে, state persist করে।"""
        if provider not in self.providers:
            return False
        self._enabled_state[provider] = bool(enabled)
        self._save_enabled_state()
        return True

    def _load_enabled_state(self) -> Dict[str, bool]:
        try:
            if os.path.exists(PROVIDER_STATE_FILE):
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
        """Task type অনুযায়ী best provider select করে।"""
        # Task type based preferences
        preferences = {
            "coding": ["deepseek", "groq", "openai", "claude"],
            "research": ["gemini", "claude", "openai", "groq"],
            "fast": ["groq", "gemini", "deepseek"],
            "analysis": ["claude", "openai", "gemini"],
            "creative": ["claude", "openai", "gemini"],
            "general": self.DEFAULT_PRIORITY
        }

        priority = preferences.get(task_type, self.DEFAULT_PRIORITY)

        for p in priority:
            if self._is_healthy(p):
                return p

        # Fallback to any available
        for p in self.DEFAULT_PRIORITY:
            if self._is_healthy(p):
                return p

        return None

    def _is_healthy(self, provider: str) -> bool:
        """Provider available, healthy, এবং user দ্বারা enabled কিনা।"""
        if provider not in self.health:
            return False
        if not self._enabled_state.get(provider, True):
            return False
        h = self.health[provider]
        return h["available"] and h["error_count"] < 5

    def _check_all_providers(self):
        """সব provider এর availability check করে।"""
        for name, provider in self.providers.items():
            try:
                self.health[name]["available"] = provider.is_available()
            except:
                self.health[name]["available"] = False

    def _update_health(self, provider: str, success: bool, response_time: float = 0, error: str = None):
        """Provider health update করে।"""
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

    def _log_request(self, provider: str, model: Optional[str], input_len: int, output_len: int, elapsed: float, success: bool):
        """Request log করে।"""
        self.request_log.append({
            "provider": provider,
            "model": model,
            "input_chars": input_len,
            "output_chars": output_len,
            "response_time": round(elapsed, 2),
            "success": success
        })
        # Last 100 only রাখি
        if len(self.request_log) > 100:
            self.request_log = self.request_log[-100:]
