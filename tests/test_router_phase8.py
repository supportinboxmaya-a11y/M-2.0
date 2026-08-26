"""Phase 8 Router+ tests — offline."""
import os, sys, time, types
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# stub optional deps if missing (config/dotenv + provider SDKs via llm/__init__)
def _stub(name, **attrs):
    try:
        __import__(name)
    except ImportError:
        parts = name.split(".")
        for i in range(1, len(parts) + 1):
            mod_name = ".".join(parts[:i])
            if mod_name not in sys.modules:
                sys.modules[mod_name] = types.ModuleType(mod_name)
        for k, v in attrs.items():
            setattr(sys.modules[name], k, v)

_stub("dotenv", load_dotenv=lambda *a, **k: None)
class _FakeClient:
    def __init__(self, *a, **k): pass
_stub("groq", Groq=_FakeClient)
_stub("openai", OpenAI=_FakeClient)
_stub("anthropic", Anthropic=_FakeClient)
_stub("google.generativeai", configure=lambda **k: None,
      GenerativeModel=_FakeClient)
_stub("loguru")
if not hasattr(sys.modules.get("loguru", types.ModuleType("x")), "logger"):
    class _L:
        def __getattr__(self, k): return lambda *a, **kw: None
    sys.modules["loguru"].logger = _L()

from llm.router_plus import ProviderStats, SmartSelector, RouterPlus, PROVIDER_TABLE
from llm.providers.openrouter import OpenRouterProvider


def test_set_key_revives_provider():
    """Regression (live validation, 2026-08): set_key hardcoded
    health['available']=False and nothing ever reset it, so after a
    key rotation the provider stayed unhealthy forever and the router
    could report 'No LLM provider available' with valid keys restored."""
    from llm.router import LLMRouter
    r = LLMRouter()
    prov = "openrouter"
    assert prov in r.providers
    # Simulate an unhealthy provider (as after repeated failures).
    r.health[prov]["error_count"] = 9
    assert not r._is_healthy(prov)
    # Rotating the key must fully revive it: fresh availability,
    # error_count reset.
    ok = r.set_key(prov, "sk-or-test-key")
    assert ok is True
    assert r.health[prov]["error_count"] == 0
    assert r._is_healthy(prov) is True
    print("PASS set_key revival")


def test_cooldown_revives_throttled_provider():
    """Regression (live push validation, 2026-08): 5 rapid 429s set
    health['available']=False permanently — no time-based recovery — so
    even long operator backoffs couldn't revive a throttled free tier
    mid-process. After PROVIDER_COOLDOWN since the last error, the
    provider must get a fresh start."""
    import time as _time
    from llm.router import LLMRouter
    r = LLMRouter()
    prov = "openrouter"
    assert prov in r.health
    # Simulate a 429 burst that tripped the circuit breaker.
    for _ in range(5):
        r._update_health(prov, success=False, error="429 rate limited")
    assert r.health[prov]["available"] is False
    assert not r._is_healthy(prov)
    # Within the cooldown window: still unhealthy.
    r.health[prov]["last_error_ts"] = _time.time() - (
        r.PROVIDER_COOLDOWN / 2)
    assert not r._is_healthy(prov)
    # After the cooldown window: revived (error_count reset).
    r.health[prov]["last_error_ts"] = _time.time() - (
        r.PROVIDER_COOLDOWN + 1)
    assert r._is_healthy(prov) is True
    assert r.health[prov]["error_count"] == 0
    print("PASS cooldown revival")


def test_stats():
    s = ProviderStats(alpha=0.5)
    s.record("groq", 1.0, True); s.record("groq", 2.0, True)
    assert abs(s.latency("groq") - 1.5) < 1e-9            # EMA
    s.record("groq", 1.0, False)
    assert abs(s.error_rate("groq") - 1/3) < 1e-9
    snap = s.snapshot()
    assert snap["groq"]["ok"] == 2 and snap["groq"]["errors"] == 1
    assert s.error_rate("never_used") == 0.0
    print("PASS stats")


def test_selector_strategies():
    sel = SmartSelector()
    avail = ["claude", "groq", "openai", "local"]
    assert sel.order(avail, "cost")[0] == "local"          # cheapest first
    assert sel.order(avail, "quality")[0] == "claude"      # best first
    bal = sel.order(avail, "balanced")
    assert bal[0] in ("local", "groq")                     # value picks
    # latency strategy uses observed EMA
    sel.stats.record("openai", 0.2, True)
    sel.stats.record("groq", 3.0, True)
    assert sel.order(["openai", "groq"], "latency")[0] == "openai"
    print("PASS selector")


def test_selector_skips_unhealthy():
    sel = SmartSelector(max_error_rate=0.4)
    for _ in range(3):
        sel.stats.record("groq", 1.0, False)               # 100% errors
    sel.stats.record("gemini", 1.0, True)
    order = sel.order(["groq", "gemini"], "cost")
    assert order[0] == "gemini" and "groq" not in order
    # but if ALL are unhealthy, still return them (never empty)
    order2 = sel.order(["groq"], "cost")
    assert order2 == ["groq"]
    print("PASS unhealthy_skip")


def test_fallback_chain():
    rp = RouterPlus(retries_per_provider=2)
    calls = []
    def call_fn(provider, prompt):
        calls.append(provider)
        if provider == "local":
            raise RuntimeError("local model down")
        return f"{provider} says: {prompt}"
    res = rp.call(["local", "groq"], call_fn, "hello", strategy="cost")
    assert res["ok"] and res["provider"] == "groq"
    assert calls.count("local") == 2                        # retried before fallback
    assert "local" in res["tried"]
    assert rp.stats.error_rate("local") == 1.0
    # all fail
    def all_fail(p, x): raise RuntimeError("nope")
    res2 = RouterPlus().call(["groq"], all_fail, "x")
    assert not res2["ok"] and "nope" in res2["error"]
    res3 = RouterPlus().call([], all_fail, "x")
    assert not res3["ok"]
    print("PASS fallback_chain")


def test_openrouter():
    os.environ.pop("OPENROUTER_KEY", None); os.environ.pop("OPENROUTER_API_KEY", None)
    assert OpenRouterProvider().is_available() is False
    os.environ["OPENROUTER_API_KEY"] = "sk-or-test"
    assert OpenRouterProvider().is_available() is True
    captured = {}
    def fake_http(url, payload, key):
        captured.update(url=url, payload=payload, key=key)
        return {"choices": [{"message": {"content": "hi from openrouter"}}]}
    p = OpenRouterProvider(http_fn=fake_http)
    out = p.chat([{"role": "user", "content": "hello"}])
    assert out == "hi from openrouter"
    assert captured["key"] == "sk-or-test"
    # Default free-tier model (llama-3.3 :free was retired by OpenRouter;
    # nemotron-3-super verified live 2026-08). Must stay a :free slug.
    assert captured["payload"]["model"].endswith(":free")
    assert "openrouter" in PROVIDER_TABLE
    os.environ.pop("OPENROUTER_API_KEY", None)
    print("PASS openrouter")


if __name__ == "__main__":
    test_stats(); test_selector_strategies(); test_selector_skips_unhealthy()
    test_fallback_chain(); test_openrouter(); test_set_key_revival()
    test_cooldown_revives_throttled_provider()
    print("\nAll Phase 8 router tests passed!")
