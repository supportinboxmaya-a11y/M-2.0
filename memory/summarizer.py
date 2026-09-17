"""Memory summarization (Phase 2).

Extractive by default (offline, deterministic); accepts an optional
llm_fn callback for higher-quality abstractive summaries in production.
"""
import re

from .ranker import _tokens


class MemorySummarizer:
    def __init__(self, llm_fn=None):
        self.llm_fn = llm_fn  # callable(prompt: str) -> str, optional

    def summarize(self, texts: list, max_sentences: int = 5) -> str:
        corpus = " ".join(t for t in texts if t).strip()
        if not corpus:
            return ""
        if self.llm_fn:
            try:
                return self.llm_fn(
                    "Summarize these memories in under 100 words, keeping "
                    f"concrete facts and preferences:\n{corpus[:6000]}")
            except Exception:
                pass  # graceful fallback to extractive
        return self._extractive(corpus, max_sentences)

    def _extractive(self, corpus: str, max_sentences: int) -> str:
        sentences = [s.strip() for s in re.split(r"(?<=[.!?])\s+", corpus) if len(s.strip()) > 15]
        if not sentences:
            return corpus[:300]
        freq = {}
        for s in sentences:
            for w in _tokens(s):
                freq[w] = freq.get(w, 0) + 1
        ranked = sorted(sentences, key=lambda s: sum(freq.get(w, 0) for w in _tokens(s)) /
                        (len(_tokens(s)) or 1), reverse=True)
        chosen = ranked[:max_sentences]
        return " ".join(s for s in sentences if s in set(chosen))
