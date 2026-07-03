"""Final run report generation (spec: generate reports)."""
import time


class ReportGenerator:
    def generate(self, goal: str, workflow_result: dict,
                 final_output: str = "", started: float | None = None) -> str:
        prog = workflow_result.get("progress", {})
        results = workflow_result.get("results", [])
        lines = [
            "# Maya Autonomous Run Report",
            f"**Goal:** {goal}",
            f"**Status:** {workflow_result.get('status', '?')}",
            f"**Plan confidence:** {workflow_result.get('plan_confidence', 0)}",
            f"**Steps:** {prog.get('total', 0)} total — {prog.get('states', {})}",
        ]
        if started:
            lines.append(f"**Duration:** {round(time.time() - started, 1)}s")
        lines.append("\n## Steps")
        for r in results:
            mark = "SKIP" if r.get("skipped") else ("OK" if r.get("ok") else "FAIL")
            issues = "; ".join(r.get("review", {}).get("issues", []) or [])
            lines.append(f"- [{mark}] node {r.get('node')} "
                         f"(confidence {r.get('confidence', 0)})"
                         + (f" — {issues}" if issues else ""))
        fails = [r for r in results if not r.get("ok")]
        if fails:
            lines.append("\n## Failures & recovery")
            lines.append(f"{len(fails)} step(s) failed; retries were attempted "
                         "automatically by the workflow engine.")
        if final_output:
            lines.append("\n## Final output\n")
            lines.append(final_output[:4000])
        return "\n".join(lines)
