"""Unit tests for Phase 1 infrastructure (stdlib-only, run directly)."""
import asyncio, os, sys, time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from infrastructure.config_manager import ConfigManager
from infrastructure.secrets import SecretManager
from infrastructure.metrics import Metrics
from infrastructure.retry import retry
from infrastructure.cache import TTLCache
from infrastructure.rate_limiter import RateLimiter
from infrastructure.task_queue import TaskQueue
from infrastructure.feature_flags import FeatureFlags


def test_config():
    c = ConfigManager()
    os.environ["X_INT"] = "42"; os.environ["X_BOOL"] = "true"; os.environ["X_BAD"] = "abc"
    assert c.get_int("X_INT") == 42
    assert c.get_bool("X_BOOL") is True
    assert c.get_int("X_BAD", 7) == 7          # bad cast -> default
    assert c.get("X_MISSING", "d") == "d"
    c.set_override("X_INT", 1); assert c.get_int("X_INT") == 1
    c.clear_override("X_INT"); assert c.get_int("X_INT") == 42
    print("PASS config")

def test_secrets():
    s = SecretManager()
    os.environ["S_API_KEY"] = "sk-abcdef"
    assert s.get("S_KEY", "S_API_KEY") == "sk-abcdef"
    assert s.has("S_KEY", "S_API_KEY")
    assert "sk-a" in s.mask("sk-abcdef") and "abcdef" not in s.mask("sk-abcdef")
    try: s.get("NOPE_1", "NOPE_2", required=True); assert False
    except KeyError: pass
    print("PASS secrets")

def test_metrics():
    m = Metrics()
    m.incr("req"); m.incr("req", 2)
    with m.timer("op"): time.sleep(0.01)
    snap = m.snapshot()
    assert snap["counters"]["req"] == 3
    assert snap["latency"]["op"]["count"] == 1
    print("PASS metrics")

def test_retry():
    calls = {"n": 0}
    @retry(attempts=3, base_delay=0.01)
    def flaky():
        calls["n"] += 1
        if calls["n"] < 3: raise ValueError("boom")
        return "ok"
    assert flaky() == "ok" and calls["n"] == 3
    @retry(attempts=2, base_delay=0.01)
    def always(): raise ValueError("no")
    try: always(); assert False
    except ValueError: pass
    print("PASS retry")

def test_retry_async():
    calls = {"n": 0}
    @retry(attempts=3, base_delay=0.01)
    async def aflaky():
        calls["n"] += 1
        if calls["n"] < 2: raise ValueError("boom")
        return "ok"
    assert asyncio.run(aflaky()) == "ok"
    print("PASS retry_async")

def test_cache():
    c = TTLCache(max_size=2, default_ttl=0.05)
    c.set("a", 1); assert c.get("a") == 1
    time.sleep(0.06); assert c.get("a") is None          # expired
    c.set("x", 1); c.set("y", 2); c.set("z", 3)
    assert c.stats()["size"] == 2                         # evicted
    print("PASS cache")

def test_rate_limiter():
    rl = RateLimiter(rate=2, per_seconds=60)
    assert rl.allow("u1") and rl.allow("u1") and not rl.allow("u1")
    assert rl.allow("u2")                                 # separate key
    print("PASS rate_limiter")

def test_task_queue():
    async def main():
        q = TaskQueue(workers=1)
        await q.start()
        async def job(x): return x * 2
        async def bad(): raise RuntimeError("fail!")
        t1 = await q.submit(job, 21, name="double")
        t2 = await q.submit(bad, name="bad")
        await asyncio.sleep(0.1)
        assert q.status(t1)["state"] == "done" and q.status(t1)["result"] == 42
        assert q.status(t2)["state"] == "failed" and "fail!" in q.status(t2)["error"]
    asyncio.run(main())
    print("PASS task_queue")

def test_flags():
    f = FeatureFlags()
    os.environ["FLAG_NEWUI"] = "true"
    assert f.enabled("newui") and not f.enabled("ghost")
    f.set("ghost", True); assert f.enabled("ghost")
    assert f.all().get("newui") is True
    print("PASS flags")


if __name__ == "__main__":
    test_config(); test_secrets(); test_metrics(); test_retry(); test_retry_async()
    test_cache(); test_rate_limiter(); test_task_queue(); test_flags()
    print("\nAll infrastructure tests passed!")
