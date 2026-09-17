"""Feature flags via environment (FLAG_<NAME>=true) with runtime override."""
import os
import threading


class FeatureFlags:
    def __init__(self, prefix: str = "FLAG_"):
        self.prefix = prefix
        self._overrides: dict[str, bool] = {}
        self._lock = threading.Lock()

    def enabled(self, name: str, default: bool = False) -> bool:
        with self._lock:
            if name in self._overrides:
                return self._overrides[name]
        raw = os.environ.get(self.prefix + name.upper(), "")
        if raw == "":
            return default
        return raw.strip().lower() in ("1", "true", "yes", "on")

    def set(self, name: str, value: bool) -> None:
        with self._lock:
            self._overrides[name] = bool(value)

    def all(self) -> dict:
        out = {}
        for k, v in os.environ.items():
            if k.startswith(self.prefix):
                out[k[len(self.prefix):].lower()] = v.strip().lower() in ("1", "true", "yes", "on")
        with self._lock:
            out.update(self._overrides)
        return out


flags = FeatureFlags()
