"""Phase 19 tests — cron parser + persistent scheduler.
Offline, real SQLite temp dir, real asyncio, deterministic clock."""
import asyncio, os, shutil, sys, tempfile, types
from datetime import datetime
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

from infrastructure.cron import CronExpression
from infrastructure.scheduler import Scheduler
from infrastructure.task_queue import TaskQueue

_tmp = tempfile.mkdtemp(prefix="maya_sched19_")


# ── cron parser ───────────────────────────────────────────────────
def test_cron_basic_matching():
    c = CronExpression("30 9 * * *")     # 09:30 daily
    assert c.matches(datetime(2026, 7, 10, 9, 30))
    assert not c.matches(datetime(2026, 7, 10, 9, 31))
    assert not c.matches(datetime(2026, 7, 10, 10, 30))
    print("PASS cron basic matching")


def test_cron_ranges_lists_steps():
    assert CronExpression("*/15 * * * *").matches(datetime(2026, 1, 1, 0, 45))
    assert not CronExpression("*/15 * * * *").matches(datetime(2026, 1, 1, 0, 46))
    assert CronExpression("0 9-17 * * *").matches(datetime(2026, 1, 1, 13, 0))
    assert not CronExpression("0 9-17 * * *").matches(datetime(2026, 1, 1, 18, 0))
    assert CronExpression("0 0 1,15 * *").matches(datetime(2026, 3, 15, 0, 0))
    print("PASS cron ranges/lists/steps")


def test_cron_aliases_and_dow():
    assert CronExpression("@daily").matches(datetime(2026, 5, 5, 0, 0))
    assert CronExpression("@hourly").matches(datetime(2026, 5, 5, 14, 0))
    # Sunday = 0 in cron; 2026-07-12 is a Sunday
    assert CronExpression("0 0 * * 0").matches(datetime(2026, 7, 12, 0, 0))
    assert not CronExpression("0 0 * * 0").matches(datetime(2026, 7, 13, 0, 0))
    print("PASS cron aliases + day-of-week")


def test_cron_validation():
    for bad in ("* * *", "60 * * * *", "* 24 * * *", "*/0 * * * *",
                "5-2 * * * *", "abc * * * *"):
        try:
            CronExpression(bad)
            assert False, f"should reject '{bad}'"
        except ValueError:
            pass
    print("PASS cron validation rejects bad expressions")


def test_cron_next_after():
    c = CronExpression("0 12 * * *")     # noon daily
    nxt = c.next_after(datetime(2026, 7, 10, 15, 0))
    assert nxt == datetime(2026, 7, 11, 12, 0)
    print("PASS cron next_after")


# ── scheduler ─────────────────────────────────────────────────────
def _stack(tag):
    q = TaskQueue(workers=1, db_path=os.path.join(_tmp, f"q_{tag}.db"),
                  persist=True)
    s = Scheduler(q, db_path=os.path.join(_tmp, f"s_{tag}.db"))
    return q, s


def test_add_validates_job_and_cron():
    async def go():
        q, s = _stack("v")
        try:
            s.add("bad", "* * * * *", "nonexistent_job")
            assert False
        except ValueError as e:
            assert "not a registered" in str(e)
        q.register("noop", lambda: asyncio.sleep(0))
        try:
            s.add("bad", "bad cron", "noop")
            assert False
        except ValueError:
            pass
        rec = s.add("good", "@daily", "noop")
        assert rec["enabled"] and rec["next_run"] is not None
    asyncio.run(go())
    print("PASS scheduler add validates job + cron")


def test_tick_fires_due_schedule():
    async def go():
        q, s = _stack("fire")
        fired = []
        async def handler(msg="x"):
            fired.append(msg)
            return msg
        q.register("report", handler)
        await q.start()
        # schedule every minute; tick just after its computed next_run
        rec = s.add("hourly-report", "* * * * *", "report", kwargs={"msg": "hi"})
        from datetime import timedelta
        fire_at = datetime.fromtimestamp(rec["next_run"]) + timedelta(seconds=1)
        ids = await s.tick(now=fire_at)
        assert len(ids) == 1
        await asyncio.wait_for(q._queue.join(), timeout=3)
        assert fired == ["hi"]
        # queue task recorded as done
        assert q.status(ids[0])["state"] == "done"
    asyncio.run(go())
    print("PASS scheduler tick fires due schedule via queue")


def test_disabled_schedule_does_not_fire():
    async def go():
        q, s = _stack("dis")
        q.register("noop", lambda: asyncio.sleep(0))
        rec = s.add("off", "* * * * *", "noop")
        s.set_enabled(rec["id"], False)
        from datetime import timedelta
        fire_at = datetime.fromtimestamp(rec["next_run"]) + timedelta(seconds=1)
        ids = await s.tick(now=fire_at)
        assert ids == []
        print("PASS disabled schedule does not fire")
    asyncio.run(go())


def test_no_catchup_burst_and_advances():
    async def go():
        q, s = _stack("catch")
        q.register("noop", lambda: asyncio.sleep(0))
        await q.start()
        rec = s.add("noon", "0 12 * * *", "noop")
        from datetime import timedelta
        # Tick well after the scheduled noon: fires exactly ONCE
        base = datetime.fromtimestamp(rec["next_run"])
        fire_at = base + timedelta(hours=6)
        ids = await s.tick(now=fire_at)
        assert len(ids) == 1
        after = s.get(rec["id"])
        assert after["next_run"] > fire_at.timestamp()
        # ticking again a minute later does not double-fire
        ids2 = await s.tick(now=fire_at + timedelta(minutes=1))
        assert ids2 == []
    asyncio.run(go())
    print("PASS no catch-up burst; next_run advances")


def test_persistence_across_instances():
    async def go():
        db = os.path.join(_tmp, "persist_s.db")
        q = TaskQueue(workers=1, db_path=os.path.join(_tmp, "persist_q.db"),
                      persist=True)
        q.register("noop", lambda: asyncio.sleep(0))
        s1 = Scheduler(q, db_path=db)
        rec = s1.add("keep", "@daily", "noop")
        # a fresh scheduler on the same DB sees the schedule
        s2 = Scheduler(q, db_path=db)
        got = s2.get(rec["id"])
        assert got and got["name"] == "keep"
        assert s2.remove(rec["id"]) and s2.get(rec["id"]) is None
    asyncio.run(go())
    print("PASS schedules persist across instances")


try:
    test_cron_basic_matching()
    test_cron_ranges_lists_steps()
    test_cron_aliases_and_dow()
    test_cron_validation()
    test_cron_next_after()
    test_add_validates_job_and_cron()
    test_tick_fires_due_schedule()
    test_disabled_schedule_does_not_fire()
    test_no_catchup_burst_and_advances()
    test_persistence_across_instances()
    print("\nAll scheduler tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
