"""Phase 18 tests — persistent background task queue + restart recovery.
Offline, real SQLite in a temp dir, real asyncio."""
import asyncio
import os
import shutil
import sys
import tempfile
import types

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

from infrastructure.task_queue import TaskQueue


def _make_temp_db():
    """Create a fresh temp directory and return a db path in it."""
    tmp = tempfile.mkdtemp(prefix="maya_q18_")
    return os.path.join(tmp, "q.db"), tmp


async def _drain(q, timeout=3.0):
    """Wait until the queue is empty and workers are idle."""
    await asyncio.wait_for(q._queue.join(), timeout=timeout)


def test_inprocess_submit_still_works():
    db_path, tmp = _make_temp_db()
    async def go():
        q = TaskQueue(workers=2, db_path=db_path, persist=True)
        await q.start()
        out = {}
        async def job():
            out["ran"] = True
            return "hello"
        tid = await q.submit(job, name="greet")
        await _drain(q)
        st = q.status(tid)
        assert st["state"] == "done" and st["result"] == "hello"
        assert out.get("ran")
    asyncio.run(go())
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS in-process submit still works")


def test_persistent_job_runs_and_persists():
    db_path, tmp = _make_temp_db()
    async def go():
        q = TaskQueue(workers=2, db_path=db_path, persist=True)
        results = []
        async def handler(x, y=0):
            results.append(x + y)
            return x + y
        q.register("add", handler)
        await q.start()
        tid = await q.submit_job("add", 3, y=4)
        await _drain(q)
        st = q.status(tid)
        assert st["state"] == "done" and st["result"] == 7
        assert results == [7]
        # a fresh instance (same DB) must SEE the finished task
        q2 = TaskQueue(workers=1, db_path=db_path, persist=True)
        assert q2.status(tid)["result"] == 7
    asyncio.run(go())
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS persistent job runs and is stored")


def test_restart_recovery_resumes_unfinished():
    """Simulate a crash: write a queued job to the DB with no worker
    running, then start a NEW queue and confirm it resumes the job."""
    db_path, tmp = _make_temp_db()

    async def phase1():
        q = TaskQueue(workers=1, db_path=db_path, persist=True)
        q.register("noop", lambda: asyncio.sleep(9))  # not started (no start())
        # Manually persist a queued job as if the server died before running
        tid = "recover123456"
        rec = {"name": "noop", "job": "noop", "state": "queued",
               "queued_at": 1.0, "args": [], "kwargs": {}, "attempts": 0}
        q._status[tid] = rec
        q._save(tid, rec)
        return tid

    async def phase2(tid):
        ran = {"v": False}
        async def handler():
            ran["v"] = True
            return "recovered"
        q = TaskQueue(workers=1, db_path=db_path, persist=True)
        q.register("noop", handler)
        await q.start()          # _recover() should re-enqueue tid
        await _drain(q)
        st = q.status(tid)
        assert st["state"] == "done" and st["result"] == "recovered"
        assert ran["v"]

    tid = asyncio.run(phase1())
    asyncio.run(phase2(tid))
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS restart recovery resumes unfinished job")


def test_recovery_fails_orphans_without_handler():
    db_path, tmp = _make_temp_db()

    async def phase1():
        q = TaskQueue(workers=1, db_path=db_path, persist=True)
        tid = "orphan1234567"
        rec = {"name": "ghost", "job": "ghost_job", "state": "running",
               "queued_at": 1.0, "started_at": 1.5, "args": [], "kwargs": {},
               "attempts": 1}
        q._status[tid] = rec
        q._save(tid, rec)
        return tid

    async def phase2(tid):
        q = TaskQueue(workers=1, db_path=db_path, persist=True)
        await q.start()          # no 'ghost_job' handler registered
        st = q.status(tid)
        assert st["state"] == "failed" and "not registered" in st["error"]

    tid = asyncio.run(phase1())
    asyncio.run(phase2(tid))
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS orphan job without handler is failed, not hung")


def test_cancel_before_start():
    db_path, tmp = _make_temp_db()
    async def go():
        q = TaskQueue(workers=1, db_path=db_path, persist=True)
        async def slow():
            await asyncio.sleep(5)
        q.register("slow", slow)
        # don't start workers, so it stays queued
        tid = await q.submit_job("slow")
        assert q.cancel(tid) is True
        assert q.status(tid)["state"] == "cancelled"
        assert q.cancel(tid) is False       # can't cancel twice
    asyncio.run(go())
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS cancel before start")


def test_submit_job_validation():
    db_path, tmp = _make_temp_db()
    async def go():
        q = TaskQueue(workers=1, db_path=db_path, persist=True)
        try:
            await q.submit_job("missing")
            assert False
        except ValueError as e:
            assert "No registered job" in str(e)
        q.register("ok", lambda: asyncio.sleep(0))
        try:
            await q.submit_job("ok", object())   # not JSON-serializable
            assert False
        except ValueError as e:
            assert "JSON" in str(e)
    asyncio.run(go())
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS submit_job validation")


def test_stats_shape():
    db_path, tmp = _make_temp_db()
    async def go():
        q = TaskQueue(workers=3, db_path=db_path, persist=True)
        q.register("j", lambda: asyncio.sleep(0))
        s = q.stats()
        assert s["persist"] and s["workers"] == 3
        assert "j" in s["registered_jobs"] and "counts" in s
    asyncio.run(go())
    shutil.rmtree(tmp, ignore_errors=True)
    print("PASS stats shape")


if __name__ == "__main__":
    try:
        test_inprocess_submit_still_works()
        test_persistent_job_runs_and_persists()
        test_restart_recovery_resumes_unfinished()
        test_recovery_fails_orphans_without_handler()
        test_cancel_before_start()
        test_submit_job_validation()
        test_stats_shape()
        print("\nAll task-queue persistence tests passed")
    finally:
        pass  # cleanup handled per-test