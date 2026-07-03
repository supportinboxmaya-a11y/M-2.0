"""Memory compression: fold groups of old memories into digests.

Uses the Phase 2 summarizer; works on any store exposing
get_all/add/delete (the existing LongTermMemory qualifies).
"""
from memory.summarizer import MemorySummarizer


class MemoryCompressor:
    def __init__(self, store, summarizer: MemorySummarizer | None = None,
                 group_size: int = 10):
        self.store = store
        self.summarizer = summarizer or MemorySummarizer()
        self.group_size = group_size

    def compress(self, memory_type: str = "chat", keep_recent: int = 20,
                 dry_run: bool = True) -> dict:
        """Summarize old memories of one type into a single digest memory."""
        rows = [m for m in self.store.get_all(limit=100000)
                if m.get("type") == memory_type]
        rows.sort(key=lambda m: str(m.get("timestamp", "")), reverse=True)
        old = rows[keep_recent:]
        if len(old) < self.group_size:
            return {"type": memory_type, "compressed": 0, "kept": len(rows),
                    "digest_created": False, "dry_run": dry_run}
        texts = [m.get("content", "") for m in old]
        digest = self.summarizer.summarize(texts, max_sentences=6)
        chars_before = sum(len(t) for t in texts)
        if not dry_run:
            self.store.add(f"[compressed digest of {len(old)} {memory_type} memories] "
                           + digest, memory_type=f"{memory_type}_digest")
            for m in old:
                self.store.delete(m["id"])
        return {"type": memory_type, "compressed": len(old),
                "kept": keep_recent, "digest_created": not dry_run,
                "chars_before": chars_before, "chars_after": len(digest),
                "saving_pct": round(100 * (1 - len(digest) / chars_before), 1)
                if chars_before else 0, "dry_run": dry_run}
