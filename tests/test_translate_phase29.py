"""Phase 29 tests — live translation (detection + LLM-backed translate).
Offline, fake chat_fn, no network."""
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

from tools.media.translator import Translator, SUPPORTED


def test_detect_scripts():
    d = Translator.detect
    assert d("Hello world") == "en"
    assert d("আমি ভালো আছি") == "bn"          # Bengali
    assert d("नमस्ते दुनिया") == "hi"           # Devanagari
    assert d("مرحبا بالعالم") == "ar"          # Arabic
    assert d("你好世界") == "zh"                 # Chinese
    assert d("こんにちは") == "ja"               # Japanese
    assert d("안녕하세요") == "ko"               # Korean
    assert d("Привет мир") == "ru"             # Cyrillic
    assert d("") == "en"                        # empty -> default
    print("PASS script detection")


def test_mixed_script_picks_dominant():
    # Bengali-dominant with a couple Latin words -> bn
    assert Translator.detect("আমি office যাচ্ছি এখন তাড়াতাড়ি") == "bn"
    print("PASS mixed script picks dominant")


def test_normalize_code_or_name():
    n = Translator._normalize
    assert n("bn") == "bn"
    assert n("Bengali") == "bn"
    assert n("bengali") == "bn"
    assert n("ENGLISH") == "en"
    assert n("klingon") is None
    assert n("") is None
    print("PASS normalize code or name")


def test_supported_languages_list():
    t = Translator()
    langs = t.supported_languages()
    codes = {l["code"] for l in langs}
    assert "en" in codes and "bn" in codes
    assert len(langs) == len(SUPPORTED)
    print("PASS supported languages list")


def test_translate_calls_chat():
    seen = {}
    def chat_fn(messages):
        seen["messages"] = messages
        return "আমি ভালো আছি"
    t = Translator(chat_fn=chat_fn)
    res = t.translate("I am fine", target="bn")
    assert res["source"] == "en" and res["target"] == "bn"
    assert res["source_name"] == "English" and res["target_name"] == "Bengali"
    assert res["translation"] == "আমি ভালো আছি"
    # prompt mentions both languages
    prompt = seen["messages"][-1]["content"]
    assert "English" in prompt and "Bengali" in prompt
    print("PASS translate calls chat with correct prompt")


def test_translate_strips_quotes():
    t = Translator(chat_fn=lambda m: '"Bonjour"')
    res = t.translate("Hello", target="fr")
    assert res["translation"] == "Bonjour"      # surrounding quotes stripped
    print("PASS translate strips stray quotes")


def test_same_language_short_circuits():
    calls = []
    t = Translator(chat_fn=lambda m: calls.append(1) or "x")
    res = t.translate("Hello world", target="en")   # already English
    assert res["translation"] == "Hello world"
    assert res.get("note") == "already in target language"
    assert calls == []                          # no LLM call needed
    print("PASS same-language short-circuit")


def test_translate_validation():
    t = Translator(chat_fn=lambda m: "x")
    try:
        t.translate("", target="bn"); assert False
    except ValueError: pass
    try:
        t.translate("hi", target="klingon"); assert False
    except ValueError: pass
    print("PASS translate validation")


def test_explicit_source_overrides_detection():
    t = Translator(chat_fn=lambda m: "translated")
    # force source=fr even though text is Latin/english-looking
    res = t.translate("bonjour", target="en", source="fr")
    assert res["source"] == "fr" and res["source_name"] == "French"
    print("PASS explicit source overrides detection")


def test_no_chat_fn_degrades():
    t = Translator(chat_fn=None)
    res = t.translate("hello", target="bn")
    assert "no translator configured" in res["translation"]
    print("PASS no chat_fn degrades gracefully")


test_detect_scripts()
test_mixed_script_picks_dominant()
test_normalize_code_or_name()
test_supported_languages_list()
test_translate_calls_chat()
test_translate_strips_quotes()
test_same_language_short_circuits()
test_translate_validation()
test_explicit_source_overrides_detection()
test_no_chat_fn_degrades()
print("\nAll translation tests passed")
