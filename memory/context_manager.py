"""
Maya 2.0 - Ultra Context Manager
----------------------------------
Conversation এবং task context intelligently manage করে।
Token limit মাথায় রেখে সবচেয়ে relevant context রাখে।
"""

import json
from typing import List, Dict, Optional, Any
from collections import deque
from datetime import datetime


class ContextManager:
    """
    Maya-র context management engine.
    - Short-term conversation history রাখে
    - Task context track করে
    - Relevant context বেছে দেয়
    - Token limit এর মধ্যে রাখে
    - Important context prioritize করে
    """

    def __init__(self, max_tokens: int = 4000, max_messages: int = 20):
        self.max_tokens = max_tokens
        self.max_messages = max_messages

        # Current session
        self.current_goal: Optional[str] = None
        self.current_plan: Optional[Dict] = None
        self.current_task_id: Optional[str] = None

        # Message history
        self.messages: deque = deque(maxlen=max_messages)

        # Step results
        self.step_results: List[Dict] = []

        # Important facts discovered during execution
        self.discovered_facts: List[str] = []

        # Errors and warnings
        self.errors: List[Dict] = []

        # Session metadata
        self.session_start = datetime.now().isoformat()
        self.total_steps = 0
        self.successful_steps = 0

    def set_goal(self, goal: str, task_id: str = None):
        """নতুন goal set করে।"""
        self.current_goal = goal
        self.current_task_id = task_id
        self.step_results = []
        self.discovered_facts = []
        self.errors = []
        self.total_steps = 0
        self.successful_steps = 0
        self._add_message("system", f"New goal set: {goal}")

    def set_plan(self, plan: Dict):
        """Current plan set করে।"""
        self.current_plan = plan

    def add_step_result(self, step: Dict, result: Dict):
        """Step execution result add করে।"""
        entry = {
            "step": step.get("step"),
            "description": step.get("description", ""),
            "tool": step.get("tool"),
            "success": result.get("success", False),
            "result": str(result.get("result", ""))[:500],
            "error": result.get("error"),
            "timestamp": datetime.now().isoformat()
        }
        self.step_results.append(entry)
        self.total_steps += 1
        if result.get("success"):
            self.successful_steps += 1

        # Important results থেকে facts extract করি
        if result.get("success") and result.get("result"):
            self._extract_facts(str(result.get("result", "")))

    def add_error(self, error: str, step: Any = None, recoverable: bool = True):
        """Error record করে।"""
        self.errors.append({
            "error": error,
            "step": step,
            "recoverable": recoverable,
            "timestamp": datetime.now().isoformat()
        })
        self._add_message("error", f"Error at step {step}: {error}")

    def add_fact(self, fact: str):
        """Important fact add করে।"""
        if fact and fact not in self.discovered_facts:
            self.discovered_facts.append(fact[:300])

    def add_user_message(self, message: str):
        self._add_message("user", message)

    def add_assistant_message(self, message: str):
        self._add_message("assistant", message)

    def get_context_string(self, max_length: int = 2000) -> str:
        """
        Current context এর string representation দেয়।
        Most relevant info priority পায়।
        """
        parts = []

        if self.current_goal:
            parts.append(f"Current Goal: {self.current_goal}")

        # Recent successful step results
        recent_success = [r for r in self.step_results[-5:] if r.get("success")]
        if recent_success:
            parts.append("Recent results:")
            for r in recent_success:
                parts.append(f"  Step {r['step']}: {r['result'][:200]}")

        # Discovered facts
        if self.discovered_facts:
            parts.append("Discovered facts:")
            for f in self.discovered_facts[-5:]:
                parts.append(f"  - {f}")

        # Recent errors
        recent_errors = self.errors[-2:]
        if recent_errors:
            parts.append("Recent errors:")
            for e in recent_errors:
                parts.append(f"  - {e['error'][:100]}")

        context = "\n".join(parts)
        return context[:max_length]

    def get_step_results_summary(self) -> str:
        """Step results এর summary দেয়।"""
        if not self.step_results:
            return "No steps executed yet"

        lines = []
        for r in self.step_results:
            status = "✅" if r.get("success") else "❌"
            lines.append(f"{status} Step {r['step']}: {r['description'][:50]} → {r['result'][:100] if r.get('success') else r.get('error', 'failed')[:100]}")

        return "\n".join(lines)

    def get_messages_for_llm(self) -> List[Dict]:
        """LLM কে দেওয়ার জন্য message history।"""
        return list(self.messages)

    def get_progress(self) -> Dict:
        """Current progress summary।"""
        return {
            "goal": self.current_goal,
            "total_steps": self.total_steps,
            "successful_steps": self.successful_steps,
            "failed_steps": self.total_steps - self.successful_steps,
            "success_rate": f"{(self.successful_steps/self.total_steps*100):.0f}%" if self.total_steps > 0 else "0%",
            "errors": len(self.errors),
            "facts_discovered": len(self.discovered_facts)
        }

    def clear(self):
        """Context clear করে।"""
        self.current_goal = None
        self.current_plan = None
        self.current_task_id = None
        self.step_results = []
        self.discovered_facts = []
        self.errors = []
        self.messages.clear()
        self.total_steps = 0
        self.successful_steps = 0

    def _add_message(self, role: str, content: str):
        self.messages.append({
            "role": role,
            "content": content,
            "timestamp": datetime.now().isoformat()
        })

    def _extract_facts(self, result_text: str):
        """Result থেকে important facts extract করে।"""
        if len(result_text) > 100:
            self.discovered_facts.append(result_text[:300])
