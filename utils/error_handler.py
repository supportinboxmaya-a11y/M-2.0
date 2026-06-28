"""
Maya 2.0 - Ultra Error Handler
--------------------------------
Centralized error handling, classification, and recovery.
"""

from typing import Dict, Optional
from maya_logging.logger import get_logger

log = get_logger("errors")


class MayaError(Exception):
    """Base Maya error."""
    def __init__(self, message: str, error_type: str = "general", recoverable: bool = True):
        super().__init__(message)
        self.error_type = error_type
        self.recoverable = recoverable


class LLMError(MayaError):
    def __init__(self, message: str, provider: str = ""):
        super().__init__(message, "llm", recoverable=True)
        self.provider = provider


class ToolError(MayaError):
    def __init__(self, message: str, tool: str = ""):
        super().__init__(message, "tool", recoverable=True)
        self.tool = tool


class PlanningError(MayaError):
    def __init__(self, message: str):
        super().__init__(message, "planning", recoverable=True)


class AuthError(MayaError):
    def __init__(self, message: str):
        super().__init__(message, "auth", recoverable=False)


class ErrorHandler:
    """Centralized error handling."""

    ERROR_TYPES = {
        "network": ["timeout", "connection", "network", "dns"],
        "auth": ["api key", "authentication", "unauthorized", "forbidden"],
        "rate_limit": ["rate limit", "too many requests", "quota"],
        "not_found": ["not found", "404", "no such file"],
        "parse": ["json", "parse", "syntax", "decode"],
        "permission": ["permission", "access denied"],
        "llm": ["llm", "model", "token", "completion"],
    }

    def classify(self, error: str) -> str:
        """Error type classify করে।"""
        error_lower = error.lower()
        for error_type, keywords in self.ERROR_TYPES.items():
            if any(k in error_lower for k in keywords):
                return error_type
        return "unknown"

    def is_recoverable(self, error: str) -> bool:
        """Error recoverable কিনা।"""
        error_type = self.classify(error)
        return error_type not in ["auth", "permission"]

    def handle(self, error: Exception, module: str = "maya", context: str = "") -> Dict:
        """Error handle করে এবং structured response দেয়।"""
        error_str = str(error)
        error_type = self.classify(error_str)
        recoverable = self.is_recoverable(error_str)

        if recoverable:
            log.warning(f"[{module}] {error_type} error: {error_str[:100]}")
        else:
            log.error(f"[{module}] NON-RECOVERABLE {error_type} error: {error_str[:100]}")

        return {
            "error": error_str,
            "error_type": error_type,
            "recoverable": recoverable,
            "module": module,
            "context": context,
            "suggestion": self._get_suggestion(error_type)
        }

    def _get_suggestion(self, error_type: str) -> str:
        suggestions = {
            "auth": "Check your API key in .env file",
            "rate_limit": "Wait a moment and try again, or switch to another LLM provider",
            "network": "Check your internet connection and try again",
            "not_found": "The resource was not found, try a different approach",
            "parse": "Response format was unexpected, retrying with clearer prompt",
            "permission": "Insufficient permissions for this operation",
            "llm": "LLM provider issue, trying fallback provider",
        }
        return suggestions.get(error_type, "Retrying with alternative approach")
