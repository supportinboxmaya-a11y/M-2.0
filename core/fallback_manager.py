"""
Maya 2.0 - Ultra Fallback Manager
------------------------------------
যখন কিছু fail করে, intelligent recovery করে।
"""

import json
from typing import Dict, List, Optional
from llm.router import LLMRouter


class FallbackManager:
    """
    Maya-র failure recovery engine.
    - Step failure analyze করে
    - Alternative strategies তৈরি করে
    - Provider switch করে
    - Tool alternatives খোঁজে
    - Max retry limit manage করে
    """

    TOOL_ALTERNATIVES = {
        "web_search": ["web_scrape"],
        "web_scrape": ["web_search"],
        "run_code": ["run_shell", "run_terminal"],
        "run_shell": ["run_terminal", "run_code"],
        "run_terminal": ["run_shell"],
        "read_file": [],
        "write_file": [],
    }

    def __init__(self, planner=None, router: LLMRouter = None):
        self.planner = planner
        self.router = router
        self.recovery_history: List[Dict] = []
        self.max_global_retries = 5
        self.global_retry_count = 0

    def recover(self, goal: str, error: str, completed_steps: List[Dict], failed_step: Dict, context: str = "") -> Dict:
        """
        Failure থেকে recover করার strategy তৈরি করে।
        """
        self.global_retry_count += 1

        if self.global_retry_count > self.max_global_retries:
            return {
                "should_abort": True,
                "reason": f"Max retries ({self.max_global_retries}) exceeded",
                "recovery_strategy": "abort",
                "new_steps": []
            }

        # Error type detect করি
        error_type = self._detect_error_type(error)

        # Recovery strategy বেছে নিই
        strategy = self._choose_strategy(error_type, failed_step, completed_steps)

        recovery = {
            "should_abort": False,
            "error_type": error_type,
            "recovery_strategy": strategy,
            "retry_count": self.global_retry_count,
            "new_steps": []
        }

        if strategy == "switch_tool":
            alt_tool = self._get_alternative_tool(failed_step.get("tool"))
            if alt_tool:
                new_step = {**failed_step, "tool": alt_tool, "description": f"[Retry with {alt_tool}] {failed_step.get('description', '')}"}
                recovery["new_steps"] = [new_step]
                recovery["message"] = f"Switching to alternative tool: {alt_tool}"

        elif strategy == "replan" and self.planner:
            completed_summary = "\n".join([
                f"Step {s.get('step')}: {s.get('description')} → {s.get('result', 'done')}"
                for s in completed_steps if s.get("success")
            ])
            new_plan = self.planner.replan(goal, error, completed_steps, failed_step)
            recovery["new_steps"] = new_plan.get("new_steps", [])
            recovery["message"] = new_plan.get("recovery_strategy", "Replanning...")

        elif strategy == "simplify":
            # Step টা ছোট করে আবার try করি
            simplified = {
                **failed_step,
                "tool": None,
                "description": f"Simplified: {failed_step.get('description', goal)}"
            }
            recovery["new_steps"] = [simplified]
            recovery["message"] = "Simplifying the approach"

        elif strategy == "skip":
            recovery["new_steps"] = []
            recovery["message"] = "Skipping failed step and continuing"

        self.recovery_history.append({
            "error": error,
            "error_type": error_type,
            "strategy": strategy,
            "success": None  # Will be updated later
        })

        return recovery

    def select_fallback_provider(self, failed_provider: str, available_providers: List[str], task_type: str = "general") -> Optional[str]:
        """Failed provider এর বদলে best alternative বেছে নেয়।"""
        alternatives = [p for p in available_providers if p != failed_provider]
        if not alternatives:
            return None

        # Task type based preference
        task_preferences = {
            "coding": ["deepseek", "openai", "groq"],
            "research": ["gemini", "claude", "openai"],
            "general": ["groq", "gemini", "openai", "claude", "deepseek"]
        }

        preferred = task_preferences.get(task_type, task_preferences["general"])
        for p in preferred:
            if p in alternatives:
                return p

        return alternatives[0]

    def should_retry(self, error: str, attempt: int, max_attempts: int) -> bool:
        """Retry করা উচিত কিনা।"""
        if attempt >= max_attempts:
            return False

        # এই errors retry করা ঠিক না
        no_retry_errors = ["permission denied", "api key", "authentication", "unauthorized", "quota exceeded"]
        error_lower = error.lower()
        if any(e in error_lower for e in no_retry_errors):
            return False

        return True

    def _detect_error_type(self, error: str) -> str:
        """Error type detect করে।"""
        error_lower = error.lower()
        if any(k in error_lower for k in ["timeout", "timed out", "connection"]):
            return "network"
        if any(k in error_lower for k in ["permission", "access denied", "unauthorized"]):
            return "permission"
        if any(k in error_lower for k in ["api key", "authentication", "invalid key"]):
            return "auth"
        if any(k in error_lower for k in ["rate limit", "quota", "too many requests"]):
            return "rate_limit"
        if any(k in error_lower for k in ["not found", "404", "no such file"]):
            return "not_found"
        if any(k in error_lower for k in ["syntax", "parse", "json"]):
            return "parse"
        return "unknown"

    def _choose_strategy(self, error_type: str, failed_step: Dict, completed_steps: List[Dict]) -> str:
        """Error type অনুযায়ী best recovery strategy বেছে নেয়।"""
        if error_type == "auth":
            return "abort"  # API key নেই, কিছু করার নেই
        if error_type == "rate_limit":
            return "replan"  # Different provider দিয়ে try
        if error_type == "network":
            return "switch_tool"  # Alternative tool try
        if error_type == "not_found":
            return "replan"  # Different approach
        if error_type == "parse":
            return "simplify"  # Simpler approach
        if failed_step.get("tool"):
            return "switch_tool"  # Tool ছিল, alternative try
        return "replan"

    def _get_alternative_tool(self, tool_name: Optional[str]) -> Optional[str]:
        """Tool এর alternative বেছে দেয়।"""
        if not tool_name:
            return None
        alternatives = self.TOOL_ALTERNATIVES.get(tool_name, [])
        return alternatives[0] if alternatives else None

    def reset(self):
        """Recovery counter reset করে।"""
        self.global_retry_count = 0
        self.recovery_history = []
