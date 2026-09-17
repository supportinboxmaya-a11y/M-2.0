"""Confidence scoring for step results and whole plans (0.0–1.0)."""

ERROR_SIGNS = ("error", "traceback", "exception", "failed", "not found",
               "permission denied", "timeout", "cannot", "unable")
GOOD_SIGNS = ("success", "completed", "done", "created", "passed", "ok")


class ConfidenceScorer:
    def score_step(self, output: str, verified: bool | None = None,
                   attempts: int = 1) -> float:
        text = (output or "").lower()
        c = 0.6
        if verified is True:
            c += 0.3
        elif verified is False:
            c -= 0.3
        c -= min(0.3, 0.1 * sum(1 for w in ERROR_SIGNS if w in text))
        c += min(0.15, 0.05 * sum(1 for w in GOOD_SIGNS if w in text))
        c -= 0.1 * max(0, attempts - 1)          # each retry costs confidence
        if not text:
            c -= 0.2                              # empty output is suspicious
        return round(max(0.0, min(1.0, c)), 3)

    def score_plan(self, step_scores: list) -> float:
        """Plan confidence = weakest link biased mean."""
        if not step_scores:
            return 0.0
        avg = sum(step_scores) / len(step_scores)
        return round(0.6 * min(step_scores) + 0.4 * avg, 3)

    def should_replan(self, plan_score: float, threshold: float = 0.45) -> bool:
        return plan_score < threshold
