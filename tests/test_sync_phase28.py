"""Phase 28 tests — offline sync engine (idempotent action replay).
Offline, real SQLite temp dir."""
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

from infrastructure.sync_engine import SyncEngine

_tmp = tempfile.mkdtemp(prefix="maya_sync28_")


def _engine(tag):
    return SyncEngine(db_path=os.path.join(_tmp, f"s_{tag}.db"))


def test_applies_known_actions():
    eng = _engine("apply")
    stored = []
    eng.register("add_note", lambda payload, user: stored.append(payload["text"]) or {"ok": True})
    batch = [
        {"op_id": "op1", "type": "add_note", "payload": {"text": "a"}},
        {"op_id": "op2", "type": "add_note", "payload": {"text": "b"}},
    ]
    res = eng.apply_batch(batch, user="u@x.com")
    assert res["summary"]["applied"] == 2
    assert stored == ["a", "b"]
    print("PASS applies known actions")


def test_idempotent_replay_dedupes():
    eng = _engine("idem")
    calls = []
    eng.register("act", lambda p, u: calls.append(1) or {"n": len(calls)})
    batch = [{"op_id": "same", "type": "act", "payload": {}}]
    r1 = eng.apply_batch(batch)
    r2 = eng.apply_batch(batch)          # replay same op_id
    assert r1["summary"]["applied"] == 1
    assert r2["summary"]["skipped"] == 1 and r2["summary"]["applied"] == 0
    assert len(calls) == 1               # handler ran only ONCE
    print("PASS idempotent replay dedupes")


def test_unknown_type_rejected():
    eng = _engine("unknown")
    res = eng.apply_batch([{"op_id": "x", "type": "mystery", "payload": {}}])
    assert res["summary"]["rejected"] == 1
    assert res["results"][0]["status"] == "rejected"
    # rejected op is recorded so a replay is also skipped, not retried
    res2 = eng.apply_batch([{"op_id": "x", "type": "mystery", "payload": {}}])
    assert res2["summary"]["skipped"] == 1
    print("PASS unknown type rejected + recorded")


def test_missing_op_id_rejected():
    eng = _engine("noid")
    res = eng.apply_batch([{"type": "act", "payload": {}}])
    assert res["summary"]["rejected"] == 1
    assert res["results"][0]["error"] == "missing op_id"
    print("PASS missing op_id rejected")


def test_handler_failure_isolated():
    eng = _engine("fail")
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
    print("PASS handler failure isolated + recorded")


def test_status_and_recent():
    eng = _engine("status")
    eng.register("act", lambda p, u: {"echo": p.get("v")})
    eng.apply_batch([{"op_id": "s1", "type": "act", "payload": {"v": 42}}],
                    user="me@x.com")
    st = eng.status("s1")
    assert st["status"] == "applied" and st["result"]["echo"] == 42
    recent = eng.recent("me@x.com")
    assert len(recent) == 1 and recent[0]["op_id"] == "s1"
    assert eng.status("nope") is None
    print("PASS status + recent")


def test_known_types():
    eng = _engine("types")
    eng.register("a", lambda p, u: None)
    eng.register("b", lambda p, u: None)
    assert eng.known_types() == ["a", "b"]
    print("PASS known types")


def test_persistence_across_instances():
    db = os.path.join(_tmp, "persist.db")
    e1 = SyncEngine(db_path=db)
    e1.register("act", lambda p, u: {"ok": True})
    e1.apply_batch([{"op_id": "keep", "type": "act", "payload": {}}])
    # new instance (same DB) must remember the op -> dedupe on replay
    e2 = SyncEngine(db_path=db)
    e2.register("act", lambda p, u: {"ok": True})
    res = e2.apply_batch([{"op_id": "keep", "type": "act", "payload": {}}])
    assert res["summary"]["skipped"] == 1
    print("PASS persistence across instances (dedupe survives restart)")


try:
    test_applies_known_actions()
    test_idempotent_replay_dedupes()
    test_unknown_type_rejected()
    test_missing_op_id_rejected()
    test_handler_failure_isolated()
    test_status_and_recent()
    test_known_types()
    test_persistence_across_instances()
    print("\nAll sync-engine tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
