"""Phase 42 tests: autonomous self-improvement loop (propose-only, gated).

Covers:
- Gap analysis from seeded self-model outcomes (weak task types ranked,
  skill coverage detected).
- propose() is propose-only: drafts a proposal, executes NOTHING.
- execute_proposal refuses unapproved proposals (human gate).
- Skill proposal execution distills buffered episodes into a stored skill.
- Tool proposal execution goes through ToolCreator (AST scan blocks
  dangerous code; approval denial blocks loading).
- Kernel _distill_episode hook: no-op without engine, delegates with it.
- Flag-off posture: engine absent -> routes would 503 (engine None here),
  kernel untouched.
"""

import json
import os
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

os.environ.setdefault("SELF_IMPROVE_DIR",
                      tempfile.mkdtemp(prefix="maya_p42_"))


class FakeSelfModel:
    """Minimal stand-in matching SelfModel.weaknesses()/type_stats()."""

    def __init__(self):
        self._stats = [
            {"task_type": "deployment", "attempts": 4, "success_rate": 0.25,
             "avg_quality": 3.1},
            {"task_type": "data_analysis", "attempts": 2, "success_rate": 0.0,
             "avg_quality": None},
            {"task_type": "question_answering", "attempts": 10,
             "success_rate": 0.9, "avg_quality": 8.0},  # not weak
        ]

    def weaknesses(self, min_attempts=2, max_success_rate=0.5):
        return [s for s in self._stats
                if s["attempts"] >= min_attempts
                and s["success_rate"] <= max_success_rate]


class FakeProceduralMemory:
    def __init__(self):
        self.stored = []

    def search_skills(self, query, limit=5):
        # Only 'data analysis' has an existing covering skill.
        if "data" in query.lower():
            return [{"name": "analyze_csv"}]
        return []

    def store_skill(self, skill):
        self.stored.append(skill)
        return skill.id


SKILL_JSON = json.dumps({
    "name": "deploy_service_safely",
    "description": "Deploy with pre-checks and rollback",
    "preconditions": ["ssh reachable"],
    "procedure": [{"step": 1, "action": "check disk", "tool": "run_shell"}],
    "confidence": 0.7,
})

FAKE_LLM = lambda prompt: (SKILL_JSON if "episodes" in prompt.lower()
                           or "Episodes" in prompt else "```python\n"
                           "def register_tools(registry):\n"
                           "    registry.register('auto_tool', lambda: 'ok', "
                           "'test tool', category='self_improved')\n```")

DANGEROUS_LLM = lambda prompt: (
    "def register_tools(registry):\n"
    "    import subprocess\n"
    "    registry.register('evil', lambda: subprocess.run('ls'), 'x')")


from infrastructure.self_improvement import (  # noqa: E402
    SelfImprovementEngine,
)

_PROPOSALS_FILE = (Path(os.environ["SELF_IMPROVE_DIR"])
                   / "proposals.json")


class ProposalIsolated(unittest.TestCase):
    """Each test starts with an empty proposal store."""

    def setUp(self):
        if _PROPOSALS_FILE.exists():
            _PROPOSALS_FILE.unlink()


def make_engine(llm=FAKE_LLM, **kw):
    defaults = dict(
        self_model=FakeSelfModel(),
        procedural_memory=FakeProceduralMemory(),
        llm_fn=llm,
    )
    defaults.update(kw)
    return SelfImprovementEngine(**defaults)


class TestGapAnalysis(unittest.TestCase):
    def test_detects_and_ranks_weaknesses(self):
        e = make_engine()
        gaps = e.analyze_gaps()
        self.assertEqual(len(gaps), 2)
        types = [g["task_type"] for g in gaps]
        self.assertIn("deployment", types)
        self.assertIn("data_analysis", types)
        self.assertNotIn("question_answering", types)

    def test_uncovered_gap_ranks_higher(self):
        e = make_engine()
        gaps = e.analyze_gaps()
        # deployment: no skill coverage; data_analysis: covered by skill.
        self.assertEqual(gaps[0]["task_type"], "deployment")
        self.assertEqual(gaps[0]["suggested_action"], "create_skill_or_tool")
        self.assertEqual(
            [s for s in gaps if s["task_type"] == "data_analysis"][0]
            ["suggested_action"], "reinforce_skill")

    def test_no_self_model_no_crash(self):
        e = make_engine(self_model=None)
        self.assertEqual(e.analyze_gaps(), [])


class TestProposeOnly(ProposalIsolated):
    def test_propose_creates_draft_without_side_effects(self):
        e = make_engine()
        prop = e.propose(goal_hint="deploy the api to vps")
        self.assertEqual(prop["status"], "proposed")
        self.assertEqual(len(e.list_proposals()), 1)
        # Nothing executed: no skills stored, no tools created.
        self.assertEqual(e.procedural.stored, [])
        self.assertIsNone(e.tool_creator)

    def test_propose_with_no_gaps_raises(self):
        e = make_engine(self_model=FakeSelfModel())
        e.self_model._stats = []
        with self.assertRaises(ValueError):
            e.propose()

    def test_execute_requires_approval_first(self):
        e = make_engine()
        prop = e.propose()
        result = e.execute_proposal(prop["id"])
        self.assertFalse(result["success"])
        self.assertIn("approval", result["error"].lower())


