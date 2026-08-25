"""LIVE production validation — real NVIDIA NIM inference through Maya.

Everything is real: LLM planning/verification, tools, SQLite persistence,
kernel unified loop, streaming, outage/fallback/resume.

Usage: python validate_live.py
"""
import json
import os
import sys
import time

os.environ["MAYA_UNIFIED_LOOP"] = "true"
from dotenv import load_dotenv
load_dotenv(".env")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from llm.router import LLMRouter  # noqa: E402

# Pre-flight: confirm real inference works at all
_router = LLMRouter()
_providers = _router.available_providers()
print(f"Live providers: {_providers}")
if not _providers:
    print("NO PROVIDER AVAILABLE — cannot run live validation")
    sys.exit(2)

PASS, FAIL = [], []


def check(name, cond, detail=""):
    (PASS if cond else FAIL).append(name)
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}"
          + (f" -- {detail[:150]}" if detail and not cond else ""))


def t():
    return time.strftime("%H:%M:%S")


# ── Boot full Maya with the REAL router ──────────────────────────────────
print(f"\n=== [{t()}] BOOT: Maya with real NIM inference ===")
from core.maya import Maya  # noqa: E402

maya = Maya()
router = maya.router
kernel = maya.cognitive_kernel
check("L0 real provider active", len(router.available_providers()) >= 1)
check("L0 kernel has sole executor", kernel.has_executor)
check("L0 unified loop enabled", kernel.unified_loop_enabled)

REAL_KEY_OK = True


class LiveEmitter:
    """Matches the real streaming contract: every method returns a
    coroutine (the engine drives them via asyncio.run)."""

    def __init__(self):
        self.events = []

    def __getattr__(self, name):
        def _m(*a, **k):
            self.events.append(name)

            async def _coro():
                pass
            return _coro()
        return _m


def run_goal(goal, task_id):
    em = LiveEmitter()
    r = maya.run(goal, task_id=task_id, stream_emitter=em)
    return r, em


# ── L1: real multi-step goal ─────────────────────────────────────────────
os.makedirs("workspace/maya_e2e", exist_ok=True)
try:
    os.remove("workspace/maya_e2e/live_result.txt")
except OSError:
    pass

GOAL1 = ("Use the run_code tool to compute the sum of squares of integers "
         "from 1 to 10, print it, and also write just that number to the "
         "file maya_e2e/live_result.txt (relative path). One self-contained "
         "run_code step.")
print(f"\n=== [{t()}] L1: real multi-step goal ===")
r1, em1 = None, None
_BACKOFF = [60, 120, 240]   # conservative exponential backoff
for _attempt in range(3):
    r1, em1 = run_goal(GOAL1, f"live-1-{_attempt}")
    if r1.get("success"):
        break
    wait = _BACKOFF[min(_attempt, len(_BACKOFF) - 1)]
    print(f"      [{t()}] L1 attempt {_attempt+1} hit provider "
          f"throttling, backing off {wait}s...")
    time.sleep(wait)
check("L1 goal succeeded", r1.get("success") is True, str(r1)[:200])
check("L1 executed under unified loop", r1.get("unified_loop") is True)
g1 = kernel.get_goal(r1.get("goal_id", ""))
check("L1 kernel goal completed",
      g1 is not None and g1.status.value == "completed")
side_effect = False
try:
    side_effect = open("workspace/maya_e2e/live_result.txt").read().strip() == "385"
except OSError:
    pass
check("L1 real side effect correct (385)", side_effect)
check("L1 streaming events fired", len(em1.events) >= 3,
      f"{len(em1.events)} events: {em1.events[:8]}")

# ── L2: learning traces from the real run ────────────────────────────────
print(f"\n=== [{t()}] L2: learning & memory ===")
beliefs = [b.proposition for b in kernel.beliefs.values()]
check("L2 belief recorded for real goal",
      any("sum of squares" in p.lower() or "live_result" in p.lower()
          for p in beliefs), str(beliefs[-3:])[:150])
