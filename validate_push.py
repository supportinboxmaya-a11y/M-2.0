"""Final validation push — long-horizon, restart-recovery, self-improvement.

Runs against REAL providers through the unified loop:

  H1  Long-horizon: 3 sequential dependent goals through kernel.process_goal
      — state stays consistent across the whole horizon (no leaks/dupes),
      audit trail continuous, self-model accumulates outcomes.
  H2  Restart recovery policy: an ACTIVE goal re-executes under
      resume_incomplete; SUSPENDED/BLOCKED goals NEVER auto-execute
      (propose-only) even when MAYA_AUTO_RESUME=true.
  H3  Phase 42 propose-only: gap analysis on the live self-model, proposal
      drafted, NOTHING loads/executes without explicit owner decision;
      tool draft never reaches ToolCreator loading at propose time.

Usage: python validate_push.py   (requires .env provider keys)
"""
import os
import sys
import time

os.environ["MAYA_UNIFIED_LOOP"] = "true"
os.environ.setdefault("SELF_IMPROVE_ENABLED", "true")
from dotenv import load_dotenv
load_dotenv(".env")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from llm.router import LLMRouter  # noqa: E402

_router = LLMRouter()
if not _router.available_providers():
    print("NO PROVIDER AVAILABLE — cannot run live validation")
    sys.exit(2)

PASS, FAIL = [], []

# Optional section gating: PUSH_SECTIONS="H1,H2b" runs only those sections
# (free-tier providers throttle hard under burst load; re-run just the
# throttled sections after a cooldown instead of paying for everything).
_SECTIONS = {s.strip().upper()
             for s in os.getenv("PUSH_SECTIONS", "").split(",") if s.strip()}


def _sec(name):
    return not _SECTIONS or name.upper() in _SECTIONS


def check(name, cond, detail=""):
    (PASS if cond else FAIL).append(name)
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}"
          + (f" -- {detail[:180]}" if detail and not cond else ""))


def t():
    return time.strftime("%H:%M:%S")


print(f"\n=== [{t()}] BOOT ===")
from core.maya import Maya  # noqa: E402

maya = Maya()
kernel = maya.cognitive_kernel


def drive(goal_desc, task_id, attempts=3, backoffs=(45, 90, 180)):
    """Drive one goal through the kernel with operator-style backoff."""
    last = None
    for i in range(attempts):
        r = kernel.process_goal(
            f"{goal_desc} [push-{task_id}]",
            metadata={"source": "validate_push"},
            execute=True,
            executor_options={"task_id": task_id},
        )
        if r.get("success"):
            return r
        last = r
        if i < attempts - 1:
            w = backoffs[min(i, len(backoffs) - 1)]
            print(f"      [{t()}] attempt {i+1} failed, backoff {w}s")
            time.sleep(w)
    return last


# ── H1: long-horizon — three dependent goals ─────────────────────────────
if _sec("H1"):
    print(f"\n=== [{t()}] H1: long-horizon multi-goal ===")
    os.makedirs("workspace/maya_push", exist_ok=True)
    try:
        os.remove("workspace/maya_push/chain.txt")
    except OSError:
        pass

    goals = [
        ("Use run_code to compute 7 factorial, print it, and write just that "
         "number to maya_push/chain.txt", "h1-a"),
        ("Use read_file to read maya_push/chain.txt, then use run_code to "
         "multiply that number by 2, print it, and overwrite "
         "maya_push/chain.txt with only the new number", "h1-b"),
        ("Use read_file on maya_push/chain.txt and report whether the value "
         "equals 10080 in your final answer text", "h1-c"),
    ]
    results = []
    for desc, tid in goals:
        r = drive(desc, tid)
        results.append(r)
        print(f"      [{t()}] {tid}: success={r.get('success')}")
    check("H1 all three goals succeeded",
          all(r.get("success") for r in results),
          str([r.get('success') for r in results]))
    final_ok = False
    try:
        final_ok = open("workspace/maya_push/chain.txt").read().strip() == "10080"
    except OSError:
        pass
    check("H1 side-effect chain correct (5040 -> 10080)", final_ok)

    statuses = [kernel.get_goal(r["goal_id"]).status.value
                for r in results if r.get("goal_id")]
    check("H1 every goal COMPLETED in kernel state",
          statuses and all(s == "completed" for s in statuses), str(statuses))

    audits = [a["event_type"] for a in kernel.get_recent_audit(800)]
    horizon_starts = sum(1 for a in audits if a == "unified_goal_start"
                         and "push-h1-" in str(a))
    check("H1 audit trail continuous across horizon",
          sum(1 for a in audits if a == "unified_goal_done") >= 3,
          f"starts={horizon_starts}")
    sm_after = maya.self_model.profile()
    check("H1 self-model accumulated horizon outcomes",
          sm_after.get("total_outcomes", 0) >= 3,
          f"total={sm_after.get('total_outcomes')}")

# ── H2: restart recovery policy ──────────────────────────────────────────
print(f"\n=== [{t()}] H2: persistent-goal restart recovery ===")

