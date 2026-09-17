"""Phase 25 tests — plugin system: registry unregister + plugin loader
tool retraction + install-from-code. Offline, temp plugins dir."""
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

from tools.registry import ToolRegistry
from skills.plugin_loader import PluginLoader

_tmp = tempfile.mkdtemp(prefix="maya_plugin25_")

# A minimal valid plugin defining one tool.
_PLUGIN_CODE = '''
DESCRIPTION = "test plugin"
VERSION = "1.0"
TOOLS = ["shout"]

def shout(text: str) -> str:
    return text.upper()

def register_tools(registry):
    registry.register("shout", shout, "uppercases text", category="plugin")
'''


# ── registry.unregister ───────────────────────────────────────────
def test_registry_unregister():
    reg = ToolRegistry()
    reg.register("t1", lambda: "x", "desc", category="plugin")
    assert reg.has("t1")
    assert reg.run("t1") == "x"
    assert reg.unregister("t1") is True
    assert not reg.has("t1")
    assert reg.unregister("t1") is False       # already gone
    try:
        reg.run("t1")
        assert False, "calling an unregistered tool should raise"
    except ValueError:
        pass
    print("PASS registry unregister makes tool uncallable")


def test_names_in_category():
    reg = ToolRegistry()
    reg.register("a", lambda: 1, category="plugin")
    reg.register("b", lambda: 2, category="plugin")
    reg.register("c", lambda: 3, category="core")
    assert set(reg.names_in_category("plugin")) == {"a", "b"}
    print("PASS names_in_category")


def _loader():
    return PluginLoader(plugins_dir=os.path.join(_tmp, os.urandom(3).hex()),
                        tool_registry=ToolRegistry())


# ── install-from-code ─────────────────────────────────────────────
def test_install_from_code_registers_tool():
    pl = _loader()
    info = pl.install_from_code("shouter", _PLUGIN_CODE)
    assert info["name"] == "shouter"
    assert "shout" in info["registered_tools"]
    assert pl.tool_registry.has("shout")
    assert pl.tool_registry.run("shout", {"text": "hi"}) == "HI"
    print("PASS install-from-code registers tool")


def test_install_validation():
    pl = _loader()
    for name, code, err in [
        ("", _PLUGIN_CODE, "invalid plugin name"),
        ("x", "", "empty"),
        ("x", "def foo(:\n pass", "syntax error"),
        ("x", "DESCRIPTION='no register fn'", "register_tools"),
    ]:
        try:
            pl.install_from_code(name, code)
            assert False, f"should reject: {err}"
        except ValueError as e:
            assert err in str(e)
    print("PASS install-from-code validation")


def test_disable_retracts_tools():
    pl = _loader()
    pl.install_from_code("shouter", _PLUGIN_CODE)
    assert pl.tool_registry.has("shout")
    # disable -> tool must be gone
    assert pl.set_enabled("shouter", False) is True
    assert not pl.tool_registry.has("shout")
    # re-enable -> tool back
    assert pl.set_enabled("shouter", True) is True
    assert pl.tool_registry.has("shout")
    print("PASS disable retracts tools, re-enable restores")


def test_uninstall_retracts_and_deletes():
    pl = _loader()
    info = pl.install_from_code("shouter", _PLUGIN_CODE)
    path = pl.get_plugin("shouter")["path"]
    assert os.path.exists(path)
    assert pl.uninstall("shouter") is True
    assert not pl.tool_registry.has("shout")       # tool retracted
    assert not os.path.exists(path)                # file deleted
    assert pl.get_plugin("shouter") is None
    assert pl.uninstall("shouter") is False        # already gone
    print("PASS uninstall retracts tools + deletes file")


def test_list_reflects_enabled_state():
    pl = _loader()
    pl.install_from_code("shouter", _PLUGIN_CODE)
    pl.set_enabled("shouter", False)
    listed = {p["name"]: p for p in pl.list_plugins()}
    assert listed["shouter"]["enabled"] is False
    print("PASS list reflects enabled state")


try:
    test_registry_unregister()
    test_names_in_category()
    test_install_from_code_registers_tool()
    test_install_validation()
    test_disable_retracts_tools()
    test_uninstall_retracts_and_deletes()
    test_list_reflects_enabled_state()
    print("\nAll plugin-system tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