sm = maya.self_model.profile()
check("L2 self-model updated", sm["total_outcomes"] >= 1,
      f"total={sm['total_outcomes']}")
audits = [a["event_type"] for a in kernel.get_recent_audit(500)]
check("L2 audit trail written",
      "unified_goal_start" in audits and "unified_goal_done" in audits)
cost_summary = maya.cost.get_summary()
check("L2 cost tracker captured real usage",
      cost_summary.get("total_calls", 0) >= 1 or
      cost_summary.get("calls", 0) >= 1 or
      sum(s.get("calls", 0) for s in cost_summary.get("by_provider", {}).values()) >= 1,
      str(cost_summary)[:150])
mem_ok = False
try:
    mem_ok = bool(maya.memory.get_relevant_memories("sum of squares"))
except Exception:
    pass
check("L2 episodic/semantic memory stored", mem_ok)

# ── L3: model failure -> state intact -> fallback restored -> resume ======
print(f"\n=== [{t()}] L3: model failure / switch / resume ===")
before_goals = len(kernel.goals)
real_key_env = os.getenv("NVIDIA_NIM_KEY", "")
assert real_key_env, "key missing from env"

# break the key (simulates dead credentials) WITHOUT touching state
router.set_key("nvidia_nim", "nvapi-invalid-key-outage-test")
r3, _ = run_goal("compute 2+2 with run_code and print it", "live-3")
check("L3 outage handled gracefully", r3.get("success") is False,
      str(r3)[:120])
check("L3 no state lost", len(kernel.goals) == before_goals + 1)
blocked_id = r3.get("goal_id")
check("L3 goal marked blocked",
      blocked_id and kernel.get_goal(blocked_id).status.value == "blocked")

# restore the real key and resume (retry-tolerant like a real operator:
# providers throw intermittent 429s/timeouts under load)
router.set_key("nvidia_nim", real_key_env)
r4, last_err = None, ""
_BACKOFF4 = [60, 120, 180]
for attempt in range(3):
    r4 = kernel.resume_goal(blocked_id, execute=True)
    if r4.get("success"):
        break
    last_err = str(r4.get("outcome", {}).get("result", ""))[:120]
    wait = _BACKOFF4[min(attempt, len(_BACKOFF4) - 1)]
    print(f"      [{t()}] resume attempt {attempt+1} failed ({last_err}), "
          f"backing off {wait}s...")
    time.sleep(wait)
check("L4 resume succeeds after recovery",
      r4 is not None and r4.get("success") is True,
      f"{str(r4)[:100]} last={last_err}")
check("L4 blocked goal now completed",
      kernel.get_goal(blocked_id).status.value == "completed")

# ── L5: propose-only autonomy with real model ────────────────────────────
print(f"\n=== [{t()}] L5: propose-only autonomy ===")
pr = kernel.process_goal(
    "design a small weather dashboard website", execute=False)
check("L5 proposal created, nothing executed",
      pr.get("executed") is False and pr.get("plan_id"))
g = kernel.get_goal(pr["goal_id"])
check("L5 proposed goal suspended", g.status.value == "suspended")

# ── L6: autonomous skill acquisition with REAL model + vector retrieval ──
print(f"\n=== [{t()}] L6: skill distillation (real llm_fn) ===")
from infrastructure.procedural_memory import (  # noqa: E402
    Episode, get_episodic_memory,
)
_ep_mem = get_episodic_memory()
for i in range(3):
    _ep_mem.add_episode(Episode(
        id=f"live-ep-{i}",
        goal=f"deploy docker container number {i} to the production vps",
        steps=[
            {"step": 1, "action": "scp project to server", "success": True},
            {"step": 2, "action": "docker build image on server", "success": True},
            {"step": 3, "action": "docker run container", "success": True},
        ],
        outcome="success", success=True, reward=0.9, duration=120.0,
    ))
skills_before = len(maya.procedural_memory._skills)
distilled = maya.experience_distiller.distill_from_goal(
    "deploy docker container to the production vps")
