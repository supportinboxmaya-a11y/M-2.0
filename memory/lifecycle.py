"""Memory expiration & cleanup (Phase 2).

Works through the existing LongTermMemory API (get_all/delete) —
no schema changes. Store is injected, so it is testable with fakes.
"""
from datetime import datetime, timezone

from .importance import ImportanceScorer

# days each type is kept; None = keep forever
DEFAULT_TTL_DAYS = {
    "chat": 14, "episode": 60, "general": 90, "task": 90,
    "fact": None, "preference": None, "identity": None, "user": None, "project": None,
}


class MemoryLifecycle:
    def __init__(self, store, ttl_days: dict | None = None,
                 max_memories: int = 5000, scorer: ImportanceScorer | None = None):
        self.store = store
        self.ttl = {**DEFAULT_TTL_DAYS, **(ttl_days or {})}
        self.max_memories = max_memories
        self.scorer = scorer or ImportanceScorer()

    def cleanup(self, dry_run: bool = True) -> dict:
        """Delete expired memories; if still over cap, drop lowest-importance.

        Returns a report. dry_run=True (default) only reports, deletes nothing.
        """
        rows = self.store.get_all(limit=100000)
        expired = [m for m in rows if self._expired(m)]
        expired_ids = {m["id"] for m in expired}
        kept = [m for m in rows if m["id"] not in expired_ids]

        overflow = []
        if len(kept) > self.max_memories:
            kept.sort(key=lambda m: self.scorer.score(
                m.get("content", ""), m.get("type", "general"), m.get("timestamp")))
            overflow = kept[: len(kept) - self.max_memories]

        to_delete = expired + overflow
        if not dry_run:
            for m in to_delete:
                self.store.delete(m["id"])
        return {"total": len(rows), "expired": len(expired),
                "overflow": len(overflow), "deleted": 0 if dry_run else len(to_delete),
                "dry_run": dry_run}

    def _expired(self, m: dict) -> bool:
        ttl = self.ttl.get(m.get("type", "general"), 90)
        if ttl is None:
            return False
        try:
            ts = datetime.fromisoformat(str(m.get("timestamp", "")).replace("Z", "+00:00"))
            if ts.tzinfo is None:
                ts = ts.replace(tzinfo=timezone.utc)
        except (ValueError, TypeError):
            return False  # unknown age -> never auto-delete
        age_days = (datetime.now(timezone.utc) - ts).total_seconds() / 86400
        return age_days > ttl
