"""OpenRouter provider (Phase 8) — OpenAI-compatible aggregator API."""
import json
import os
import urllib.request

try:
    from config.settings import env_first
except ImportError:  # pre-Phase-0 codebases
    def env_first(*names, default=""):
        for n in names:
            v = os.environ.get(n, "")
            if v:
                return v
        return default


class OpenRouterProvider:
    BASE = "https://openrouter.ai/api/v1/chat/completions"

    def __init__(self, model: str = "openrouter/auto", http_fn=None):
        self.model = model
        self.http_fn = http_fn or self._http   # injectable for tests

    @staticmethod
    def available() -> bool:
        return bool(env_first("OPENROUTER_KEY", "OPENROUTER_API_KEY"))

    def build_payload(self, messages: list) -> dict:
        return {"model": self.model, "messages": messages}

    def chat(self, messages: list) -> str:
        key = env_first("OPENROUTER_KEY", "OPENROUTER_API_KEY")
        if not key:
            raise RuntimeError("OpenRouter key not configured")
        data = self.http_fn(self.BASE, self.build_payload(messages), key)
        return data["choices"][0]["message"]["content"]

    @staticmethod
    def _http(url: str, payload: dict, key: str) -> dict:
        req = urllib.request.Request(
            url, data=json.dumps(payload).encode(),
            headers={"Authorization": f"Bearer {key}",
                     "Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode())
