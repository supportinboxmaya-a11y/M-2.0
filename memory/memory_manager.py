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
        self.vector = VectorMemory()
        self.context = ContextManager()
        self._session_start = datetime.now().isoformat()
        log.info("Memory systems ready")

    def add(self, content: str, memory_type: str = "general", metadata: Dict = None) -> str:
        """
        Content সব memory systems এ add করে।
        Returns memory ID.
        """
        if not content or not content.strip():
            return ""

        # Short-term এ always add
        self.short_term.add(content, metadata or {})

        # Long-term এ persist করি
        mid = self.long_term.add(content, memory_type, metadata)

        # Vector memory তে semantic search এর জন্য
        self.vector.add(content, doc_id=mid, metadata=metadata)

        log.debug(f"Memory added [{memory_type}]: {content[:60]}")
        return mid

    def search(self, query: str, limit: int = 5, memory_type: str = None) -> List[Dict]:
        """
        Query দিয়ে memory search করে।
        Vector search + keyword search combine করে।
        """
        results = []

        # Vector semantic search
        try:
            vector_results = self.vector.search(query, limit=limit)
            results.extend(vector_results)
        except Exception as e:
            log.warning(f"Vector search failed: {e}")

        # Keyword search in long-term
        try:
            keyword_results = self.long_term.search(query, limit=limit)
            # Deduplicate
            existing = {r.get("content", "") for r in results}
            for r in keyword_results:
                if r.get("content", "") not in existing:
                    results.append(r)
                    existing.add(r.get("content", ""))
        except Exception as e:
            log.warning(f"Long-term search failed: {e}")

        log.debug(f"Memory search: '{query}' -> {len(results)} results")
        return results[:limit]

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

    def get_stats(self) -> Dict:
        """Memory system statistics।"""
        return {
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
