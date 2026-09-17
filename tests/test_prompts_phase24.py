"""Phase 24 tests — prompt library (templates, variables, render, versions).
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

from infrastructure.prompt_library import PromptLibrary

_tmp = tempfile.mkdtemp(prefix="maya_prompt24_")


def _lib(tag):
    return PromptLibrary(db_path=os.path.join(_tmp, f"p_{tag}.db"))


def test_variable_extraction():
    ex = PromptLibrary.extract_variables
    assert ex("Summarize {{text}} in {{n}} points") == ["text", "n"]
    assert ex("no vars here") == []
    # duplicates collapse, order preserved
    assert ex("{{a}} {{b}} {{a}}") == ["a", "b"]
    print("PASS variable extraction")


def test_create_derives_variables():
    lib = _lib("create")
    p = lib.create("Summary", "Summarize {{text}} into {{n}} bullets",
                   description="quick summary", category="writing",
                   tags=["summary"])
    names = [v["name"] for v in p["variables"]]
    assert names == ["text", "n"]
    assert all(v["required"] for v in p["variables"])   # no defaults -> required
    assert p["category"] == "writing" and p["uses"] == 0
    print("PASS create derives variables")


def test_create_with_defaults():
    lib = _lib("defaults")
    p = lib.create("Greet", "Say hello in {{lang}}",
                   variables=[{"name": "lang", "default": "English",
                               "description": "language"}])
    var = p["variables"][0]
    assert var["default"] == "English" and var["required"] is False
    print("PASS create with variable defaults")


def test_render_fills_and_counts():
    lib = _lib("render")
    p = lib.create("T", "Translate {{text}} to {{lang}}")
    out = lib.render(p["id"], {"text": "hello", "lang": "Bangla"})
    assert out == "Translate hello to Bangla"
    assert lib.get(p["id"])["uses"] == 1          # usage counted
    print("PASS render fills + counts use")


def test_render_missing_required_raises():
    lib = _lib("missing")
    p = lib.create("T", "Do {{action}} on {{target}}")
    try:
        lib.render(p["id"], {"action": "review"})    # target missing
        assert False
    except ValueError as e:
        assert "target" in str(e)
    print("PASS render missing required raises")


def test_render_uses_defaults():
    lib = _lib("rdefault")
    p = lib.create("Bullets", "Summarize {{text}} in {{n}} points",
                   variables=[{"name": "n", "default": "3"}])
    out = lib.render(p["id"], {"text": "the doc"})   # n falls back to 3
    assert out == "Summarize the doc in 3 points"
    print("PASS render uses defaults")


def test_update_versions_body():
    lib = _lib("version")
    p = lib.create("V", "First version {{x}}")
    up = lib.update(p["id"], body="Second version {{x}} and {{y}}")
    assert up["version"] == 2
    names = [v["name"] for v in up["variables"]]
    assert names == ["x", "y"]                       # re-derived
    hist = lib.history(p["id"])
    assert len(hist) == 1 and "First version" in hist[0]["body"]
    print("PASS update versions body + keeps history")


def test_update_metadata_only_no_version_bump():
    lib = _lib("meta")
    p = lib.create("M", "Body {{a}}")
    up = lib.update(p["id"], name="Renamed", category="ops")
    assert up["version"] == 1 and up["name"] == "Renamed"
    assert up["category"] == "ops"
    print("PASS metadata update doesn't bump version")


def test_list_search_categories_delete():
    lib = _lib("list")
    lib.create("Alpha", "about cats {{x}}", category="animals")
    lib.create("Beta", "about dogs {{x}}", category="animals")
    p3 = lib.create("Gamma", "about rockets {{x}}", category="space")
    assert len(lib.list(category="animals")) == 2
    assert len(lib.list(query="rockets")) == 1
    cats = {c["category"]: c["count"] for c in lib.categories()}
    assert cats["animals"] == 2 and cats["space"] == 1
    assert lib.delete(p3["id"]) is True
    assert lib.get(p3["id"]) is None
    print("PASS list/search/categories/delete")


def test_persistence_across_instances():
    db = os.path.join(_tmp, "persist.db")
    l1 = PromptLibrary(db_path=db)
    p = l1.create("Keep", "keep {{x}}")
    l2 = PromptLibrary(db_path=db)
    assert l2.get(p["id"])["name"] == "Keep"
    print("PASS prompts persist across instances")


if __name__ == "__main__":
    try:
        test_variable_extraction()
        test_create_derives_variables()
        test_create_with_defaults()
        test_render_fills_and_counts()
        test_render_missing_required_raises()
        test_render_uses_defaults()
        test_update_versions_body()
        test_update_metadata_only_no_version_bump()
        test_list_search_categories_delete()
        test_persistence_across_instances()
        print("\nAll prompt-library tests passed")
    finally:
        shutil.rmtree(_tmp, ignore_errors=True)
