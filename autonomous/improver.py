"""Output improvement loop: reflect -> revise -> accept best (spec: improve outputs)."""
from brain.reflection import Reflector


class OutputImprover:
    def __init__(self, llm_fn=None, max_rounds: int = 2):
        self.llm_fn = llm_fn
        # heuristic critique keeps acceptance deterministic; llm only revises
        self.reflector = Reflector(None)
        self.max_rounds = max_rounds

    def improve(self, goal: str, output: str) -> dict:
        current = output or ""
        history = []
        for round_no in range(1, self.max_rounds + 1):
            review = self.reflector.critique(goal, current)
            history.append({"round": round_no, "issues": review["issues"]})
            if review["acceptable"] or not self.llm_fn:
                return {"output": current, "improved": round_no > 1,
                        "rounds": history, "acceptable": review["acceptable"]}
            try:
                revised = self.llm_fn(
                    f"Goal: {goal}\nDraft: {current[:4000]}\n"
                    f"Problems: {'; '.join(review['issues'])}\n"
                    "Rewrite the draft fixing every problem. Return only the result.")
                if revised and revised.strip():
                    current = revised.strip()
            except Exception:
                break
        final = self.reflector.critique(goal, current)
        return {"output": current, "improved": True,
                "rounds": history, "acceptable": final["acceptable"]}
