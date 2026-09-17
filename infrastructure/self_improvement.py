"""Phase 42: Autonomous self-improvement loop (propose-only, flag OFF).

Closes the loop between Maya's outcome signals and her capability set:

    self_model weaknesses  ─┐
    reflection failures     ├─> analyze_gaps() ─> propose() ─> proposals
    skill-coverage check   ─┘                                  │
                                                    execute_proposal(id)
                                                    (EXPLICIT only)
                                                    ├── "skill": distill
                                                    │   episodes -> Skill
                                                    └── "tool" : draft ->
                                                        ToolCreator
                                                        (AST scan + human
                                                         approval gate)

Safety posture:
  - OFF by default (SELF_IMPROVE_ENABLED).
  - propose() NEVER executes anything — it only drafts a proposal.
  - execute_proposal() is explicit-only (API call); no background loop
    ever calls it.
  - Tool proposals keep BOTH existing gates: scan_risk AST scan AND the
    high-risk ApprovalManager gate inside ToolCreator.create_tool.
  - This engine is NOT a controller: it never runs goals, never touches
    the executor. It only grows the capability set (skills/tools) that
    the kernel's single control loop can then use.

Audit trail: every step writes to the engine's own append-only JSONL log
(storage/self_improve/audit.jsonl) in addition to any kernel audit row.
"""

import json
import os
import threading
import time
import uuid
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

STORAGE_DIR = Path(os.getenv("SELF_IMPROVE_DIR",
                             "storage/self_improve"))
PROPOSALS_FILE = STORAGE_DIR / "proposals.json"
AUDIT_FILE = STORAGE_DIR / "audit.jsonl"

# How many successful similar episodes are needed before a skill is
# distilled from them (same threshold as ExperienceDistiller).
MIN_EPISODES_FOR_SKILL = 3


def self_improve_enabled() -> bool:
    return os.getenv("SELF_IMPROVE_ENABLED", "").strip().lower() in (
        "1", "true", "yes")


