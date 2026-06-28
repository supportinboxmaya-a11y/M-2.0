from typing import List, Dict, Optional

class ModelFallback:
    """Handles fallback between models when primary fails."""

    FALLBACK_CHAIN = {
        "llama3-8b-8192": ["llama3-70b-8192", "mixtral-8x7b-32768"],
        "gemini-1.5-flash": ["gemini-1.5-pro", "gemini-pro"],
        "gpt-4o-mini": ["gpt-4o", "gpt-3.5-turbo"],
    }

    def get_fallbacks(self, model: str) -> List[str]:
        return self.FALLBACK_CHAIN.get(model, [])
