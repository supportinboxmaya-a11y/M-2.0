"""
Maya 2.0 - Ultra Retry System
-------------------------------
Smart retry with exponential backoff, jitter, and error classification.
"""

import time
import random
from typing import Callable, Any, List, Type, Optional
from maya_logging.logger import get_logger

log = get_logger("retry")


class RetryConfig:
    def __init__(
        self,
        max_attempts: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 30.0,
        backoff: float = 2.0,
        jitter: bool = True,
        retryable_errors: List[Type[Exception]] = None,
    ):
        self.max_attempts = max_attempts
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.backoff = backoff
        self.jitter = jitter
        self.retryable_errors = retryable_errors or [Exception]


# Non-retryable error keywords
NO_RETRY_KEYWORDS = [
    "api key", "authentication", "unauthorized", "forbidden",
    "invalid key", "permission denied", "quota exceeded",
    "billing", "not found", "404"
]


def should_retry(error: str, attempt: int, max_attempts: int) -> bool:
    """Error retry করা উচিত কিনা।"""
    if attempt >= max_attempts:
        return False
    error_lower = error.lower()
    if any(k in error_lower for k in NO_RETRY_KEYWORDS):
        return False
    return True


def get_delay(attempt: int, base_delay: float = 1.0, backoff: float = 2.0,
              max_delay: float = 30.0, jitter: bool = True) -> float:
    """Exponential backoff with optional jitter."""
    delay = min(base_delay * (backoff ** attempt), max_delay)
    if jitter:
        delay *= (0.5 + random.random() * 0.5)
    return delay


def retry(
    func: Callable,
    *args,
    config: RetryConfig = None,
    on_retry: Callable = None,
    **kwargs
) -> Any:
    """
    Function retry করে with smart backoff.
    """
    cfg = config or RetryConfig()
    last_error = None

    for attempt in range(cfg.max_attempts):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            last_error = e
            error_str = str(e)

            if not should_retry(error_str, attempt + 1, cfg.max_attempts):
                log.error(f"Non-retryable error: {error_str[:100]}")
                raise e

            if attempt < cfg.max_attempts - 1:
                delay = get_delay(attempt, cfg.base_delay, cfg.backoff, cfg.max_delay, cfg.jitter)
                log.warning(f"Attempt {attempt+1} failed: {error_str[:80]} | Retrying in {delay:.1f}s")

                if on_retry:
                    on_retry(attempt + 1, error_str, delay)

                time.sleep(delay)

    raise last_error


def retry_decorator(max_attempts: int = 3, base_delay: float = 1.0):
    """Decorator version of retry."""
    def decorator(func: Callable):
        def wrapper(*args, **kwargs):
            return retry(func, *args, config=RetryConfig(max_attempts=max_attempts, base_delay=base_delay), **kwargs)
        return wrapper
    return decorator
