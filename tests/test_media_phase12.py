"""Phase 12 multimodal tests — offline, fake providers, zero network."""
import base64, io, os, sys, types
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Stub optional heavy deps so tests run on any machine (Colab/CI/local)
for _name in ("loguru", "dotenv", "chromadb"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            _m = types.ModuleType(_name)
            if _name == "loguru":
                class _L:
                    def __getattr__(self, k): return lambda *a, **kw: None
                _m.logger = _L()
            if _name == "dotenv":
                _m.load_dotenv = lambda *a, **kw: None
            sys.modules[_name] = _m

# Ensure no provider keys leak in from the environment
for _k in ("GEMINI_KEY", "GEMINI_API_KEY", "OPENAI_KEY", "OPENAI_API_KEY",
           "ANTHROPIC_KEY", "ANTHROPIC_API_KEY", "GROQ_KEY", "GROQ_API_KEY",
           "STABILITY_KEY"):
    os.environ.pop(_k, None)

from tools.media.vision_tool import VisionTool
from tools.media.tts_tool import TTSTool
from tools.media.image_gen_tool import ImageGenTool
from config.settings import WORKSPACE_DIR

# 1x1 transparent PNG
_PNG_B64 = ("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4"
            "2mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=")


def test_vision_load_image_variants():
    v = VisionTool()
    raw, media = v.load_image(_PNG_B64)                      # raw base64
    assert raw[:4] == b"\x89PNG" and media == "image/png"
    raw2, media2 = v.load_image(f"data:image/png;base64,{_PNG_B64}")
    assert raw2 == raw and media2 == "image/png"             # data URL
    jpg = base64.b64encode(b"\xff\xd8\xff" + b"0" * 10).decode()
    assert v.load_image(jpg)[1] == "image/jpeg"              # magic sniff
    try:
        v.load_image("")
        assert False
    except ValueError:
        pass
    try:
        v.load_image("../../etc/passwd.png")                 # path escape
        assert False
    except (PermissionError, FileNotFoundError):
        pass
    print("PASS vision image loading")


def test_vision_no_provider_message():
    r = VisionTool().analyze(_PNG_B64)
    assert not r["success"] and "No vision-capable provider" in r["error"]
    out = VisionTool().run(image=_PNG_B64)
    assert out.startswith("Error:")
    assert VisionTool().run(image="") == \
        "Error: image required (base64, data URL, or workspace path)"
    print("PASS vision unconfigured message")


def test_vision_provider_fallback_order():
    calls = []
    v = VisionTool()
    v._gemini = staticmethod(lambda raw, m, p: (_ for _ in ()).throw(
        __import__("tools.media.vision_tool", fromlist=["_NotConfigured"])
        ._NotConfigured()))
    def fake_openai(raw, m, p):
        calls.append("openai")
        return "a tiny transparent pixel"
    v._openai = staticmethod(fake_openai)
    r = v.analyze(_PNG_B64, "what is this?")
    assert r["success"] and r["provider"] == "openai" and calls == ["openai"]
    print("PASS vision fallback order")


def test_ocr_llm_fallback_path():
    """Without pytesseract or keys, ocr() must fall through to analyze()."""
    v = VisionTool()
    seen = {}
    def fake_analyze(image, prompt):
        seen["prompt"] = prompt
        return {"success": True, "provider": "fake", "result": "HELLO"}
    v.analyze = fake_analyze
    r = v.ocr(_PNG_B64)
    assert r["result"] == "HELLO" and "Transcribe" in seen["prompt"]
    print("PASS ocr llm fallback")


def test_tts_validation_and_message():
    t = TTSTool()
    assert not t.synthesize("")["success"]
    long = "x" * 5000
    r = t.synthesize(long)
    assert not r["success"] and "too long" in r["error"]
    r = t.synthesize("hello world")
    assert not r["success"] and "No TTS provider configured" in r["error"]
    assert TTSTool().run(text="hi").startswith("Error:")
    print("PASS tts validation + message")


def test_tts_save_and_success_shape():
    t = TTSTool()
    t._openai = staticmethod(lambda text, voice: (b"FAKEMP3DATA", "mp3"))
    r = t.synthesize("bonjour", voice="nova")
    assert r["success"] and r["provider"] == "openai" and r["format"] == "mp3"
    assert os.path.isfile(r["path"]) and r["path"].endswith(".mp3")
    assert base64.b64decode(r["audio_base64"]) == b"FAKEMP3DATA"
    os.remove(r["path"])
    print("PASS tts save + shape")


def test_image_gen_saves_file():
    g = ImageGenTool()
    assert "not configured" in g.run(prompt="a cat")         # no key msg
    g.stability_key = "fake"

    class _Resp:
        status_code = 200
        def json(self):
            return {"image": _PNG_B64}
    fake_requests = types.ModuleType("requests")
    fake_requests.post = lambda *a, **kw: _Resp()
    sys.modules["requests"] = fake_requests
    try:
        out = g.run(prompt="a cat")
        assert out.startswith("Image generated and saved:")
        path = out.split(": ", 1)[1]
        assert os.path.isfile(path)
        with open(path, "rb") as f:
            assert f.read()[:4] == b"\x89PNG"
        os.remove(path)
    finally:
        # Purge requests AND its cached submodules: deleting only "requests"
        # leaves stale requests.* entries, so the next `import requests`
        # rebuilds a parent missing the `exceptions` attribute.
        for _k in [k for k in sys.modules
                   if k == "requests" or k.startswith("requests.")]:
            del sys.modules[_k]
    print("PASS image gen saves file")


test_vision_load_image_variants()
test_vision_no_provider_message()
test_vision_provider_fallback_order()
test_ocr_llm_fallback_path()
test_tts_validation_and_message()
test_tts_save_and_success_shape()
test_image_gen_saves_file()
print("\nAll multimodal tests passed")
