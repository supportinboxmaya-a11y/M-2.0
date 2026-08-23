"""Phase 28 tests — offline sync engine (idempotent action replay).
Offline, real SQLite temp dir."""
import os, shutil, sys, tempfile, types
import pytest
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

from infrastructure.sync_engine import SyncEngine


@pytest.fixture
def temp_dir():
    """Create a fresh temp directory for each test."""
    _tmp = tempfile.mkdtemp(prefix="maya_sync28_")
    yield _tmp
    shutil.rmtree(_tmp, ignore_errors=True)


def _engine(tag, tmp_dir):
    return SyncEngine(db_path=os.path.join(tmp_dir, f"s_{tag}.db"))


def test_applies_known_actions(temp_dir):
    eng = _engine("apply", temp_dir)
    stored = []
    eng.register("add_note", lambda payload, user: stored.append(payload["text"]) or {"ok": True})
    batch = [
        {"op_id": "op1", "type": "add_note", "payload": {"text": "a"}},
        {"op_id": "op2", "type": "add_note", "payload": {"text": "b"}},
    ]
    res = eng.apply_batch(batch, user="u@x.com")
    assert res["summary"]["applied"] == 2
    assert stored == ["a", "b"]


def test_idempotent_replay_dedupes(temp_dir):
    eng = _engine("idem", temp_dir)
    calls = []
    eng.register("act", lambda p, u: calls.append(1) or {"n": len(calls)})
    batch = [{"op_id": "same", "type": "act", "payload": {}}]
    r1 = eng.apply_batch(batch)
    r2 = eng.apply_batch(batch)          # replay same op_id
    assert r1["summary"]["applied"] == 1
    assert r2["summary"]["skipped"] == 1 and r2["summary"]["applied"] == 0
    assert len(calls) == 1               # handler ran only ONCE


def test_unknown_type_rejected(temp_dir):
    eng = _engine("unknown", temp_dir)
    res = eng.apply_batch([{"op_id": "x", "type": "mystery", "payload": {}}])
    assert res["summary"]["rejected"] == 1
    assert res["results"][0]["status"] == "rejected"
    # rejected op is recorded so a replay is also skipped, not retried
    res2 = eng.apply_batch([{"op_id": "x", "type": "mystery", "payload": {}}])
    assert res2["summary"]["skipped"] == 1


def test_missing_op_id_rejected(temp_dir):
    eng = _engine("noid", temp_dir)
    res = eng.apply_batch([{"type": "act", "payload": {}}])
    assert res["summary"]["rejected"] == 1
    assert res["results"][0]["error"] == "missing op_id"


def test_handler_failure_isolated(temp_dir):
    eng = _engine("fail", temp_dir)
    ran = []
    def boom(p, u):
        raise RuntimeError("handler exploded")
    eng.register("boom", boom)
    eng.register("ok", lambda p, u: ran.append(1) or {"ok": True})
    batch = [
        {"op_id": "b1", "type": "boom", "payload": {}},
        {"op_id": "o1", "type": "ok", "payload": {}},
    ]
    res = eng.apply_batch(batch)
    assert res["summary"]["failed"] == 1 and res["summary"]["applied"] == 1
    assert ran == [1]                    # good op still ran after bad one
    # a failed op is recorded (won't silently retry-loop on next push)
    assert eng.status("b1")["status"] == "failed"


def test_status_and_recent(temp_dir):
    eng = _engine("status", temp_dir)
    eng.register("act", lambda p, u: {"echo": p.get("v")})
    eng.apply_batch([{"op_id": "s1", "type": "act", "payload": {"v": 42}}],
                    user="me@x.com")
    st = eng.status("s1")
    assert st["status"] == "applied" and st["result"]["echo"] == 42
    recent = eng.recent("me@x.com")
    assert len(recent) == 1 and recent[0]["op_id"] == "s1"
    assert eng.status("nope") is None


def test_known_types(temp_dir):
    eng = _engine("types", temp_dir)
    eng.register("a", lambda p, u: None)
    eng.register("b", lambda p, u: None)
    assert eng.known_types() == ["a", "b"]


def test_persistence_across_instances(temp_dir):
    db = os.path.join(temp_dir, "persist.db")
    e1 = SyncEngine(db_path=db)
    e1.register("act", lambda p, u: {"ok": True})
    e1.apply_batch([{"op_id": "keep", "type": "act", "payload": {}}])
    # new instance (same DB) must remember the op -> dedupe on replay
    e2 = SyncEngine(db_path=db)
    e2.register("act", lambda p, u: {"ok": True})
    res = e2.apply_batch([{"op_id": "keep", "type": "act", "payload": {}}])
    assert res["summary"]["skipped"] == 1


if __name__ == "__main__":
    import tempfile, shutil
    _tmp = tempfile.mkdtemp(prefix="maya_sync28_")
    try:
        test_applies_known_actions(_tmp)
        test_idempotent_replay_dedupes(_tmp)
        test_unknown_type_rejected(_tmp)
        test_missing_op_id_rejected(_tmp)
        test_handler_failure_isolated(_tmp)
        test_status_and_recent(_tmp)
        test_known_types(_tmp)
        test_persistence_across_instances(_tmp)
        print("\nAll sync-engine tests passed")
    finally:
        shutil.rmtree(_tmp, ignore_errors=True)
