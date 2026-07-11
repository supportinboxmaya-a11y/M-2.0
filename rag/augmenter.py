"""
Maya 2.0 - RAG Auto-Connect
---------------------------
Lets the assistant automatically consult the knowledge base before
answering, instead of requiring an explicit knowledge_search tool call.

Flow:
    augmenter = RAGAugmenter()
    system_addon, citations = augmenter.augment(user_message)
    # prepend system_addon to the system prompt; show citations after

Design principles:
- Lazy + optional: if the RAG package or its index is empty/unavailable,
  augment() returns ("", []) and the caller behaves exactly as before.
- Cheap gating: a quick relevance check avoids retrieval on trivial
  messages ("hi", "thanks") and when nothing scores above a threshold,
  so we never bloat the prompt with irrelevant context.
- Transparent: returns the citations so the UI/response can show sources.
"""

import re
from typing import List, Tuple

# Messages shorter/simpler than this rarely benefit from retrieval.
_MIN_QUERY_CHARS = 8
_TRIVIAL = re.compile(
    r"^(hi|hey|hello|thanks|thank you|ok|okay|yes|no|sure|cool|"
    r"good morning|good night|bye)\b", re.IGNORECASE)


class RAGAugmenter:
    """Retrieves knowledge-base context to ground the assistant's answers."""

    def __init__(self, retriever=None, min_score: float = 0.0,
                 max_snippets: int = 4, max_chars: int = 4000):
        self._retriever = retriever          # injected or lazily loaded
        self._loaded = retriever is not None
        self.min_score = min_score
        self.max_snippets = max_snippets
        self.max_chars = max_chars

    def _get_retriever(self):
        if not self._loaded:
            try:
                from rag import RAGRetriever
                self._retriever = RAGRetriever.shared()
            except Exception:
                self._retriever = None
            self._loaded = True
        return self._retriever

    # ── gating ────────────────────────────────────────────────────
    @staticmethod
    def _worth_retrieving(message: str) -> bool:
        msg = (message or "").strip()
        if len(msg) < _MIN_QUERY_CHARS:
            return False
        if _TRIVIAL.match(msg):
            return False
        return True

    def has_knowledge(self) -> bool:
        r = self._get_retriever()
        if r is None:
            return False
        try:
            return r.stats().get("documents", 0) > 0
        except Exception:
            return False

    # ── main entry ────────────────────────────────────────────────
    def augment(self, message: str) -> Tuple[str, List[dict]]:
        """Return (system_prompt_addon, citations).

        Empty ("", []) when retrieval isn't warranted or nothing relevant
        is found — the caller then behaves exactly as before.
        """
        if not self._worth_retrieving(message):
            return "", []
        r = self._get_retriever()
        if r is None:
            return "", []
        try:
            result = r.get_context(message, limit=self.max_snippets,
                                    max_chars=self.max_chars)
        except Exception:
            return "", []

        citations = result.get("citations", []) or []
        context = (result.get("context") or "").strip()
        if not context or not citations:
            return "", []

        # Drop anything below the score floor (keeps prompts focused).
        if self.min_score > 0:
            citations = [c for c in citations
                         if c.get("score", 0) >= self.min_score]
            if not citations:
                return "", []

        addon = (
            "\n\nYou have access to the following retrieved knowledge-base "
            "context. Use it when it is relevant to the user's question, and "
            "cite sources inline using their [n] markers. If the context does "
            "not answer the question, rely on your general knowledge and do "
            "not force a citation.\n\n"
            "----- KNOWLEDGE CONTEXT -----\n"
            f"{context}\n"
            "----- END CONTEXT -----"
        )
        return addon, citations

    @staticmethod
    def format_sources(citations: List[dict]) -> str:
        """A short human-readable sources footer for chat responses."""
        if not citations:
            return ""
        lines = []
        for c in citations:
            ref = c.get("ref", "?")
            title = c.get("title", "source")
            section = c.get("section", "")
            tail = f" — {section}" if section else ""
            lines.append(f"[{ref}] {title}{tail}")
        return "Sources:\n" + "\n".join(lines)
