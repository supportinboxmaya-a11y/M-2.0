"""Phase 27 tests — deployment health & monitoring.
Offline, real filesystem probes, no network."""
import os, sys, types
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

from infrastructure.health import HealthMonitor


def test_liveness_cheap():
    h = HealthMonitor()
    r = h.liveness()
    assert r["status"] == "alive"
    assert r["uptime_seconds"] >= 0
    print("PASS liveness")


def test_readiness_all_checks_present():
    h = HealthMonitor(provider_checker=lambda: ["groq"])
    r = h.readiness()
    assert set(r["checks"].keys()) == {"storage_writable", "database",
                                       "llm_provider"}
    assert r["checks"]["storage_writable"]["ok"] is True
    assert r["checks"]["database"]["ok"] is True
    assert r["checks"]["llm_provider"]["ok"] is True
    assert r["ready"] is True and r["status"] == "ready"
    print("PASS readiness all checks pass")


def test_readiness_not_ready_without_provider():
    # No provider configured and no checker -> llm_provider check fails.
    for k in ("GROQ_KEY", "GROQ_API_KEY", "GEMINI_KEY", "GEMINI_API_KEY",
              "OPENAI_KEY", "OPENAI_API_KEY", "ANTHROPIC_KEY", "ANTHROPIC_API_KEY"):
        os.environ.pop(k, None)
    h = HealthMonitor(provider_checker=lambda: [])
    r = h.readiness()
    assert r["ready"] is False and r["status"] == "not_ready"
    assert r["checks"]["llm_provider"]["ok"] is False
    print("PASS readiness not-ready without provider")


def test_readiness_provider_from_env_fallback():
    os.environ["GROQ_KEY"] = "test-key"
    try:
        h = HealthMonitor()               # no checker -> env fallback
        r = h.readiness()
        assert r["checks"]["llm_provider"]["ok"] is True
    finally:
        os.environ.pop("GROQ_KEY", None)
    print("PASS readiness env-fallback provider check")


def test_provider_checker_error_is_safe():
    def boom():
        raise RuntimeError("provider check exploded")
    h = HealthMonitor(provider_checker=boom)
    r = h.readiness()
    assert r["checks"]["llm_provider"]["ok"] is False
    assert "error" in r["checks"]["llm_provider"]     # degrades, never raises
    print("PASS provider checker error degrades safely")


def test_system_info_shape():
    h = HealthMonitor()
    info = h.system_info()
    assert "python_version" in info and "platform" in info
    assert info["uptime_seconds"] >= 0 and info["pid"] > 0
    # disk may be present; if so it has the expected keys
    if info.get("disk"):
        assert "percent_used" in info["disk"]
    print("PASS system info shape")


test_liveness_cheap()
test_readiness_all_checks_present()
test_readiness_not_ready_without_provider()
test_readiness_provider_from_env_fallback()
test_provider_checker_error_is_safe()
test_system_info_shape()
print("\nAll health tests passed")
