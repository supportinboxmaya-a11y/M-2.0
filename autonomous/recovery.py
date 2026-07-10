"""
Maya 2.0 - Autonomous Recovery Strategy
---------------------------------------
Gives the autonomous loop real error-recovery intelligence.

Today the loop retries every failure the same way. This module inspects
the *kind* of failure and chooses a strategy:

    RETRY     - transient (timeout, rate limit, connection) → back off
                and try the same step again
    ALTERNATE - the tool itself failed (bad tool, permission) → try a
                different approach / drop to an LLM step
    REPLAN    - the step's premise is wrong (missing dependency, the
                plan asked for something impossible) → signal a replan
    ABORT     - unrecoverable (out of retries, hard security block) →
                stop wasting attempts

It also produces a short reflection note that gets fed back into the
next attempt's prompt, so Maya learns from the failure within the run.

Pure-Python, deterministic, fully offline — no LLM required (an optional
llm_fn deepens the reflection when available).
"""

import re
from dataclasses import dataclass, field
from typing import Dict, List, Optional

# Strategy names
RETRY = "retry"
ALTERNATE = "alternate"
REPLAN = "replan"
ABORT = "abort"

# error signature → strategy
_TRANSIENT = re.compile(
    r"timeout|timed out|rate limit|429|temporarily|connection|"
    r"reset by peer|unavailable|503|502|throttl", re.IGNORECASE)
_TOOL_FAIL = re.compile(
    r"tool .* failed|permission denied|not configured|no such tool|"
    r"unsupported|invalid argument|bad request|400|401|403", re.IGNORECASE)
_PREMISE = re.compile(
    r"not found|missing|no result|does not exist|404|empty|"
    r"depends on|prerequisite|undefined", re.IGNORECASE)
_HARD_BLOCK = re.compile(
    r"security blocked|blocked pattern|escapes the workspace|"
    r"access denied", re.IGNORECASE)


@dataclass
class RecoveryDecision:
    strategy: str
    reason: str
    backoff_seconds: float = 0.0
    reflection: str = ""
    attempt: int = 0
    max_attempts: int = 0

    def to_dict(self) -> Dict:
        return {"strategy": self.strategy, "reason": self.reason,
                "backoff_seconds": round(self.backoff_seconds, 2),
                "reflection": self.reflection,
                "attempt": self.attempt, "max_attempts": self.max_attempts}


@dataclass
class RecoveryStrategy:
    """Decides how to recover from a failed autonomous step."""
    max_attempts: int = 3
    base_delay: float = 0.5
    max_delay: float = 8.0
    llm_fn: Optional[object] = None
    _history: Dict[str, List[str]] = field(default_factory=dict)

    # ── classification ────────────────────────────────────────────
    @staticmethod
    def classify(error: str) -> str:
        e = error or ""
        if _HARD_BLOCK.search(e):
            return ABORT
        if _TRANSIENT.search(e):
            return RETRY
        if _PREMISE.search(e):
            return REPLAN
        if _TOOL_FAIL.search(e):
            return ALTERNATE
        return RETRY          # unknown → one cautious retry

    # ── main decision ─────────────────────────────────────────────
    def decide(self, node_id: str, error: str, attempt: int,
               goal: str = "", description: str = "") -> RecoveryDecision:
        """Choose a recovery strategy for a failed step.

        `attempt` is how many times this node has already been tried
        (1 after the first failure)."""
        error = (error or "").strip() or "unknown error"
        self._history.setdefault(node_id, []).append(error)
        base_strategy = self.classify(error)

        # Out of budget → abort regardless of error type.
        if attempt >= self.max_attempts:
            return RecoveryDecision(
                ABORT, f"exhausted {self.max_attempts} attempts",
                reflection=self._reflect(goal, description, error, ABORT),
                attempt=attempt, max_attempts=self.max_attempts)

        # Repeating the exact same error twice → escalate away from RETRY.
        seen = self._history[node_id]
        if base_strategy == RETRY and seen.count(error) >= 2:
            base_strategy = ALTERNATE

        backoff = 0.0
        if base_strategy == RETRY:
            backoff = min(self.max_delay, self.base_delay * (2 ** (attempt - 1)))

        return RecoveryDecision(
            strategy=base_strategy,
            reason=self._reason(base_strategy, error),
            backoff_seconds=backoff,
            reflection=self._reflect(goal, description, error, base_strategy),
            attempt=attempt, max_attempts=self.max_attempts)

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _reason(strategy: str, error: str) -> str:
        head = error.splitlines()[0][:160]
        return {
            RETRY: f"transient failure, backing off and retrying: {head}",
            ALTERNATE: f"tool/approach failed, trying an alternative: {head}",
            REPLAN: f"step premise invalid, replanning needed: {head}",
            ABORT: f"unrecoverable, aborting step: {head}",
        }[strategy]

    def _reflect(self, goal: str, description: str, error: str,
                 strategy: str) -> str:
        """A note fed back into the next attempt so Maya adapts."""
        base = {
            RETRY: "The previous attempt hit a temporary problem; the same "
                   "approach should work on retry.",
            ALTERNATE: "The previous tool/approach did not work. Solve the "
                       "task a different way, without relying on it.",
            REPLAN: "A prerequisite was missing or the step's assumption was "
                    "wrong. Reconsider what this step actually needs first.",
            ABORT: "This step could not be recovered.",
        }[strategy]
        note = (f"Reflection on failed step '{description[:80]}': {base} "
                f"(error: {error.splitlines()[0][:120]})")
        if self.llm_fn and strategy in (ALTERNATE, REPLAN):
            try:
                deeper = self.llm_fn(
                    f"Goal: {goal}\nStep: {description}\nIt failed with: "
                    f"{error[:400]}\nIn one sentence, suggest a concretely "
                    "different way to accomplish this step.")
                if deeper and deeper.strip():
                    note += " Suggested alternative: " + deeper.strip()[:300]
            except Exception:
                pass
        return note

    # ── introspection ─────────────────────────────────────────────
    def history(self, node_id: str) -> List[str]:
        return list(self._history.get(node_id, []))

    def reset(self, node_id: Optional[str] = None) -> None:
        if node_id is None:
            self._history.clear()
        else:
            self._history.pop(node_id, None)
