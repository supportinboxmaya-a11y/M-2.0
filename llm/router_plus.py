"""Maya 3.0 — Phase 8 Router+ (additive layer over the existing LLMRouter).

Adds: live provider stats (latency EMA, error rate), strategy-based
selection (cost / latency / quality / balanced), retry + fallback
chains, and OpenRouter support. llm/router.py stays untouched.
"""
import time


# static reference table: relative cost + quality tier per provider
PROVIDER_TABLE = {
    #            cost($/1M tok approx)  quality(0-1)
    "groq":      {"cost": 0.10, "quality": 0.70},
    "gemini":    {"cost": 0.15, "quality": 0.80},
    "deepseek":  {"cost": 0.30, "quality": 0.75},
    "openrouter":{"cost": 0.50, "quality": 0.80},
    "openai":    {"cost": 2.50, "quality": 0.90},
    "claude":    {"cost": 3.00, "quality": 0.95},
    "local":     {"cost": 0.00, "quality": 0.55},
}


class ProviderStats:
    """Latency EMA + rolling error rate per provider."""

    def __init__(self, alpha: float = 0.3):
        self.alpha = alpha
        self._lat: dict = {}
        self._ok: dict = {}
        self._err: dict = {}

    def record(self, provider: str, latency_s: float, ok: bool) -> None:
        prev = self._lat.get(provider)
        self._lat[provider] = latency_s if prev is None else \
            self.alpha * latency_s + (1 - self.alpha) * prev
        (self._ok if ok else self._err).setdefault(provider, 0)
        if ok:
            self._ok[provider] = self._ok.get(provider, 0) + 1
        else:
            self._err[provider] = self._err.get(provider, 0) + 1

    def latency(self, provider: str) -> float | None:
        return self._lat.get(provider)

    def error_rate(self, provider: str) -> float:
        ok, err = self._ok.get(provider, 0), self._err.get(provider, 0)
        return err / (ok + err) if (ok + err) else 0.0

    def snapshot(self) -> dict:
        provs = set(self._lat) | set(self._ok) | set(self._err)
        return {p: {"latency_ema_s": round(self._lat.get(p, 0), 3),
                    "ok": self._ok.get(p, 0), "errors": self._err.get(p, 0),
                    "error_rate": round(self.error_rate(p), 3)} for p in provs}


class SmartSelector:
    """Order available providers by strategy, skipping unhealthy ones."""

    def __init__(self, stats: ProviderStats | None = None,
                 table: dict | None = None, max_error_rate: float = 0.5):
        self.stats = stats or ProviderStats()
        self.table = table or PROVIDER_TABLE
        self.max_error_rate = max_error_rate

    def order(self, available: list, strategy: str = "balanced") -> list:
        healthy = [p for p in available
                   if self.stats.error_rate(p) <= self.max_error_rate]
        pool = healthy or list(available)          # never return empty if any exist

        def cost(p): return self.table.get(p, {}).get("cost", 1.0)
        def quality(p): return self.table.get(p, {}).get("quality", 0.5)
        def latency(p): return self.stats.latency(p) or 1.0

        if strategy == "cost":
            key = lambda p: (cost(p), -quality(p))
        elif strategy == "latency":
            key = lambda p: (latency(p), cost(p))
        elif strategy == "quality":
            key = lambda p: (-quality(p), cost(p))
        else:  # balanced: quality per dollar, tempered by observed latency
            key = lambda p: (-(quality(p) / (cost(p) + 0.05)), latency(p))
        return sorted(pool, key=key)


class RouterPlus:
    """Retry + fallback chain executor with stats, over any call_fn."""

    def __init__(self, selector: SmartSelector | None = None,
                 retries_per_provider: int = 1):
        self.selector = selector or SmartSelector()
        self.stats = self.selector.stats
        self.retries = max(1, retries_per_provider)

    def call(self, available: list, call_fn, prompt,
             strategy: str = "balanced") -> dict:
        """call_fn(provider, prompt) -> str. Tries providers in order.

        Returns {ok, provider, output|error, tried:[…]}. Never raises.
        """
        tried = []
        for provider in self.selector.order(available, strategy):
            for _ in range(self.retries):
                t0 = time.time()
                try:
                    out = call_fn(provider, prompt)
                    self.stats.record(provider, time.time() - t0, True)
                    return {"ok": True, "provider": provider,
                            "output": out, "tried": tried + [provider]}
                except Exception as e:
                    self.stats.record(provider, time.time() - t0, False)
                    last = str(e)
            tried.append(provider)
        return {"ok": False, "provider": None,
                "error": last if tried else "no providers available",
                "tried": tried}