class SelfImprovementEngine:
    """Gap detection -> proposal drafting -> explicit gated execution."""

    def __init__(
        self,
        self_model: Optional[Any] = None,
        procedural_memory: Optional[Any] = None,
        llm_fn: Optional[Callable] = None,
        tool_creator: Optional[Any] = None,
    ) -> None:
        self.self_model = self_model
        self.procedural = procedural_memory
        self.llm_fn = llm_fn
        self.tool_creator = tool_creator
        # Set by the host after construction (never a controller —
        # used ONLY for audit logging).
        self.kernel = None

        self._lock = threading.Lock()
        # Successful episode dicts buffered from the kernel's distill
        # hook, keyed by normalized goal group.
        self._episode_buffer: List[Dict] = []
        self._distilled_groups: set = set()

        STORAGE_DIR.mkdir(parents=True, exist_ok=True)

    # ── Audit ────────────────────────────────────────────────────────

    def _audit(self, event: str, detail: str) -> None:
        row = {
            "ts": time.time(), "event": event, "detail": str(detail)[:500],
        }
        try:
            with AUDIT_FILE.open("a", encoding="utf-8") as f:
                f.write(json.dumps(row) + "\n")
        except Exception:
            pass
        k = self.kernel
        if k is not None and hasattr(k, "_audit"):
            try:
                k._audit(f"self_improve_{event}", str(detail)[:300])
            except Exception:
                pass

    # ── Gap analysis ────────────────────────────────────────────────

    def _skill_coverage(self, task_type: str) -> List[str]:
        """Names of stored skills that look relevant to this task type."""
        pm = self.procedural
        if pm is None or not hasattr(pm, "search_skills"):
            return []
        try:
            hits = pm.search_skills(task_type.replace("_", " "), limit=3)
        except Exception:
            return []
        return sorted({h.get("name", "") for h in hits if h.get("name")})

    def analyze_gaps(self) -> List[Dict]:
        """Ranked capability gaps from the persistent self-model.

        A gap = a task type with enough failed attempts that Maya should
        either reinforce a weak skill, distill a missing one, or draft a
        new tool. Priority = attempts x failure-rate, +1 when no stored
        skill covers the type at all.
        """
        sm = self.self_model
        if sm is None or not hasattr(sm, "weaknesses"):
            return []
        gaps: List[Dict] = []
        for w in sm.weaknesses():
            tt = w.get("task_type", "")
            attempts = int(w.get("attempts", 0))
            rate = float(w.get("success_rate", 0.0))
            covered = self._skill_coverage(tt)
            priority = round(attempts * (1.0 - rate), 3)
            if not covered:
                priority += 1.0
            gaps.append({
                "task_type": tt,
                "attempts": attempts,
                "success_rate": rate,
                "avg_quality": w.get("avg_quality"),
                "covered_by_skills": covered,
                "priority": priority,
                "suggested_action": (
                    "reinforce_skill" if covered else "create_skill_or_tool"),
            })
        gaps.sort(key=lambda g: -g["priority"])
        return gaps

    # ── Proposals ───────────────────────────────────────────────────

    def _load_proposals(self) -> List[Dict]:
        try:
            return json.loads(PROPOSALS_FILE.read_text(encoding="utf-8"))
        except Exception:
            return []

    def _save_proposals(self, proposals: List[Dict]) -> None:
        tmp = PROPOSALS_FILE.with_suffix(".tmp")
        tmp.write_text(
            json.dumps(proposals, indent=2), encoding="utf-8")
        os.replace(tmp, PROPOSALS_FILE)

    def list_proposals(self, status: str = None) -> List[Dict]:
        props = self._load_proposals()
        if status:
            props = [p for p in props if p.get("status") == status]
        return sorted(props, key=lambda p: -p.get("created_at", 0))

    def get_proposal(self, proposal_id: str) -> Optional[Dict]:
        for p in self._load_proposals():
            if p.get("id") == proposal_id:
                return p
        return None

    def propose(self, gap: Optional[Dict] = None,
                goal_hint: str = "") -> Dict:
        """Draft an improvement proposal. Propose-only: NO side effects.

        For 'tool' proposals an LLM draft of the tool code may be
        generated NOW (analysis is free), but loading it happens only in
        execute_proposal() behind ToolCreator's scan+approval gates.
        """
        if gap is None:
            gaps = self.analyze_gaps()
            if not gaps:
                raise ValueError("no capability gaps detected "
                                 "(need >=2 recorded outcomes)")
            gap = gaps[0]

        task_type = gap.get("task_type", "unknown")
        action = gap.get("suggested_action", "create_skill_or_tool")
        ptype = "tool" if "tool" in action else "skill"
        proposal_id = f"sip_{uuid.uuid4().hex[:10]}"

        draft_code = None
        spec = ""
        if ptype == "tool":
            draft_code, spec = self._draft_tool(task_type, goal_hint)

        proposal = {
            "id": proposal_id,
            "type": ptype,
            "task_type": task_type,
            "status": "proposed",  # proposed | approved | executed | rejected
            "created_at": time.time(),
            "gap": {k: gap.get(k) for k in
                    ("attempts", "success_rate", "priority")},
            "goal_hint": goal_hint[:300],
            "spec": spec,
            "draft_code": draft_code,
        }
        with self._lock:
            props = self._load_proposals()
            props.append(proposal)
            self._save_proposals(props)
        self._audit("proposal_created",
                    f"{proposal_id} type={ptype} task={task_type}")
        return dict(proposal)

    def _draft_tool(self, task_type: str, goal_hint: str):
        """Best-effort LLM draft of a plugin module for the gap.

        Returns (code_or_None, spec_text). Draft generation failures are
        non-fatal — the proposal still records the intent.
        """
        spec = (f"A tool closing capability gap '{task_type}'"
                + (f" observed while pursuing: {goal_hint}" if goal_hint else ""))
        if self.llm_fn is None:
            return None, spec
        prompt = f"""Write a Python plugin module for an AI agent's plugin system.

Capability gap: repeated failures on "{task_type}" tasks{(' — context: ' + goal_hint) if goal_hint else ''}

Requirements:
- Define register_tools(registry) which calls registry.register(name, func, description, category="self_improved") for each tool.
- Tool functions must be pure-Python using ONLY the standard library modules allowed here: json, re, math, datetime, pathlib, collections, itertools, functools, textwrap, statistics.
- NO subprocess, socket, os.system, eval, exec, network calls, or filesystem writes outside the current directory.
- Keep it under 60 lines. Return ONLY the code, no markdown fences."""
        try:
            code = str(self.llm_fn(prompt)).strip()
            if code.startswith("```"):
                code = code.strip("`")
                if code.lower().startswith("python"):
                    code = code[6:]
                code = code.strip()
            return (code if code else None), spec
        except Exception as e:
            self._audit("draft_failed", str(e))
            return None, spec

    def approve_proposal(self, proposal_id: str,
                         approved: bool = True) -> Dict:
        """Owner decision on a proposal (bookkeeping only)."""
        with self._lock:
            props = self._load_proposals()
            for p in props:
                if p["id"] == proposal_id:
                    p["status"] = "approved" if approved else "rejected"
                    p["decided_at"] = time.time()
                    self._save_proposals(props)
                    self._audit("proposal_decided",
                                f"{proposal_id} -> {p['status']}")
                    return dict(p)
        raise ValueError(f"unknown proposal: {proposal_id}")

    def execute_proposal(self, proposal_id: str) -> Dict:
        """Execute an APPROVED proposal. Explicit-only; never called by
        any background loop. Returns a result dict; never raises."""
        prop = self.get_proposal(proposal_id)
        if prop is None:
            return {"success": False, "error": f"unknown proposal {proposal_id}"}
        if prop.get("status") != "approved":
            return {
                "success": False,
                "error": (f"proposal {proposal_id} is "
                          f"'{prop.get('status')}', not 'approved' — "
                          f"human approval required first"),
            }
        try:
            if prop["type"] == "skill":
                result = self._execute_skill(prop)
            else:
                result = self._execute_tool(prop)
        except Exception as e:
            result = {"success": False, "error": str(e)}
        with self._lock:
            props = self._load_proposals()
            for p in props:
                if p["id"] == proposal_id:
                    p["status"] = ("executed" if result.get("success")
                                   else "failed")
                    p["executed_at"] = time.time()
                    p["execution_result"] = {
                        k: v for k, v in result.items()
                        if k not in ("skill",)}
                    self._save_proposals(props)
        self._audit("proposal_executed",
                    f"{proposal_id} success={result.get('success')}")
        return result

    # ── Execution paths ─────────────────────────────────────────────

    def _execute_skill(self, prop: Dict) -> Dict:
        """Distill buffered episodes for this task type into a Skill."""
        tt = prop.get("task_type", "")
        eps = self._episodes_for_task(tt)
        if len(eps) < MIN_EPISODES_FOR_SKILL:
            return {
                "success": False,
                "error": (f"only {len(eps)} relevant episode(s) buffered; "
                          f"need >= {MIN_EPISODES_FOR_SKILL}"),
            }
        skill = self._build_skill(tt, eps)
        if skill is None:
            return {"success": False, "error": "skill distillation failed"}
        self.procedural.store_skill(skill)
        import dataclasses
        return {"success": True,
                "skill": dataclasses.asdict(skill)}

    def _episodes_for_task(self, task_type: str) -> List[Dict]:
        """Buffered episodes plausibly related to a task type.

        Prefix-tolerant token match ('deployment' matches 'deploy') so a
        self-model task label can find its episodes without exact wording.
        """
        tt_toks = [t for t in task_type.lower().split("_") if len(t) > 3]
        matched = []
        for e in self._episode_buffer:
            gtoks = set(self._group_key(e.get("goal", "")).split("_"))
            if any(
                any(g.startswith(t[:4]) or t.startswith(g[:4])
                    for g in gtoks if g)
                for t in tt_toks
            ):
                matched.append(e)
        return matched

    def _execute_tool(self, prop: Dict) -> Dict:
        """Load a drafted tool through ToolCreator (AST scan + approval)."""
        tc = self.tool_creator
        if tc is None:
            return {"success": False, "error": "no tool_creator attached"}
        code = prop.get("draft_code")
        if not code:
            return {"success": False,
                    "error": "no draft code available for this proposal"}
        name = f"auto_{prop.get('task_type', 'tool')}"
        msg = tc.create_tool(name=name, code=code,
                             reason=f"Phase 42 self-improvement: close "
                                    f"gap '{prop.get('task_type')}'")
        return {"success": True, "message": msg,
                "note": "ToolCreator enforced AST scan + approval gate"}

    # ── Episode hook (kernel _distill_episode) ──────────────────────

    @staticmethod
    def _group_key(goal: str) -> str:
        stop = {"the", "a", "an", "to", "for", "and", "of", "in", "on"}
        words = [w.strip(".,!?;:'\"") .lower()
                 for w in str(goal).split()]
        # Drop pure numbers so 'deploy container 1/2/3' groups together.
        key_words = [w for w in words
                     if w and w not in stop and not w.isdigit()][:4]
        return "_".join(key_words) or "general"

    def observe_episode(self, ep_dict: Dict) -> Optional[Dict]:
        """Called by the kernel after every successful goal execution.

        Buffers the episode; once MIN_EPISODES_FOR_SKILL similar
        successes accumulate without an existing covering skill, a new
        Skill is distilled and stored. Knowledge-level only — no tools
        are created here, no goals executed.
        """
        goal = str(ep_dict.get("goal") or ep_dict.get("description") or "")
        if not goal or not ep_dict.get("success", True):
            return None
        group = self._group_key(goal)
        entry = dict(ep_dict)
        entry["_group"] = group
        with self._lock:
            self._episode_buffer.append(entry)
            self._episode_buffer = self._episode_buffer[-100:]
            eps = [e for e in self._episode_buffer
                   if e["_group"] == group]
        if len(eps) < MIN_EPISODES_FOR_SKILL or group in self._distilled_groups:
            return None
        if self._skill_coverage(group.replace("_", " ")):
            self._distilled_groups.add(group)
            return None
        skill = self._build_skill(group, eps)
        if skill is None:
            return None
        self.procedural.store_skill(skill)
        self._distilled_groups.add(group)
        self._audit("skill_distilled", f"group={group} skill={skill.name}")
        return skill

    def _build_skill(self, topic: str, episodes: List[Dict]):
        """LLM-distill similar successful episodes into a Skill object."""
        pm = self.procedural
        if pm is None or self.llm_fn is None:
            return None
        summaries = [{
            "goal": e.get("goal", ""),
            "steps": [
                {"action": s.get("action", s.get("step", "")),
                 "tool": s.get("tool", s.get("required_capability", "")),
                 "success": s.get("success", True)}
                for s in (e.get("steps") or [])
            ],
        } for e in episodes]
        prompt = f"""Analyze these {len(summaries)} similar successful episodes and extract ONE reusable skill.

Episodes: {json.dumps(summaries, indent=1)}

Return ONLY JSON:
{{"name": "snake_case_name", "description": "...",
  "preconditions": ["..."],
  "procedure": [{{"step": 1, "action": "...", "tool": "..."}}],
  "confidence": 0.7}}"""
        try:
            raw = str(self.llm_fn(prompt)).strip()
            if "{" in raw and "}" in raw:
                raw = raw[raw.index("{"):raw.rindex("}") + 1]
            data = json.loads(raw)
        except Exception as e:
            self._audit("distill_llm_error", str(e))
            return None
        try:
            from infrastructure.procedural_memory import Skill
            sid = f"skill_{uuid.uuid4().hex[:10]}"
            return Skill(
                id=sid,
                name=str(data.get("name", f"skill_{topic}"))[:64],
                description=str(data.get("description", ""))[:500],
                preconditions=data.get("preconditions", []),
                procedure=data.get("procedure", []),
                confidence=max(0.05, min(0.95,
                              float(data.get("confidence", 0.6)))),
                source_episodes=[e.get("id", f"ep-{i}")
                                 for i, e in enumerate(episodes)],
            )
        except Exception as e:
            self._audit("distill_build_error", str(e))
            return None

    # ── Status ──────────────────────────────────────────────────────

    def stats(self) -> Dict:
        props = self._load_proposals()
        return {
            "enabled": self_improve_enabled(),
            "gaps_detected": len(self.analyze_gaps()),
            "proposals_total": len(props),
            "proposals_pending": sum(
                1 for p in props if p.get("status") == "proposed"),
            "proposals_executed": sum(
                1 for p in props if p.get("status") == "executed"),
            "episodes_buffered": len(self._episode_buffer),
            "skills_distilled_live": len(self._distilled_groups),
        }


_engine: Optional[SelfImprovementEngine] = None


def get_self_improvement_engine(**kwargs) -> SelfImprovementEngine:
    global _engine
    if _engine is None:
        _engine = SelfImprovementEngine(**kwargs)
    return _engine