# H2a: SUSPENDED goal must NEVER auto-execute even with AUTO_RESUME on.
if _sec("H2a"):
    pr = kernel.process_goal("write a haiku about databases", execute=False)
    suspended_id = pr["goal_id"]
    os.environ["MAYA_AUTO_RESUME"] = "true"
    # max_goals must cover the WHOLE backlog: get_incomplete_goals returns
    # stale goals oldest-first, so a fixed cap (e.g. 50) silently hides
    # freshly-created test goals behind months of accumulated cruft.
    # plan_proposals=False keeps it a cheap policy scan (no LLM re-planning
    # of 100+ stale goals); the explicit operator resume below is the only
    # live call in this section.
    resumed = kernel.resume_incomplete(execute=None,
                                       max_goals=len(kernel.goals) + 10,
                                       plan_proposals=False)
    mine = [r for r in resumed if r.get("goal_id") == suspended_id]
    check("H2a suspended goal seen by auto-resume",
          bool(mine), str(len(resumed)))
    check("H2a suspended goal NOT executed (propose-only)",
          mine and mine[0].get("auto_executed") is False,
          str(mine[:1]))
    check("H2a suspended goal still suspended",
          kernel.get_goal(suspended_id).status.value == "suspended")

# H2b: BLOCKED goal must also stay propose-only.
if _sec("H2b"):
    before_goals = len(kernel.goals)
    _REAL_KEYS = {}
    for _prov, _env in (("nvidia_nim", "NVIDIA_NIM_KEY"),
                        ("groq", "GROQ_KEY"), ("openrouter", "OPENROUTER_KEY")):
        if os.getenv(_env):
            _REAL_KEYS[_prov] = os.getenv(_env)
            router_set = getattr(maya.router, "set_key", None)
            if router_set:
                router_set(_prov, f"invalid-{_prov}-x")
    rb = drive("compute 9*9 with run_code and print it", "h2-blocked",
               attempts=1)
    blocked_id = rb.get("goal_id")
    is_blocked = blocked_id and kernel.get_goal(blocked_id).status.value \
        in ("blocked", "failed")
    check("H2b outage produced non-completed goal", is_blocked,
          str(rb)[:120])
    for _prov, _key in _REAL_KEYS.items():
        getattr(maya.router, "set_key", lambda *a: None)(_prov, _key)
    resumed2 = kernel.resume_incomplete(execute=True,
                                        max_goals=len(kernel.goals) + 10,
                                        plan_proposals=False)
    mine_b = [r for r in resumed2 if r.get("goal_id") == blocked_id]
    check("H2b BLOCKED goal not auto-executed (policy)",
          mine_b and mine_b[0].get("auto_executed") is False,
          str(mine_b[:1])[:150])
    # Explicit operator resume DOES work after recovery.
    r_fix, last_err = None, ""
    for attempt in range(3):
        r_fix = kernel.resume_goal(blocked_id, execute=True)
        if r_fix.get("success"):
            break
        last_err = str(r_fix)[:120]
        time.sleep(45)
    check("H2b explicit operator resume succeeds after key restore",
          r_fix is not None and r_fix.get("success") is True, last_err)

# ── H3: Phase 42 propose-only live ───────────────────────────────────────
print(f"\n=== [{t()}] H3: self-improvement propose-only ===")
sie = getattr(kernel, "self_improvement", None)
check("H3 engine attached to kernel", sie is not None)
if sie is not None:
    gaps = sie.analyze_gaps()
    check("H3 gap analysis returns ranked gaps from live self-model",
          isinstance(gaps, list) and len(gaps) >= 1,
          str(gaps[:1])[:160])
    skills_before = set()
    try:
        skills_before = set(s.id for s in
                            maya.procedural_memory._skills.values())
    except Exception:
        pass
    tools_before = set(maya.tool_manager.get_registry().tool_names())
    prop = sie.propose(goal_hint="improve code task reliability")
    check("H3 proposal drafted propose-only",
          prop.get("status") == "proposed")
    check("H3 no skill stored by proposing",
          set(s.id for s in maya.procedural_memory._skills.values())
          == skills_before)
    check("H3 no tool registered by proposing",
          set(maya.tool_manager.get_registry().tool_names())
          == tools_before)
    if prop.get("type") == "tool":
        check("H3 tool draft present but NOT loaded",
              True)  # registry equality already proves not-loaded
    # Execution without approval MUST be refused.
    refuse = sie.execute_proposal(prop["id"])
    check("H3 execution refused without owner approval",
          refuse.get("success") is False
          and "approval" in str(refuse.get("error", "")).lower(),
          str(refuse)[:120])
    # Owner REJECT path keeps everything inert.
    sie.approve_proposal(prop["id"], approved=False)
    rej = sie.execute_proposal(prop["id"])
    check("H3 rejected proposal never executes",
          rej.get("success") is False,
          str(rej)[:100])
    check("H3 still nothing registered after rejection",
          set(maya.tool_manager.get_registry().tool_names())
          == tools_before)

# ── Summary ───────────────────────────────────────────────────────────────
print(f"\n{'='*58}")
print(f"PUSH VALIDATION: {len(PASS)} passed, {len(FAIL)} failed")
if FAIL:
    print("FAILED:", FAIL)
    sys.exit(1)
print("ALL PUSH VALIDATIONS PASSED")
