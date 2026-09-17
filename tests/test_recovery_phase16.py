"""Phase 16 tests — autonomous recovery strategy + engine integration.
Offline, deterministic, no network / no LLM."""
import asyncio, os, sys, types
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

from autonomous.recovery import (RecoveryStrategy, RETRY, ALTERNATE,
                                 REPLAN, ABORT)


def test_classification():
    c = RecoveryStrategy.classify
    assert c("Request timed out after 30s") == RETRY
    assert c("HTTP 429 rate limit exceeded") == RETRY
    assert c("Tool 'x' failed: permission denied") == ALTERNATE
    assert c("Error 400 invalid argument") == ALTERNATE
    assert c("file not found: config.yaml") == REPLAN
    assert c("no result returned") == REPLAN
    assert c("Security blocked: eval") == ABORT
    assert c("escapes the workspace") == ABORT
    print("PASS error classification")


def test_backoff_grows_then_capped():
    rs = RecoveryStrategy(max_attempts=6, base_delay=1.0, max_delay=8.0)
    d1 = rs.decide("n", "connection reset", attempt=1)
    d2 = rs.decide("n2", "connection reset", attempt=2)
    d3 = rs.decide("n3", "connection reset", attempt=3)
    d9 = rs.decide("n4", "connection reset", attempt=6)
    assert d1.strategy == RETRY and d1.backoff_seconds == 1.0
    assert d2.backoff_seconds == 2.0 and d3.backoff_seconds == 4.0
    assert d9.strategy == ABORT       # attempt >= max_attempts
    print("PASS backoff grows and caps, abort at budget")


def test_repeated_error_escalates():
    rs = RecoveryStrategy(max_attempts=5)
    # Unknown error defaults to RETRY, but repeating twice → ALTERNATE
    rs.decide("node1", "weird glitch", attempt=1)
    d = rs.decide("node1", "weird glitch", attempt=2)
    assert d.strategy == ALTERNATE
    assert rs.history("node1").count("weird glitch") == 2
    print("PASS repeated identical error escalates to alternate")


def test_reflection_note_present():
    rs = RecoveryStrategy()
    d = rs.decide("n", "tool 'browser' failed: not configured", attempt=1,
                  goal="Book a flight", description="open booking site")
    assert d.strategy == ALTERNATE
    assert "different way" in d.reflection.lower()
    assert "open booking site" in d.reflection
    print("PASS reflection note guides next attempt")


def test_abort_on_hard_block_even_first_try():
    rs = RecoveryStrategy(max_attempts=5)
    d = rs.decide("n", "Security blocked: dangerous pattern", attempt=1)
    assert d.strategy == ABORT
    print("PASS hard block aborts immediately")


def test_engine_recovers_transient_failure():
    """Full engine run: a node fails transiently once, then succeeds.
    Recovery must retry it and the run completes with a recovery_log."""
    from workflows.engine import WorkflowEngine
    from autonomous.recovery import RecoveryStrategy

    engine = WorkflowEngine(recovery=RecoveryStrategy(max_attempts=3,
                                                      base_delay=0.0))
    run = engine.create("write a short greeting")

    attempts = {"n": 0}

    def execute_fn(agent, node):
        # Fail the first time with a transient error, then succeed.
        attempts["n"] += 1
        note = getattr(node, "recovery_note", "")
        if attempts["n"] == 1:
            raise RuntimeError("connection reset by peer")
        # second attempt should carry a reflection note
        return (f"done (note_seen={bool(note)})", True)

    result = asyncio.run(engine.execute(run, execute_fn, retry_failed=1))
    # at least one retry happened and it was logged as a RETRY decision
    assert any(entry["strategy"] == RETRY for entry in result["recovery_log"])
    assert attempts["n"] >= 2
    print("PASS engine retries transient failure via recovery")


def test_engine_aborts_hard_block():
    from workflows.engine import WorkflowEngine
    from autonomous.recovery import RecoveryStrategy

    engine = WorkflowEngine(recovery=RecoveryStrategy(max_attempts=5,
                                                      base_delay=0.0))
    run = engine.create("do something blocked")
    calls = {"n": 0}

    def execute_fn(agent, node):
        calls["n"] += 1
        raise RuntimeError("Security blocked: eval() not allowed")

    result = asyncio.run(engine.execute(run, execute_fn, retry_failed=3))
    aborts = [e for e in result["recovery_log"] if e["strategy"] == ABORT]
    assert aborts, "hard block should produce an ABORT decision"
    # Should NOT burn all retries hammering a blocked call.
    assert calls["n"] <= 2
    print("PASS engine aborts hard-blocked step without wasting retries")


test_classification()
test_backoff_grows_then_capped()
test_repeated_error_escalates()
test_reflection_note_present()
test_abort_on_hard_block_even_first_try()
test_engine_recovers_transient_failure()
test_engine_aborts_hard_block()
print("\nAll recovery tests passed")