class TestSkillExecution(ProposalIsolated):
    def _approved_skill_proposal(self, e):
        prop = e.propose(gap={
            "task_type": "deployment", "attempts": 4,
            "success_rate": 0.25, "priority": 3.0,
            "suggested_action": "create_skill"})
        # Seed the episode buffer as the kernel hook would.
        for i in range(3):
            e.observe_episode({
                "id": f"ep{i}", "goal": f"deploy service number {i}",
                "success": True,
                "steps": [{"action": "scp", "tool": "shell", "success": True}],
            })
        e.approve_proposal(prop["id"], approved=True)
        return prop

    def test_executes_approved_skill_proposal(self):
        e = make_engine()
        prop = self._approved_skill_proposal(e)
        result = e.execute_proposal(prop["id"])
        self.assertTrue(result["success"], result)
        # The 3rd seeded episode already auto-distilled via the hook;
        # the approved execution adds its own distilled skill.
        self.assertGreaterEqual(len(e.procedural.stored), 1)
        self.assertEqual(result["skill"]["name"], "deploy_service_safely")
        self.assertEqual(e.get_proposal(prop["id"])["status"], "executed")

    def test_insufficient_episodes_blocks_execution(self):
        e = make_engine()
        prop = e.propose(gap={
            "task_type": "deployment", "attempts": 4,
            "success_rate": 0.25, "suggested_action": "create_skill"})
        e.approve_proposal(prop["id"], True)
        result = e.execute_proposal(prop["id"])
        self.assertFalse(result["success"])
        self.assertIn("episode", result["error"].lower())


class TestToolExecution(ProposalIsolated):
    def _proposal(self, e):
        return e.propose(gap={
            "task_type": "report_generation", "attempts": 3,
            "success_rate": 0.33,
            "suggested_action": "create_skill_or_tool"})

    def test_tool_draft_generated_at_propose_time(self):
        e = make_engine(tool_creator=object())
        prop = self._proposal(e)
        self.assertEqual(prop["type"], "tool")
        self.assertIsNotNone(prop["draft_code"])
        # Still nothing loaded.
        self.assertEqual(prop["status"], "proposed")

    def test_dangerous_code_blocked_by_ast_scan(self):
        from tools.system.tool_creator import scan_risk
        e = make_engine(llm=DANGEROUS_LLM, tool_creator=object())
        prop = self._proposal(e)
        issues = scan_risk(prop["draft_code"])
        self.assertTrue(issues, "AST scan must flag subprocess use")

    def test_missing_tool_creator_refuses(self):
        e = make_engine(tool_creator=None)
        prop = self._proposal(e)
        e.approve_proposal(prop["id"], True)
        result = e.execute_proposal(prop["id"])
        self.assertFalse(result["success"])

    def test_real_tool_creator_approval_gate_holds(self):
        """End-to-end through ToolCreator: draft loads only after the
        human approval gate — which denies by default in this fake."""
        class DenyingApproval:
            def needs_approval(self, action, risk_level="low"):
                return True

            def request_approval(self, action, reason="", risk_level="high",
                                 task_id=None):
                return False

        class FakeLoader:
            def __init__(self):
                self.installed = []

            def install_from_code(self, name, code):
                self.installed.append(name)
                return {"registered_tools": ["auto_x"]}

        loader = FakeLoader()
        tc = __import__("tools.system.tool_creator", fromlist=[
            "ToolCreator"]).ToolCreator(loader, DenyingApproval())
        e = make_engine(tool_creator=tc)
        prop = self._proposal(e)
        e.approve_proposal(prop["id"], True)
        result = e.execute_proposal(prop["id"])
        self.assertTrue(result["success"], result)  # create_tool returns msg
        self.assertEqual(loader.installed, [])  # but NOTHING was installed


class TestKernelHook(unittest.TestCase):
    def test_distill_hook_noop_without_engine(self):
        from infrastructure.cognitive_kernel import CognitiveKernel
        k = CognitiveKernel.__new__(CognitiveKernel)
        k.self_improvement = None
        calls = []

        def fake_audit(event, detail=""):
            calls.append(event)
        k._audit = fake_audit
        CognitiveKernel._distill_episode(k, {"goal": "x", "success": True})
        self.assertEqual(calls, [])

    def test_distill_hook_delegates_and_audits_errors(self):
        from infrastructure.cognitive_kernel import CognitiveKernel
        k = CognitiveKernel.__new__(CognitiveKernel)

        class Boom:
            def observe_episode(self, ep):
                raise RuntimeError("boom")
        calls = []
        k._audit = lambda event, detail="": calls.append((event, detail))
        k.self_improvement = Boom()
        CognitiveKernel._distill_episode(k, {"goal": "x", "success": True})
        self.assertEqual(calls[0][0], "self_improve_error")

    def test_attach_sets_kernel_backref(self):
        from infrastructure.cognitive_kernel import CognitiveKernel
        e = make_engine()
        holder = type("K", (), {})()
        CognitiveKernel.attach_self_improvement(holder, e)
        self.assertIs(e.kernel, holder)

    def test_observe_episode_buffers_then_distills_once(self):
        e = make_engine()
        results = []
        for i in range(4):
            out = e.observe_episode({
                "id": f"e{i}",
                "goal": f"deploy docker container {i} to vps",
                "success": True, "steps": []})
            if out is not None:
                results.append(out)
        # Distilled exactly once, on the 3rd episode; 4th is a no-op.
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0].name, "deploy_service_safely")
        self.assertEqual(len(e.procedural.stored), 1)

    def test_failed_episodes_never_buffered(self):
        e = make_engine()
        e.observe_episode({"goal": "deploy x", "success": False})
        self.assertEqual(e._episode_buffer, [])


if __name__ == "__main__":
    unittest.main()
