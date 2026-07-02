"""Thread-safe TTL cache with max-size eviction (LRU-ish)."""
import threading
import time
from collections import OrderedDict


class TTLCache:
    def __init__(self, max_size: int = 512, default_ttl: float = 300.0):
        self._data: OrderedDict = OrderedDict()  # key -> (expires_at, value)
        self._lock = threading.Lock()
        self.max_size = max_size
        self.default_ttl = default_ttl
        self.hits = 0
        self.misses = 0

    def get(self, key, default=None):
        with self._lock:
            item = self._data.get(key)
            if item is None or item[0] < time.time():
                self.misses += 1
                self._data.pop(key, None)
                return default
            self._data.move_to_end(key)
            self.hits += 1
            return item[1]

    def set(self, key, value, ttl: float | None = None) -> None:
        with self._lock:
            self._data[key] = (time.time() + (ttl or self.default_ttl), value)
            self._data.move_to_end(key)
            while len(self._data) > self.max_size:
                self._data.popitem(last=False)

    def delete(self, key) -> None:
        with self._lock:
            self._data.pop(key, None)

    def clear(self) -> None:
        with self._lock:
            self._data.clear()

    def stats(self) -> dict:
        with self._lock:
            return {"size": len(self._data), "hits": self.hits, "misses": self.misses}
