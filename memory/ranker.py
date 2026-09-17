"""Retrieval ranking (Phase 2): keyword overlap + importance + recency."""
import re

from .importance import ImportanceScorer

_WORD = re.compile(r"[a-z0-9]{2,}")
_STOP = {"the", "and", "for", "with", "that", "this", "from", "are", "was", "you"}


def _tokens(text: str) -> set:
    return {w for w in _WORD.findall((text or "").lower()) if w not in _STOP}


class MemoryRanker:
    def __init__(self, scorer: ImportanceScorer | None = None):
        self.scorer = scorer or ImportanceScorer()

    def rank(self, query: str, memories: list, limit: int = 5) -> list:
        """Return memories sorted by combined score; each gets a '_score' key.

        Expects dicts with 'content', optional 'type'/'timestamp' (long_term shape).
        """
        q = _tokens(query)
        scored = []
        for m in memories:
            t = _tokens(m.get("content", ""))
            overlap = len(q & t) / len(q) if q else 0.0
            imp = self.scorer.score(m.get("content", ""), m.get("type", "general"),
                                    m.get("timestamp"))
            score = round(0.6 * overlap + 0.4 * imp, 4)
            scored.append((score, m))
        scored.sort(key=lambda x: x[0], reverse=True)
        out = []
        for score, m in scored[:limit]:
            m = dict(m)
            m["_score"] = score
            out.append(m)
        return out
