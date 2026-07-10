"""Phase 17 tests — streaming (router.stream_chat + provider fallback).
Offline, fake providers, no network."""
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

# Stub provider SDKs so the router imports even where they aren't installed.
for _sdk, _attr in (("groq", "Groq"), ("openai", "OpenAI"),
                    ("anthropic", "Anthropic")):
    if _sdk not in sys.modules:
        try:
            __import__(_sdk)
        except ImportError:
            _m = types.ModuleType(_sdk)
            setattr(_m, _attr, type(_attr, (), {"__init__":
                    lambda self, *a, **kw: None}))
            sys.modules[_sdk] = _m
if "google" not in sys.modules:
    try:
        import google.generativeai  # noqa: F401
    except ImportError:
        _g = types.ModuleType("google")
        _gg = types.ModuleType("google.generativeai")
        _gg.configure = lambda *a, **kw: None
        _gg.GenerativeModel = type("GenerativeModel", (), {
            "__init__": lambda self, *a, **kw: None})
        _g.generativeai = _gg
        sys.modules["google"] = _g
        sys.modules["google.generativeai"] = _gg

from llm.router import LLMRouter


class _StreamProvider:
    """Fake provider that streams word by word."""
    def stream_chat(self, messages, model=None, max_tokens=4000):
        for w in ["Hello", " ", "world", "!"]:
            yield w

    def chat(self, messages, model=None, max_tokens=4000):
        return "Hello world!"


class _NonStreamProvider:
    """Fake provider WITHOUT stream_chat — must degrade gracefully."""
    def chat(self, messages, model=None, max_tokens=4000):
        return "whole answer at once"


class _BrokenProvider:
    def stream_chat(self, messages, model=None, max_tokens=4000):
        raise RuntimeError("provider exploded")
        yield  # pragma: no cover

    def chat(self, messages, model=None, max_tokens=4000):
        raise RuntimeError("provider exploded")


def _router_with(providers, healthy):
    r = LLMRouter()
    r.providers = providers
    r._is_healthy = lambda p: p in healthy
    r._select_best_provider = lambda task_type="general": (
        healthy[0] if healthy else None)
    r.DEFAULT_PRIORITY = list(providers.keys())
    return r


def test_native_streaming_chunks():
    r = _router_with({"groq": _StreamProvider()}, ["groq"])
    chunks = list(r.stream_chat([{"role": "user", "content": "hi"}]))
    assert chunks == ["Hello", " ", "world", "!"]
    assert "".join(chunks) == "Hello world!"
    print("PASS native streaming yields token chunks")


def test_non_streaming_provider_degrades():
    r = _router_with({"x": _NonStreamProvider()}, ["x"])
    chunks = list(r.stream_chat([{"role": "user", "content": "hi"}]))
    assert chunks == ["whole answer at once"]     # single chunk fallback
    print("PASS non-streaming provider degrades to one chunk")


def test_stream_fallback_to_next_provider():
    r = _router_with(
        {"broken": _BrokenProvider(), "groq": _StreamProvider()},
        ["broken", "groq"])
    # selected=broken fails mid-stream -> should fall back to groq
    chunks = list(r.stream_chat([{"role": "user", "content": "hi"}]))
    assert "".join(chunks) == "Hello world!"
    print("PASS stream falls back to next healthy provider")


def test_stream_all_fail_raises():
    r = _router_with({"broken": _BrokenProvider()}, ["broken"])
    try:
        list(r.stream_chat([{"role": "user", "content": "hi"}]))
        assert False, "should raise when all providers fail"
    except Exception as e:
        assert "All providers failed" in str(e)
    print("PASS stream raises when all providers fail")


def test_stream_no_provider():
    r = _router_with({}, [])
    try:
        list(r.stream_chat([{"role": "user", "content": "hi"}]))
        assert False
    except Exception as e:
        assert "No LLM provider available" in str(e)
    print("PASS stream raises with no provider")


def test_success_stats_updated():
    r = _router_with({"groq": _StreamProvider()}, ["groq"])
    before = r.successful_requests
    list(r.stream_chat([{"role": "user", "content": "hi"}]))
    assert r.successful_requests == before + 1
    print("PASS streaming updates success stats")


test_native_streaming_chunks()
test_non_streaming_provider_degrades()
test_stream_fallback_to_next_provider()
test_stream_all_fail_raises()
test_stream_no_provider()
test_success_stats_updated()
print("\nAll streaming tests passed")
