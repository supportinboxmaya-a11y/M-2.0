"""Central retry decorator with exponential backoff (sync + async)."""
import asyncio
import functools
import random
import time


def retry(attempts: int = 3, base_delay: float = 0.5, max_delay: float = 10.0,
          exceptions: tuple = (Exception,), on_retry=None):
    """Retry a function with exponential backoff + jitter.

    on_retry(attempt, error) is called before each sleep (for logging).
    """
    def decorator(fn):
        if asyncio.iscoroutinefunction(fn):
            @functools.wraps(fn)
            async def awrap(*a, **kw):
                for i in range(1, attempts + 1):
                    try:
                        return await fn(*a, **kw)
                    except exceptions as e:
                        if i == attempts:
                            raise
                        if on_retry:
                            on_retry(i, e)
                        await asyncio.sleep(_delay(i, base_delay, max_delay))
            return awrap

        @functools.wraps(fn)
        def wrap(*a, **kw):
            for i in range(1, attempts + 1):
                try:
                    return fn(*a, **kw)
                except exceptions as e:
                    if i == attempts:
                        raise
                    if on_retry:
                        on_retry(i, e)
                    time.sleep(_delay(i, base_delay, max_delay))
        return wrap
    return decorator


def _delay(attempt: int, base: float, cap: float) -> float:
    return min(cap, base * (2 ** (attempt - 1))) * (0.7 + random.random() * 0.6)
