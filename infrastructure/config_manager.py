"""Central configuration manager.

Single typed access point for all settings. Reads environment first,
then falls back to defaults. Extends (does not replace) config/settings.py.
"""
import os
import threading
from typing import Any, Callable


class ConfigManager:
    _lock = threading.Lock()

    def __init__(self):
        self._overrides: dict[str, Any] = {}

    def get(self, key: str, default: Any = None, cast: Callable = str) -> Any:
        """Env var -> override -> default, cast to the requested type."""
        with self._lock:
            if key in self._overrides:
                return self._overrides[key]
        raw = os.environ.get(key)
        if raw is None or raw == "":
            return default
        try:
            if cast is bool:
                return raw.strip().lower() in ("1", "true", "yes", "on")
            return cast(raw)
        except (ValueError, TypeError):
            return default

    def get_int(self, key: str, default: int = 0) -> int:
        return self.get(key, default, int)

    def get_float(self, key: str, default: float = 0.0) -> float:
        return self.get(key, default, float)

    def get_bool(self, key: str, default: bool = False) -> bool:
        return self.get(key, default, bool)

    def set_override(self, key: str, value: Any) -> None:
        """Runtime override (tests / admin). Does not touch the environment."""
        with self._lock:
            self._overrides[key] = value

    def clear_override(self, key: str) -> None:
        with self._lock:
            self._overrides.pop(key, None)


config = ConfigManager()
