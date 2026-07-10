"""
Maya 2.0 - Ultra Memory Manager
---------------------------------
Unified interface for all memory systems.
Short-term, long-term, episodic, semantic, vector — সব এক জায়গায়।
"""

from typing import List, Dict, Optional, Any
from datetime import datetime
from .short_term import ShortTermMemory
from .long_term import LongTermMemory
from .episodic_memory import EpisodicMemory
from .semantic_memory import SemanticMemory
from .vector_memory import VectorMemory
from .context_manager import ContextManager
from .importance import ImportanceScorer
from .ranker import MemoryRanker, _tokens
from .summarizer import MemorySummarizer
from .lifecycle import MemoryLifecycle
from maya_logging.logger import get_logger

log = get_logger("memory")


class MemoryManager:
    """
    Maya-র unified memory system.
    - Short-term: current session (fast, in-memory)
    - Long-term: SQLite (persistent across sessions)
    - Episodic: past task runs with outcomes
    - Semantic: facts and knowledge base
    - Vector: semantic similarity search
    - Context: current task context
    """

    def __init__(self):
        log.info("Initializing memory systems...")
        self.short_term = ShortTermMemory(capacity=50)
        self.long_term = LongTermMemory()
        self.episodic = EpisodicMemory()
        self.semantic = SemanticMemory()
        self.vector = VectorMemory(fallback_store=self.long_term)
        self.context = ContextManager()
        # These four existed as real, tested modules but were never wired
        # into MemoryManager — add() never scored importance, search()
        # never ranked by it, nothing deduplicated, and nothing compressed
        # old memories down. They're connected now.
        self.scorer = ImportanceScorer()
        self.ranker = MemoryRanker(self.scorer)
        self.summarizer = MemorySummarizer()
        self.lifecycle = MemoryLifecycle(self.long_term, scorer=self.scorer)
        self._session_start = datetime.now().isoformat()
        log.info("Memory systems ready")

    def add(self, content: str, memory_type: str = "general", metadata: Dict = None) -> str:
        """
        Content সব memory systems এ add করে।
        Returns memory ID — or the existing memory's ID if this is a
        near-duplicate of something already stored (dedup check below),
        so callers can't tell the difference without checking metadata.
        """
        if not content or not content.strip():
            return ""

        existing_id = self._find_duplicate(content, memory_type)
        if existing_id:
            log.debug(f"Duplicate memory skipped [{memory_type}]: {content[:60]}")
            return existing_id

        metadata = dict(metadata or {})
        metadata["importance"] = self.scorer.score(content, memory_type)

        # Short-term এ always add
        self.short_term.add(content, metadata)

        # Long-term এ persist করি
        mid = self.long_term.add(content, memory_type, metadata)

        # Vector memory তে semantic search এর জন্য
        self.vector.add(content, doc_id=mid, metadata=metadata)
        self.vector.invalidate()

        log.debug(f"Memory added [{memory_type}]: {content[:60]}")
        return mid

    def _find_duplicate(self, content: str, memory_type: str, threshold: float = 0.87) -> Optional[str]:
        """Token-overlap check against recent memories of the same type.
        Deliberately cheap (no embeddings/network call) — good enough to
        stop the same fact/preference being saved over and over, which is
        what was actually happening with none of this in place before."""
        new_tokens = _tokens(content)
        if not new_tokens:
            return None
        recent = self.long_term.get_all(limit=200, memory_type=memory_type)
        for m in recent:
            existing_tokens = _tokens(m.get("content", ""))
            if not existing_tokens:
                continue
            overlap = len(new_tokens & existing_tokens) / len(new_tokens | existing_tokens)
            if overlap >= threshold:
                return m["id"]
        return None

    def search(self, query: str, limit: int = 5, memory_type: str = None) -> List[Dict]:
        """
        Query দিয়ে memory search করে।
        Vector search + keyword search combine করে, তারপর relevance +
        importance দিয়ে rank করে — আগে শুধু vector results আগে, keyword
        results পরে জোড়া লাগানো হত, প্রকৃত ranking ছাড়াই।
        """
        results = []

        # Vector semantic search
        try:
            vector_results = self.vector.search(query, limit=limit * 2)
            results.extend(vector_results)
        except Exception as e:
            log.warning(f"Vector search failed: {e}")

        # Keyword search in long-term
        try:
            keyword_results = self.long_term.search(query, limit=limit * 2, memory_type=memory_type)
            existing = {r.get("content", "") for r in results}
            for r in keyword_results:
                if r.get("content", "") not in existing:
                    results.append(r)
                    existing.add(r.get("content", ""))
        except Exception as e:
            log.warning(f"Long-term search failed: {e}")

        ranked = self.ranker.rank(query, results, limit=limit)
        log.debug(f"Memory search: '{query}' -> {len(ranked)} results")
        return ranked

    def remember_task(self, goal: str, steps: List[Dict], result: str, success: bool,
                      tools_used: List[str] = None, errors: List[str] = None):
        """
        Task execution episode save করে।
        """
        self.episodic.add_episode(goal, steps, result, success)

        # Summary long-term memory তে add
        status = "SUCCESS" if success else "FAILURE"
        summary = f"[{status}] Goal: {goal} | Result: {result[:200]}"
        self.add(summary, memory_type="task_episode", metadata={
            "success": success,
            "tools_used": tools_used or [],
            "errors": errors or []
        })
        log.info(f"Task episode saved: {status} | {goal[:60]}")

    def get_similar_tasks(self, goal: str, limit: int = 3) -> List[Dict]:
        """Similar past tasks খুঁজে দেয়।"""
        return self.episodic.get_similar(goal, limit=limit)

    def add_fact(self, fact: str, topic: str = "general"):
        """Knowledge base এ fact add করে।"""
        self.semantic.add_fact(fact, topic)
        self.add(fact, memory_type=f"fact:{topic}")
        log.debug(f"Fact added [{topic}]: {fact[:60]}")

    def search_facts(self, query: str, limit: int = 5) -> List[Dict]:
        """Facts search করে।"""
        return self.semantic.search_facts(query, limit=limit)

    def get_context(self) -> str:
        """Current task context string দেয়।"""
        return self.context.get_context_string()

    def set_goal(self, goal: str, task_id: str = None):
        """New goal set করে।"""
        self.context.set_goal(goal, task_id)
        self.short_term.clear()

    def add_step_result(self, step: Dict, result: Dict):
        """Step result context এ add করে।"""
        self.context.add_step_result(step, result)

        # Successful results memory তে save করি
        if result.get("success") and result.get("result"):
            self.short_term.add(
                f"Step {str(step.get('step', ''))}: {str(result.get('result', ''))[:300]}",
                {"type": "step_result"}
            )

    def get_relevant_memories(self, goal: str, limit: int = 5) -> str:
        """
        Goal এর জন্য সবচেয়ে relevant memories দেয়।
        Planner এর জন্য context হিসেবে use হয়।
        """
        memories = self.search(goal, limit=limit)
        if not memories:
            return ""

        lines = []
        for m in memories:
            content = m.get("content", "")
            if content:
                lines.append(f"- {content[:200]}")

        return "\n".join(lines)

    def get_tips_for_goal(self, goal: str) -> str:
        """Past similar tasks থেকে tips দেয়।"""
        similar = self.get_similar_tasks(goal, limit=3)
        if not similar:
            return ""

        tips = []
        for task in similar:
            if task.get("success"):
                tips.append(f"Similar success: {task.get('goal', '')[:80]}")
            else:
                tips.append(f"Avoid: {task.get('goal', '')[:80]} failed")

        return "\n".join(tips)

    def compress(self, memory_type: str = "general", keep_recent: int = 20,
                 dry_run: bool = True) -> Dict:
        """Summarizes the older, lower-importance memories of a type into a
        single compact entry and deletes the originals — actual compression,
        not just an on-demand summary for display (that's what /memory/summary
        already did; this is the first thing that actually shrinks storage).
        Keeps the `keep_recent` most recent memories of this type untouched.
        """
        rows = self.long_term.get_all(limit=100000, memory_type=memory_type)
        if len(rows) <= keep_recent:
            return {"compressed": 0, "kept": len(rows), "dry_run": dry_run}

        rows.sort(key=lambda m: m.get("timestamp", ""), reverse=True)
        to_compress = rows[keep_recent:]
        if not to_compress:
            return {"compressed": 0, "kept": len(rows), "dry_run": dry_run}

        summary_text = self.summarizer.summarize([m.get("content", "") for m in to_compress])
        result = {
            "compressed": len(to_compress), "kept": keep_recent,
            "summary_preview": summary_text[:200], "dry_run": dry_run,
        }
        if not dry_run and summary_text:
            for m in to_compress:
                self.long_term.delete(m["id"])
                self.vector.delete(m["id"])
            summary_meta = {"source_type": memory_type, "source_count": len(to_compress)}
            sid = self.long_term.add(
                f"[Compressed summary of {len(to_compress)} older '{memory_type}' memories] {summary_text}",
                memory_type="compressed",
                metadata=summary_meta,
            )
            self.vector.add(
                f"[Compressed summary of {len(to_compress)} older '{memory_type}' memories] {summary_text}",
                doc_id=sid, metadata=summary_meta)
            self.vector.invalidate()
        return result

    def delete(self, memory_id: str) -> bool:
        """Deletes a memory by id. api.py's DELETE endpoint checked for this
        method with hasattr() before this existed — it was always False, so
        every 'delete' from the Memory page quietly did nothing on the
        backend even though the UI reported success.

        Also removes the memory's vector — before this, deleted memories
        kept surfacing in vector search results forever."""
        ok = self.long_term.delete(memory_id)
        if ok:
            self.vector.delete(memory_id)
            self.vector.invalidate()
        return ok

    def update(self, memory_id: str, new_content: str) -> Optional[Dict]:
        """Edits a memory, re-scoring importance and keeping the old
        content as a version instead of losing it."""
        new_meta = {"importance": self.scorer.score(new_content)}
        result = self.long_term.update(memory_id, new_content, new_metadata=new_meta)
        if result:
            # Re-embed: without this, vector search kept returning the
            # pre-edit content for updated memories.
            self.vector.update(memory_id, new_content, metadata=new_meta)
            self.vector.invalidate()
        return result

    def get_versions(self, memory_id: str) -> List[Dict]:
        return self.long_term.get_versions(memory_id)

    def cleanup(self, dry_run: bool = True) -> Dict:
        """TTL/overflow cleanup that also prunes the vectors of every
        deleted memory, so vector search can never return expired
        content. Prefer this over calling lifecycle.cleanup directly."""
        report = self.lifecycle.cleanup(dry_run=dry_run)
        if not dry_run:
            valid = {m.get("id") for m in self.long_term.get_all(limit=100000)}
            report["vectors_pruned"] = self.vector.prune(valid)
            self.vector.invalidate()
        return report

    def get_analytics(self) -> Dict:
        return self.long_term.get_analytics()

    def get_all(self, limit: int = 50, memory_type: str = None) -> List[Dict]:
        """Same story as delete() — api.py's /memory/stats checked for this
        with hasattr() and it didn't exist, so total count was always 0."""
        return self.long_term.get_all(limit=limit, memory_type=memory_type)

    def count(self) -> int:
        return self.long_term.count()

    def get_stats(self) -> Dict:
        """Memory system statistics।"""
        return {
            "total_memories": self.long_term.count(),
            "vector_engine": self.vector.engine,
            "vector_count": self.vector.count(),
            "short_term_items": len(self.short_term.get_all()),
            "session_start": self._session_start,
            "context_goal": self.context.current_goal,
            "steps_completed": self.context.total_steps,
            "steps_successful": self.context.successful_steps,
        }

    def clear_session(self):
        """Current session clear করে।"""
        self.short_term.clear()
        self.context.clear()
        log.info("Session memory cleared")
