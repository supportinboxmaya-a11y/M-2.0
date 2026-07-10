"""Phase 14 tests — local git tool (real git, temp workspace) + GraphQL
tool (fake transport). Offline, zero network."""
import json, os, shutil, sys, tempfile, types
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

from tools.code.git_tool import GitTool
from tools.web.graphql_tool import GraphQLTool

_tmp = tempfile.mkdtemp(prefix="maya_git14_")


def _tool() -> GitTool:
    return GitTool(workspace=_tmp)


def test_git_full_flow():
    g = _tool()
    os.makedirs(os.path.join(_tmp, "proj"), exist_ok=True)
    assert not g.init("proj").startswith("Error")
    with open(os.path.join(_tmp, "proj", "app.py"), "w") as f:
        f.write("print('v1')\n")
    assert not g.add("proj", ".").startswith("Error")
    out = g.commit("proj", "first commit")
    assert not out.startswith("Error"), out
    assert "first commit" in g.log("proj", limit=5)
    assert "app.py" not in g.status("proj")          # clean tree
    with open(os.path.join(_tmp, "proj", "app.py"), "w") as f:
        f.write("print('v2')\n")
    assert "v2" in g.diff("proj")
    print("PASS git init/add/commit/log/status/diff")


def test_git_branch_and_merge():
    g = _tool()
    assert not g.branch("proj", "feature-x").startswith("Error")
    with open(os.path.join(_tmp, "proj", "feature.txt"), "w") as f:
        f.write("new feature\n")
    g.add("proj", ".")
    g.commit("proj", "add feature file")
    main = "master" if "master" in g.branch("proj") else "main"
    assert not g.checkout("proj", main).startswith("Error")
    out = g.merge("proj", "feature-x")
    assert not out.startswith("Error"), out
    assert os.path.exists(os.path.join(_tmp, "proj", "feature.txt"))
    print("PASS git branch/checkout/merge")


def test_git_merge_conflict_safe():
    g = _tool()
    main = "master" if "master" in g.branch("proj") else "main"
    g.branch("proj", "conflict-a")
    with open(os.path.join(_tmp, "proj", "app.py"), "w") as f:
        f.write("print('branch-a')\n")
    g.add("proj", "."); g.commit("proj", "a change")
    g.checkout("proj", main)
    with open(os.path.join(_tmp, "proj", "app.py"), "w") as f:
        f.write("print('main change')\n")
    g.add("proj", "."); g.commit("proj", "main change")
    out = g.merge("proj", "conflict-a")
    assert out.startswith("Error") and "conflict" in out.lower()
    assert "no merge to abort" not in g.status("proj").lower()  # aborted cleanly
    print("PASS git merge conflict aborts safely")


def test_git_security():
    g = _tool()
    assert "escapes the workspace" in g.status("../..")
    assert g.branch("proj", "--force").startswith("Error")
    assert g.checkout("proj", "-b evil").startswith("Error")
    assert g.commit("proj", "").startswith("Error")
    assert g.status("no_such_dir").startswith("Error")
    print("PASS git security checks")


class _Resp:
    def __init__(self, payload, status=200, text=""):
        self._p = payload
        self.status_code = status
        self.text = text or json.dumps(payload)

    def json(self):
        if self._p is None:
            raise ValueError("not json")
        return self._p


def _with_fake_requests(resp_or_exc, fn):
    fake = types.ModuleType("requests")
    if isinstance(resp_or_exc, Exception):
        def post(*a, **kw):
            raise resp_or_exc
    else:
        def post(*a, **kw):
            return resp_or_exc
    fake.post = post
    old = sys.modules.get("requests")
    sys.modules["requests"] = fake
    try:
        return fn()
    finally:
        if old is not None:
            sys.modules["requests"] = old
        else:
            del sys.modules["requests"]


def test_graphql_success_and_errors():
    g = GraphQLTool()
    assert g.query("ftp://x", "{a}").startswith("Error")
    assert g.query("https://x", "").startswith("Error")
    assert g.query("https://x", "{a}", variables="{bad json").startswith("Error")

    ok = _with_fake_requests(
        _Resp({"data": {"user": {"name": "Maya"}}}),
        lambda: g.query("https://api.example.com/graphql",
                        "query { user { name } }"))
    assert "Status: 200" in ok and "Maya" in ok

    err = _with_fake_requests(
        _Resp({"errors": [{"message": "Field 'x' not found"}]}),
        lambda: g.query("https://api.example.com/graphql", "{x}"))
    assert "GraphQL errors" in err and "not found" in err

    class _T(Exception):
        pass
    _T.__name__ = "ConnectTimeout"
    timeout = _with_fake_requests(_T(), lambda: g.query("https://x", "{a}"))
    assert "timed out" in timeout

    notjson = _with_fake_requests(
        _Resp(None, status=502, text="<html>bad gateway</html>"),
        lambda: g.query("https://x", "{a}"))
    assert "not JSON" in notjson
    print("PASS graphql success/errors/timeout/non-json")


try:
    test_git_full_flow()
    test_git_branch_and_merge()
    test_git_merge_conflict_safe()
    test_git_security()
    test_graphql_success_and_errors()
    print("\nAll git + graphql tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
