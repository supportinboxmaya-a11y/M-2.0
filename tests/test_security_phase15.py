"""Phase 15 sandbox-hardening tests — offline, real subprocesses."""
import os, shutil, sys, tempfile, types
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

from security.sandbox import Sandbox
from tools.code.code_runner import CodeRunner

try:
    import resource  # noqa: F401
    HAS_RLIMITS = True
except ImportError:
    HAS_RLIMITS = False

_tmp = tempfile.mkdtemp(prefix="maya_sbx15_")


def test_path_boundary_fix():
    """A sibling dir sharing the workspace prefix must be rejected —
    the old raw startswith() check let '/workspace_evil' through."""
    ws = os.path.join(_tmp, "workspace")
    evil = os.path.join(_tmp, "workspace_evil")
    os.makedirs(ws, exist_ok=True)
    os.makedirs(evil, exist_ok=True)
    sb = Sandbox(workspace=ws)
    assert sb.is_safe_path("notes.txt")
    assert sb.is_safe_path(".")
    assert not sb.is_safe_path("../workspace_evil/x.txt")
    assert not sb.is_safe_path(os.path.join("..", "workspace_evil"))
    try:
        sb.safe_path("../../etc/passwd")
        assert False
    except PermissionError:
        pass
    print("PASS path boundary fix")


def test_env_scrubbing_no_secret_leak():
    """Executed code must not see the parent's API keys anymore."""
    env = Sandbox().scrubbed_env()
    assert "PATH" in env and env.get("PYTHONPATH") == ""
    for k in env:
        assert "KEY" not in k.upper() and "TOKEN" not in k.upper()

    os.environ["SECRET_TEST_KEY_15"] = "super-secret-value"
    try:
        r = CodeRunner().run(
            "import os; print(os.environ.get('SECRET_TEST_KEY_15', 'MISSING'))",
            timeout=15)
        assert r["success"], r
        assert "MISSING" in r["output"]
        assert "super-secret-value" not in r["output"]
    finally:
        del os.environ["SECRET_TEST_KEY_15"]
    print("PASS env scrubbing (no secret leak)")


def test_memory_limit_kills_runaway():
    if not HAS_RLIMITS:
        print("SKIP memory limit (no resource module)")
        return
    r = CodeRunner().run(
        "x = bytearray(1024 * 1024 * 1024); print('allocated')", timeout=20)
    assert not r["success"]
    assert "allocated" not in r["output"]
    print("PASS memory limit kills 1GB allocation")


def test_fsize_limit_blocks_huge_writes():
    if not HAS_RLIMITS:
        print("SKIP fsize limit (no resource module)")
        return
    code = (
        "f = open('big.bin', 'wb')\n"
        "f.write(b'0' * (200 * 1024 * 1024))\n"
        "f.close()\n"
        "print('wrote')\n")
    r = CodeRunner().run(code, timeout=20)
    assert not r["success"] and "wrote" not in r["output"]
    from config.settings import WORKSPACE_DIR
    big = os.path.join(str(WORKSPACE_DIR), "big.bin")
    if os.path.exists(big):
        assert os.path.getsize(big) <= 51 * 1024 * 1024
        os.remove(big)
    print("PASS fsize limit blocks 200MB write")


def test_normal_code_still_works():
    """Hardening must not break legitimate code (backward compat)."""
    r = CodeRunner().run(
        "import json, math\n"
        "print(json.dumps({'pi': round(math.pi, 4)}))", timeout=15)
    assert r["success"], r
    assert "3.1416" in r["output"]
    r2 = CodeRunner().run("echo hardened-ok", language="bash", timeout=10)
    assert r2["success"] and "hardened-ok" in r2["output"]
    print("PASS normal python + shell still work")


def test_pattern_block_unchanged():
    r = CodeRunner().run("eval('1+1')")
    assert not r["success"] and "Security blocked" in r["error"]
    print("PASS pattern blocklist unchanged")


try:
    test_path_boundary_fix()
    test_env_scrubbing_no_secret_leak()
    test_memory_limit_kills_runaway()
    test_fsize_limit_blocks_huge_writes()
    test_normal_code_still_works()
    test_pattern_block_unchanged()
    print("\nAll sandbox-hardening tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
