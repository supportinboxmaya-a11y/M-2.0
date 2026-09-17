import time
from typing import Callable, Any

class RetryStrategy:
    def __init__(self, max_retries: int = 3, delay: float = 2.0, backoff: float = 2.0):
        self.max_retries = max_retries
        self.delay = delay
        self.backoff = backoff

    def execute(self, func: Callable, *args, **kwargs) -> Any:
        delay = self.delay
        for attempt in range(self.max_retries):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                if attempt == self.max_retries - 1:
                    raise e
                print(f"[Retry] Attempt {attempt+1} failed: {e}. Retrying in {delay}s...")
                time.sleep(delay)
                delay *= self.backoff
