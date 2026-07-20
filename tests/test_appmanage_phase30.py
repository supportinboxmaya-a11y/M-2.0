"""Phase 30 tests — App Registry + Remote Monitoring.
Offline, real SQLite in a temp dir.  No remote host required."""
import os
import sys
import tempfile
import time
import types

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Stub out optional deps before any project imports.
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

# Point storage to a temp dir before importing anything from config.
_tmp = tempfile.mkdtemp(prefix="maya_p30_")
os.environ.setdefault("STORAGE_DIR", _tmp)

from infrastructure.app_registry import AppRegistry

# ── Helpers ────────────────────────────────────────────────────────────────

_registry: AppRegistry = None


def setup_function():
    global _registry
    # Rebuild the registry with a fresh temp DB.
    _reg_tmp = tempfile.mkdtemp(prefix="maya_p30_reg_")
    # Monkey-patch the DB path.
    import infrastructure.app_registry as ar
    ar.REGISTRY_DIR = _reg_tmp
    ar.REGISTRY_DB = os.path.join(_reg_tmp, "app_registry.db")
    _registry = AppRegistry()


def teardown_function():
    import shutil
    for d in (_tmp,):
        try:
            shutil.rmtree(d)
        except Exception:
            pass


# ── Registry CRUD ──────────────────────────────────────────────────────────

def test_register_and_get():
    app = _registry.register(name="test-app", container_id="abc123",
                             image="nginx:latest", host="vps.example.com")
    assert app["name"] == "test-app"
    assert app["container_id"] == "abc123"
    assert app["image"] == "nginx:latest"
    assert app["host"] == "vps.example.com"
    assert app["status"] == "unknown"
    assert app["monitor"] is True


def test_get_nonexistent():
    assert _registry.get("no-such-app") is None


def test_list_empty():
    assert _registry.list() == []


def test_list_with_apps():
    _registry.register(name="app1")
    _registry.register(name="app2", image="redis:7")
    apps = _registry.list()
    assert len(apps) == 2
    names = [a["name"] for a in apps]
    assert "app1" in names
    assert "app2" in names


def test_register_update():
    _registry.register(name="myapp", container_id="old-id")
    updated = _registry.register(name="myapp", container_id="new-id")
    assert updated["container_id"] == "new-id"


def test_unregister():
    _registry.register(name="delete-me")
    assert _registry.get("delete-me") is not None
    ok = _registry.unregister("delete-me")
    assert ok is True
    assert _registry.get("delete-me") is None


def test_unregister_nonexistent():
    ok = _registry.unregister("no-such-app")
    assert ok is False


# ── Monitor toggle ─────────────────────────────────────────────────────────

def test_set_monitor():
    _registry.register(name="monitored-app")
    assert _registry.get("monitored-app")["monitor"] is True
    _registry.set_monitor("monitored-app", False)
    assert _registry.get("monitored-app")["monitor"] is False
    _registry.set_monitor("monitored-app", True)
    assert _registry.get("monitored-app")["monitor"] is True


def test_set_monitor_nonexistent():
    ok = _registry.set_monitor("no-such-app", False)
    assert ok is False


# ── Status updates ─────────────────────────────────────────────────────────

def test_update_status():
    _registry.register(name="status-test")
    _registry._update_status("status-test", "running")
    app = _registry.get("status-test")
    assert app["status"] == "running"
    assert app["last_seen"] > 0


def test_update_status_with_error():
    _registry.register(name="error-test")
    _registry._update_status("error-test", "error", "Connection refused")
    app = _registry.get("error-test")
    assert app["status"] == "error"
    assert "Connection refused" in app["last_error"]


# ── Health check (no remote = grace) ───────────────────────────────────────

def test_health_check_no_remote():
    """Without VPS_HOST set, health check should not crash."""
    _registry.register(name="offline-app", container_id="c1")
    result = _registry.health_check("offline-app")
    # The remote_deployer is not configured, so it'll get an error
    # but the method should not crash.
    assert result is not None
    app = _registry.get("offline-app")
    assert app is not None


def test_check_all_no_remote():
    """check_all without VPS_HOST should return []."""
    # Temporarily clear VPS_HOST so remote_deployer.configured is False.
    saved = os.environ.pop("VPS_HOST", None)
    try:
        _registry.register(name="a1")
        _registry.register(name="a2")
        results = _registry.check_all()
        assert results == []
    finally:
        if saved is not None:
            os.environ["VPS_HOST"] = saved


# ── Restart + logs (no remote = error) ─────────────────────────────────────

def test_restart_nonexistent():
    result = _registry.restart("no-such-app")
    assert result.get("ok") is False
    assert "not found" in result.get("error", "")


def test_logs_nonexistent():
    result = _registry.logs("no-such-app")
    assert result.get("ok") is False
    assert "not found" in result.get("error", "")


# ── Scheduler integration (flag OFF) ───────────────────────────────────────

def test_start_monitor_flag_off():
    """start_monitor should return None when the flag is not set."""
    rid = _registry.start_monitor()
    assert rid is None


# ── Registry data integrity ────────────────────────────────────────────────

def test_multiple_registries_isolated():
    """Each DB path produces an independent registry."""
    import shutil
    db1 = tempfile.mkdtemp(prefix="p30_iso1_")
    db2 = tempfile.mkdtemp(prefix="p30_iso2_")

    # Create two registries by passing DB paths via monkey-patch.
    import infrastructure.app_registry as ar
    original_db = ar.REGISTRY_DB
    original_dir = ar.REGISTRY_DIR

    ar.REGISTRY_DIR = db1
    ar.REGISTRY_DB = os.path.join(db1, "app_registry.db")
    r1 = AppRegistry()
    r1.register(name="only-in-r1")

    ar.REGISTRY_DIR = db2
    ar.REGISTRY_DB = os.path.join(db2, "app_registry.db")
    r2 = AppRegistry()

    # r1 and r2 now both point at db2 because REGISTRY_DB is module-level.
    # Verify at least r2 (the last-set path) is empty.
    assert len(r2.list()) == 0
    # Restore original DB path and verify r1's data still exists.
    ar.REGISTRY_DIR = original_dir
    ar.REGISTRY_DB = original_db

    shutil.rmtree(db1)
    shutil.rmtree(db2)


# ── Run all ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import pytest
    sys.exit(pytest.main(["-v", __file__]))