check("L6 real-model distillation produced a skill",
      len(maya.procedural_memory._skills) > skills_before or bool(distilled),
      str(distilled)[:150])
# Phase 40: vector retrieval must surface it for NOVEL phrasing
hits = maya.procedural_memory.search_skills(
    "ship my containerized app to my remote linux machine")
check("L6 semantic skill retrieval for novel phrasing",
      any(h["name"] == distilled[0].name for h in hits) if distilled else hits,
      str(hits[:2])[:150])

# ── L7: MCP host capability through Maya's own registry ─────────────────
print(f"\n=== [{t()}] L7: MCP tools as capabilities ===")
import tempfile as _tf  # noqa: E402
from infrastructure.mcp_client import MCPManager  # noqa: E402

_ECHO = r'''
import json, sys
while True:
    line = sys.stdin.readline()
    if not line:
        break
    line = line.strip()
    if not line:
        continue
    try:
        msg = json.loads(line)
    except json.JSONDecodeError:
        continue
    rid = msg.get("id")
    method = msg.get("method", "")
    if rid is None:
        continue
    if method == "initialize":
        result = {"protocolVersion": "2024-11-05",
                  "capabilities": {"tools": {}},
                  "serverInfo": {"name": "liveecho", "version": "0.1"}}
    elif method == "tools/list":
        result = {"tools": [
            {"name": "echo", "description": "Echo input text",
             "inputSchema": {"type": "object",
                             "properties": {"text": {"type": "string"}}}}]}
    elif method == "tools/call":
        args = msg.get("params", {}).get("arguments", {})
        result = {"content": [{"type": "text",
                               "text": f"echo: {args.get('text', '')}"}]}
    else:
        result = {}
    print(json.dumps({"jsonrpc": "2.0", "id": rid, "result": result}),
          flush=True)
'''
_d = _tf.mkdtemp(prefix="live_mcp_")
_srv = os.path.join(_d, "echo_mcp_server.py")
with open(_srv, "w") as f:
    f.write(_ECHO)
_mcp_mgr = MCPManager()
_reg = maya.tool_manager.get_registry()
_n = _mcp_mgr.connect_server(
    {"name": "live.echo", "command": [sys.executable, _srv]},
    registry=_reg)
check("L7 MCP server connected, tools registered", _n == 1, f"n={_n}")
_tool_name = "mcp_live_echo_echo"
check("L7 MCP tool registered under mcp_ prefix in Maya registry",
      _reg.has(_tool_name))
_out = _reg.run(_tool_name, {"text": "through maya registry"})
check("L7 MCP tool executes through Maya's registry",
      _out == "echo: through maya registry", str(_out)[:100])
_mcp_mgr.disconnect_all()

# ── L8: persistent self-model + semantic knowledge ───────────────────────
print(f"\n=== [{t()}] L8: self-model & knowledge engine ===")
sm_profile = maya.self_model.profile()
check("L8 self-model has real outcome history",
      sm_profile.get("total_outcomes") >= 2,
      str(sm_profile)[:150])
assessment = maya.self_model.assess(
    "deploy another docker container to the vps")
check("L8 self-model assess() returns grounded recommendation",
      isinstance(assessment, dict) and assessment.get("task_type"),
      str(assessment)[:150])
line = maya.self_model.summary_line("write some flask code")
check("L8 planner-hint summary line generated", bool(line), str(line)[:100])
kernel.learn("the live validation vps ssh port is 20045", confidence=0.9,
             domain="server")
kq = kernel.knowledge_query("which port reaches the live vps")
check("L8 semantic knowledge query ranks learned fact",
      kq and "20045" in kq[0]["proposition"], str(kq[:1])[:150])

# ── Summary ───────────────────────────────────────────────────────────────
print(f"\n{'='*58}")
print(f"LIVE VALIDATION: {len(PASS)} passed, {len(FAIL)} failed")
if FAIL:
    print("FAILED:", FAIL)
    sys.exit(1)
print("ALL LIVE VALIDATIONS PASSED")
