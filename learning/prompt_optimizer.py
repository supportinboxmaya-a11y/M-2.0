"""Prompt optimization: track variant performance, pick the best.

Epsilon-greedy: mostly exploit the best-known variant, occasionally
explore others so new variants get a fair chance.
"""
import random


class PromptOptimizer:
    def __init__(self, epsilon: float = 0.1, rng: random.Random | None = None):
        self.epsilon = epsilon
        self.rng = rng or random.Random()
        self._variants: dict = {}   # task -> {variant: {"ok": n, "fail": n}}

    def register(self, task: str, variant: str) -> None:
        self._variants.setdefault(task, {}).setdefault(variant, {"ok": 0, "fail": 0})

    def record(self, task: str, variant: str, success: bool) -> None:
        self.register(task, variant)
        self._variants[task][variant]["ok" if success else "fail"] += 1

    def _score(self, stats: dict) -> float:
        total = stats["ok"] + stats["fail"]
        return (stats["ok"] + 1) / (total + 2)     # Laplace-smoothed success rate

    def best(self, task: str) -> str | None:
        variants = self._variants.get(task, {})
        if not variants:
            return None
        return max(variants, key=lambda v: self._score(variants[v]))

    def choose(self, task: str) -> str | None:
        """Epsilon-greedy pick (exploration keeps learning alive)."""
        variants = list(self._variants.get(task, {}))
        if not variants:
            return None
        if self.rng.random() < self.epsilon:
            return self.rng.choice(variants)
        return self.best(task)

    def improve_from_feedback(self, prompt: str, issues: list) -> str:
        """Heuristic prompt hardening from observed failure issues."""
        additions = []
        joined = " ".join(issues).lower()
        if "short" in joined or "empty" in joined:
            additions.append("Give a complete, detailed answer.")
        if "goal" in joined or "address" in joined:
            additions.append("Address every part of the task explicitly.")
        if "placeholder" in joined or "todo" in joined:
            additions.append("Do not leave placeholders or TODOs; finish everything.")
        if not additions:
            additions.append("Double-check the output for correctness before answering.")
        return prompt.rstrip() + "\n" + " ".join(additions)

    def report(self) -> dict:
        return {task: {v: {**s, "score": round(self._score(s), 3)}
                       for v, s in variants.items()}
                for task, variants in self._variants.items()}
