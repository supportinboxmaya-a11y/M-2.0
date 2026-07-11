"""Phase 26 tests — declarative workflow builder.
Offline, real SQLite temp dir, real asyncio, fake prompt/tool fns."""
import asyncio, os, shutil, sys, tempfile, types
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

for _name in ("loguru", "dotenv"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            _m = types.ModuleType(_name)
            if _name == "loguru":
                class _L:
                    def __getattr__(self, k):
                        return lambda *a, **kw: self
                _m.logger = _L()
            if _name == "dotenv":
                _m.load_dotenv = lambda *a, **kw: None
            sys.modules[_name] = _m

from workflows.builder import WorkflowBuilder, WorkflowValidationError

_tmp = tempfile.mkdtemp(prefix="maya_wf26_")


def _builder(tag, prompt_fn=None, tool_fn=None):
    return WorkflowBuilder(db_path=os.path.join(_tmp, f"w_{tag}.db"),
                           prompt_fn=prompt_fn, tool_fn=tool_fn)


# ── validation ────────────────────────────────────────────────────
def test_validation_rules():
    vs = WorkflowBuilder.validate_steps
    try:
        vs([]); assert False
    except WorkflowValidationError: pass
    # duplicate ids
    try:
        vs([{"id": "a", "action": "prompt"}, {"id": "a", "action": "prompt"}])
        assert False
    except WorkflowValidationError: pass
    # unknown action
    try:
        vs([{"id": "a", "action": "magic"}]); assert False
    except WorkflowValidationError: pass
    # tool without name
    try:
        vs([{"id": "a", "action": "tool"}]); assert False
    except WorkflowValidationError: pass
    # dep on unknown
    try:
        vs([{"id": "a", "action": "prompt", "depends_on": ["z"]}]); assert False
    except WorkflowValidationError: pass
    # bad condition op
    try:
        vs([{"id": "a", "action": "prompt",
             "condition": {"when": "{{x}}", "op": "weird", "value": "1"}}])
        assert False
    except WorkflowValidationError: pass
    # valid passes
    vs([{"id": "a", "action": "prompt", "input": "hi"}])
    print("PASS validation rules")


def test_cycle_detection():
    try:
        WorkflowBuilder.validate_steps([
            {"id": "a", "action": "prompt", "depends_on": ["b"]},
            {"id": "b", "action": "prompt", "depends_on": ["a"]}])
        assert False
    except WorkflowValidationError as e:
        assert "cycle" in str(e)
    print("PASS cycle detection")


# ── CRUD ──────────────────────────────────────────────────────────
def test_crud():
    b = _builder("crud")
    wf = b.create("My Flow", [{"id": "s1", "action": "prompt", "input": "hello"}],
                  description="test")
    assert wf["name"] == "My Flow" and wf["runs"] == 0
    assert b.get(wf["id"])["steps"][0]["id"] == "s1"
    up = b.update(wf["id"], name="Renamed")
    assert up["name"] == "Renamed"
    assert len(b.list()) == 1
    assert b.delete(wf["id"]) is True and b.get(wf["id"]) is None
    print("PASS CRUD")


# ── execution ─────────────────────────────────────────────────────
def test_linear_run_with_templating():
    calls = []
    def prompt_fn(text):
        calls.append(text)
        return f"answer:{text}"
    b = _builder("linear", prompt_fn=prompt_fn)
    wf = b.create("Chain", [
        {"id": "first", "action": "prompt", "input": "start {{input.topic}}"},
        {"id": "second", "action": "prompt", "input": "use {{first.output}}",
         "depends_on": ["first"]},
    ])
    res = asyncio.run(b.run(wf["id"], inputs={"topic": "AI"}))
    assert res["status"] == "completed"
    assert res["outputs"]["first"] == "answer:start AI"
    # second step saw first's output via templating
    assert "answer:start AI" in res["outputs"]["second"]
    assert b.get(wf["id"])["runs"] == 1
    print("PASS linear run + templating")


def test_condition_skips_step():
    def prompt_fn(text):
        return "no" if "check" in text else "ran"
    b = _builder("cond", prompt_fn=prompt_fn)
    wf = b.create("Branch", [
        {"id": "check", "action": "prompt", "input": "check something"},
        {"id": "gated", "action": "prompt", "input": "do it",
         "depends_on": ["check"],
         "condition": {"when": "{{check.output}}", "op": "equals", "value": "yes"}},
    ])
    res = asyncio.run(b.run(wf["id"]))
    assert "gated" in res["skipped"]           # condition false -> skipped
    assert "gated" not in res["outputs"]
    print("PASS condition skips step")


def test_condition_runs_when_true():
    def prompt_fn(text):
        return "yes" if "check" in text else "executed"
    b = _builder("cond2", prompt_fn=prompt_fn)
    wf = b.create("Branch2", [
        {"id": "check", "action": "prompt", "input": "check"},
        {"id": "gated", "action": "prompt", "input": "go",
         "depends_on": ["check"],
         "condition": {"when": "{{check.output}}", "op": "contains", "value": "yes"}},
    ])
    res = asyncio.run(b.run(wf["id"]))
    assert "gated" not in res["skipped"]
    assert res["outputs"]["gated"] == "executed"
    print("PASS condition runs when true")


def test_parallel_independent_steps():
    order = []
    async def prompt_fn(text):
        await asyncio.sleep(0.01)
        order.append(text)
        return text
    b = _builder("par", prompt_fn=prompt_fn)
    wf = b.create("Fan", [
        {"id": "a", "action": "prompt", "input": "A"},
        {"id": "b", "action": "prompt", "input": "B"},
        {"id": "join", "action": "prompt", "input": "{{a.output}}+{{b.output}}",
         "depends_on": ["a", "b"]},
    ])
    res = asyncio.run(b.run(wf["id"]))
    assert res["outputs"]["join"] == "A+B"
    assert set(order[:2]) == {"A", "B"}      # a,b ran before join
    print("PASS parallel independent steps then join")


def test_tool_action_and_failure_skips_dependents():
    def tool_fn(name, inp):
        raise RuntimeError("tool boom")
    b = _builder("tool", tool_fn=tool_fn)
    wf = b.create("ToolFlow", [
        {"id": "t", "action": "tool", "tool": "search", "input": "q"},
        {"id": "after", "action": "prompt", "input": "use {{t.output}}",
         "depends_on": ["t"]},
    ])
    b.prompt_fn = lambda text: "should not run"
    res = asyncio.run(b.run(wf["id"]))
    assert res["status"] == "failed"
    assert "after" in res["skipped"]         # dependent skipped after failure
    print("PASS tool failure skips dependents")


def test_persistence_across_instances():
    db = os.path.join(_tmp, "persist.db")
    b1 = WorkflowBuilder(db_path=db)
    wf = b1.create("Keep", [{"id": "s", "action": "prompt", "input": "x"}])
    b2 = WorkflowBuilder(db_path=db)
    assert b2.get(wf["id"])["name"] == "Keep"
    print("PASS workflows persist across instances")


try:
    test_validation_rules()
    test_cycle_detection()
    test_crud()
    test_linear_run_with_templating()
    test_condition_skips_step()
    test_condition_runs_when_true()
    test_parallel_independent_steps()
    test_tool_action_and_failure_skips_dependents()
    test_persistence_across_instances()
    print("\nAll workflow-builder tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
