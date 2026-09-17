"""
Base LLM Provider with production-grade retry, timeout, and error handling.
"""
import os
import time
import random
from typing import List, Dict, Optional, Generator, Any
from abc import ABC, abstractmethod
import logging

logger = logging.getLogger(__name__)


class RetryConfig:
    """Configuration for retry behavior."""
    def __init__(
        self,
        max_retries: int = 3,
        base_delay: float = 1.0,
        max_delay: float = 60.0,
        exponential_base: float = 2.0,
        jitter: float = 0.1,
    ):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.exponential_base = exponential_base
        self.jitter = jitter

    def get_delay(self, attempt: int) -> float:
        delay = min(
            self.base_delay * (self.exponential_base ** attempt),
            self.max_delay
        )
        jitter_range = delay * self.jitter
        return delay + random.uniform(-jitter_range, jitter_range)


class BaseProvider(ABC):
    """Abstract base class for all LLM providers with production-grade features."""

    def __init__(
        self,
        api_key_env: str,
        default_model: str,
        retry_config: Optional[RetryConfig] = None,
        timeout: float = 120.0,
    ):
        self.api_key_env = api_key_env
        self.default_model = default_model
        self.retry_config = retry_config or RetryConfig()
        self.timeout = timeout
        self.api_key = None
        self.client = None
        self._initialize_client()

    # ── usage reporting (production budget enforcement) ──────────────
    # A single listener (Maya's CostTracker) is registered at boot; every
    # provider reports token usage through report_usage() after each call.

    def _report_usage(self, model: str, response) -> None:
        """Extract usage from an OpenAI-compatible response, if present."""
        try:
            usage = getattr(response, "usage", None)
            if usage is None:
                return
            from llm.providers.base import report_usage
            report_usage(
                self.api_key_env or self.__class__.__name__,
                model,
                getattr(usage, "prompt_tokens", 0) or 0,
                getattr(usage, "completion_tokens", 0) or 0,
            )
        except Exception:
            pass

    def _report_usage_json(self, model: str, usage: dict) -> None:
        """Report usage from a raw JSON usage dict (httpx-based providers)."""
        if not isinstance(usage, dict):
            return
        try:
            from llm.providers.base import report_usage
            report_usage(
                self.api_key_env or self.__class__.__name__,
                model,
                usage.get("prompt_tokens", 0) or 0,
                usage.get("completion_tokens", 0) or 0,
            )
        except Exception:
            pass

    def _initialize_client(self):
        """Initialize the client. Override in subclasses."""
        pass

    @abstractmethod
    def _chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> str:
        """Implementation-specific chat call."""
        pass

    @abstractmethod
    def _stream_chat_impl(self, messages: List[Dict], model: Optional[str], max_tokens: int) -> Generator[str, None, None]:
        """Implementation-specific streaming chat call."""
        pass

    def chat(
        self,
        messages: List[Dict],
        model: Optional[str] = None,
        max_tokens: int = 8000,
    ) -> str:
        """Chat with automatic retry on transient failures."""
        last_exception = None

        for attempt in range(self.retry_config.max_retries + 1):
            try:
                return self._chat_impl(messages, model, max_tokens)
            except Exception as e:
                last_exception = e
                error_str = str(e).lower()

                # Don't retry on authentication/authorization errors
                if any(k in error_str for k in [
                    "unauthorized", "authentication", "invalid api key",
                    "api key not configured", "401", "403"
                ]):
                    raise

                # Don't retry on context length / model not found
                if any(k in error_str for k in [
                    "context length", "max tokens", "model not found",
                    "404", "context_length_exceeded"
                ]):
                    raise

                if attempt < self.retry_config.max_retries:
                    delay = self.retry_config.get_delay(attempt)
                    logger.warning(
                        f"{self.__class__.__name__} attempt {attempt + 1} failed: {e}. "
                        f"Retrying in {delay:.1f}s..."
                    )
                    time.sleep(delay)
                    continue
                raise

        raise last_exception

    def stream_chat(
        self,
        messages: List[Dict],
        model: Optional[str] = None,
        max_tokens: int = 8000,
    ) -> Generator[str, None, None]:
        """Stream chat with automatic retry on transient failures."""
        last_exception = None

        for attempt in range(self.retry_config.max_retries + 1):
            try:
                yield from self._stream_chat_impl(messages, model, max_tokens)
                return  # Success
            except Exception as e:
                last_exception = e
                error_str = str(e).lower()

                if any(k in error_str for k in [
                    "unauthorized", "authentication", "invalid api key",
                    "api key not configured", "401", "403"
                ]):
                    raise

                if any(k in error_str for k in [
                    "context length", "max tokens", "model not found",
                    "404", "context_length_exceeded"
                ]):
                    raise

                if attempt < self.retry_config.max_retries:
                    delay = self.retry_config.get_delay(attempt)
                    logger.warning(
                        f"{self.__class__.__name__} stream attempt {attempt + 1} failed: {e}. "
                        f"Retrying in {delay:.1f}s..."
                    )
                    time.sleep(delay)
                    continue
                raise

        raise last_exception

    def is_available(self) -> bool:
        """Check if provider is available (has valid credentials and client)."""
        return self.client is not None and self.api_key is not None

    def _get_model(self, model: Optional[str]) -> str:
        return model or self.default_model

# ── module-level usage listener ──────────────────────────────────────────
_usage_listener = None


def set_usage_listener(fn) -> None:
    """Register the single usage listener (Maya's CostTracker)."""
    global _usage_listener
    _usage_listener = fn


def report_usage(provider: str, model: str, input_tokens: int,
                 output_tokens: int) -> None:
    if _usage_listener is None:
        return
    try:
        _usage_listener(provider, model, input_tokens, output_tokens)
    except Exception:
        pass
