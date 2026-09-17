"""Token-bucket rate limiter (per key), thread-safe, stdlib-only."""
import threading
import time


class RateLimiter:
    def __init__(self, rate: float = 60.0, per_seconds: float = 60.0, burst: float | None = None):
        """Allow `rate` requests per `per_seconds` per key (burst defaults to rate)."""
        self.capacity = burst or rate
        self.refill = rate / per_seconds
        self._buckets: dict[str, list] = {}  # key -> [tokens, last_ts]
        self._lock = threading.Lock()

    def allow(self, key: str) -> bool:
        now = time.time()
        with self._lock:
            tokens, last = self._buckets.get(key, [self.capacity, now])
            tokens = min(self.capacity, tokens + (now - last) * self.refill)
            if tokens >= 1.0:
                self._buckets[key] = [tokens - 1.0, now]
                return True
            self._buckets[key] = [tokens, now]
            return False

    def remaining(self, key: str) -> int:
        with self._lock:
            item = self._buckets.get(key)
            return int(self.capacity if item is None else item[0])
