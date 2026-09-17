"""Phase 5 tool framework tests — offline."""
import os, sys, time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from tools.framework import ToolFramework, ToolPolicy, ManagedTool, CATEGORY_MAP


def test_permission():
    t = ManagedTool("w", lambda i: "data", ToolPolicy(category="web"), logger=lambda m: None)
    denied = t.execute({}, caller_permissions=("code",))
    assert not denied["ok"] and "permission" in denied["error"]
    ok = t.execute({}, caller_permissions=("web",))
    assert ok["ok"] and ok["output"] == "data"
    star = t.execute({}, caller_permissions=("*",))
    assert star["ok"]
    print("PASS permission")


def test_dangerous_needs_approval():
    t = ManagedTool("sh", lambda i: "ran", ToolPolicy(category="shell", dangerous=True),
                    logger=lambda m: None)
    r = t.execute({}, caller_permissions=("shell",))
    assert not r["ok"] and "approved" in r["error"]
    r = t.execute({}, caller_permissions=("shell",), approved=True)
    assert r["ok"]
    print("PASS dangerous")


def test_validation():
    def validate(inputs):
        if "query" not in inputs:
            return "query is required"
    t = ManagedTool("s", lambda i: i["query"], ToolPolicy(category="web", validate_fn=validate),
                    logger=lambda m: None)
    bad = t.execute({}, caller_permissions=("web",))
    assert not bad["ok"] and "validation" in bad["error"]
    good = t.execute({"query": "x"}, caller_permissions=("web",))
    assert good["ok"] and good["output"] == "x"
    def crashy(inputs): raise RuntimeError("oops")
    t2 = ManagedTool("c", lambda i: "x", ToolPolicy(category="web", validate_fn=crashy),
                     logger=lambda m: None)
    assert "validator crashed" in t2.execute({}, ("web",))["error"]
    print("PASS validation")


def test_retry():
    calls = {"n": 0}
    def flaky(inputs):
        calls["n"] += 1
        if calls["n"] < 3:
            raise ValueError("boom")
        return "finally"
    t = ManagedTool("f", flaky, ToolPolicy(category="code", retries=3), logger=lambda m: None)
    r = t.execute({}, ("code",))
    assert r["ok"] and r["attempts"] == 3 and r["output"] == "finally"
    def always(inputs): raise ValueError("no")
    t2 = ManagedTool("a", always, ToolPolicy(category="code", retries=2), logger=lambda m: None)
    r2 = t2.execute({}, ("code",))
    assert not r2["ok"] and r2["attempts"] == 2 and "no" in r2["error"]
    print("PASS retry")


def test_timeout():
    def slow(inputs):
        time.sleep(1.0)
        return "late"
    t = ManagedTool("slow", slow, ToolPolicy(category="code", timeout_s=0.2, retries=1),
                    logger=lambda m: None)
    r = t.execute({}, ("code",))
    assert not r["ok"] and "timeout" in r["error"]
    print("PASS timeout")


def test_logging_and_metrics():
    logs = []
    class FakeMetrics:
        def __init__(self): self.counts = {}
        def incr(self, k, v=1): self.counts[k] = self.counts.get(k, 0) + v
        def observe(self, k, s): pass
    fm = FakeMetrics()
    t = ManagedTool("m", lambda i: "x", ToolPolicy(category="code"),
                    logger=logs.append, metrics=fm)
    t.execute({}, ("code",))
    t.execute({}, ())          # permission fail
    assert any("ok in" in l for l in logs) and any("FAILED" in l for l in logs)
    assert fm.counts.get("tool.m.ok") == 1 and fm.counts.get("tool.m.fail") == 1
    print("PASS logging_metrics")


def test_framework_and_adoption():
    fw = ToolFramework(logger=lambda m: None)
    fw.register("hello", lambda i: "hi", ToolPolicy(category="code"))
    assert fw.execute("hello", {}, ("code",))["ok"]
    assert not fw.execute("ghost", {}, ("code",))["ok"]
    assert fw.list()[0]["name"] == "hello"

    class FakeRegistry:
        def __init__(self):
            self._tools = {"web_search": lambda i: "results", "shell_run": lambda i: "done"}
            self._descriptions = {"web_search": "search", "shell_run": "shell"}
            self._categories = {"web_search": "web", "shell_run": "terminal"}
        def tool_names(self): return list(self._tools)
    n = fw.adopt_existing(FakeRegistry())
    assert n == 2
    tools = {t["name"]: t for t in fw.list()}
    assert tools["shell_run"]["dangerous"] is True        # terminal -> shell -> dangerous
    assert tools["shell_run"]["category"] == "shell"
    assert fw.execute("web_search", {}, ("web",))["ok"]
    blocked = fw.execute("shell_run", {}, ("shell",))
    assert not blocked["ok"] and "approved" in blocked["error"]
    assert CATEGORY_MAP["pdf"] == "file"
    print("PASS framework_adoption")


if __name__ == "__main__":
    test_permission(); test_dangerous_needs_approval(); test_validation()
    test_retry(); test_timeout(); test_logging_and_metrics(); test_framework_and_adoption()
    print("\nAll Phase 5 tool framework tests passed!")
