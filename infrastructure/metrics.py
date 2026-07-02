"""In-memory metrics: counters, latency histograms, cost tracking.

Thread-safe; zero external dependencies. Exposed via /api/v1/metrics.
"""
import threading
import time
from collections import defaultdict


class Metrics:
    def __init__(self):
        self._lock = threading.Lock()
        self._counters: dict[str, int] = defaultdict(int)
        self._latency: dict[str, list] = defaultdict(list)  # keep last 500
        self._started = time.time()

    def incr(self, name: str, value: int = 1) -> None:
        with self._lock:
            self._counters[name] += value

    def observe(self, name: str, seconds: float) -> None:
        with self._lock:
            bucket = self._latency[name]
            bucket.append(seconds)
            if len(bucket) > 500:
                del bucket[: len(bucket) - 500]

    def timer(self, name: str):
        """Context manager: with metrics.timer('llm.call'): ..."""
        m = self

        class _T:
            def __enter__(self):
                self.t0 = time.time()
                return self

            def __exit__(self, *exc):
                m.observe(name, time.time() - self.t0)
                return False

        return _T()

    def snapshot(self) -> dict:
        with self._lock:
            lat = {}
            for k, v in self._latency.items():
                if v:
                    s = sorted(v)
                    lat[k] = {
                        "count": len(s),
                        "avg_ms": round(sum(s) / len(s) * 1000, 2),
                        "p95_ms": round(s[int(len(s) * 0.95) - 1] * 1000, 2),
                    }
            return {
                "uptime_s": round(time.time() - self._started, 1),
                "counters": dict(self._counters),
                "latency": lat,
            }


metrics = Metrics()
