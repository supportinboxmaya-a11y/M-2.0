"""Memory importance scoring (Phase 2).

Scores 0.0–1.0 from content signals, type weight, and recency.
Pure function style — no I/O, fully testable offline.
"""
from datetime import datetime, timezone

TYPE_WEIGHT = {
    "preference": 0.9, "identity": 0.9, "project": 0.8, "user": 0.8,
    "fact": 0.7, "task": 0.6, "episode": 0.5, "general": 0.4, "chat": 0.3,
}
SIGNAL_WORDS = ("always", "never", "important", "remember", "prefer", "must",
                "deadline", "password", "key", "error", "failed", "success")


class ImportanceScorer:
    def score(self, content: str, memory_type: str = "general",
              timestamp: str | None = None, access_count: int = 0) -> float:
        base = TYPE_WEIGHT.get(memory_type, 0.4)
        text = (content or "").lower()
        signal = min(0.2, 0.05 * sum(1 for w in SIGNAL_WORDS if w in text))
        length = min(0.1, len(text) / 2000)          # richer content, small boost
        access = min(0.15, access_count * 0.03)      # frequently used memories matter
        rec = self._recency(timestamp)
        return round(min(1.0, base + signal + length + access) * rec, 4)

    def _recency(self, timestamp: str | None) -> float:
        """1.0 fresh -> 0.5 at ~90 days. Unknown timestamps: neutral 0.9."""
        if not timestamp:
            return 0.9
        try:
            ts = datetime.fromisoformat(str(timestamp).replace("Z", "+00:00"))
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
            days = max(0.0, (datetime.now(timezone.utc) - ts).total_seconds() / 86400)
            return max(0.5, 1.0 - days / 180.0)
        except (ValueError, TypeError):
            return 0.9
