"""
Maya 2.0 - Plugin Loader
--------------------------
Dynamically load new skills and tools without changing core code.
"""

import os
import sys
import importlib
import importlib.util
from typing import Dict, List, Optional, Callable
from pathlib import Path
from maya_logging.logger import get_logger

log = get_logger("plugins")


class PluginLoader:
    """
    Maya-র plugin system.
    - Runtime এ নতুন skills/tools load করে
    - Plugin validate করে
    - Plugin registry maintain করে
    - Hot reload support করে
    """

    def __init__(self, plugins_dir: str = None, tool_registry=None):
        self.plugins_dir = Path(plugins_dir or Path(__file__).parent.parent / "plugins")
        self.plugins_dir.mkdir(parents=True, exist_ok=True)
        self.tool_registry = tool_registry
        self.loaded_plugins: Dict[str, Dict] = {}
        # api.py's toggle/uninstall endpoints called set_enabled()/uninstall()
        # as if they already existed here — they didn't, so every toggle or
        # delete attempt on the Plugins page crashed with a 500 error.
        self._enabled_state: Dict[str, bool] = {}

    def load_all(self) -> int:
        """plugins/ folder থেকে সব plugins load করে।"""
        count = 0
        for file in self.plugins_dir.glob("*.py"):
            if file.name.startswith("_"):
                continue
            if self.load_plugin(str(file)):
                count += 1
        log.info(f"Loaded {count} plugins from {self.plugins_dir}")
        return count

    def load_plugin(self, path: str) -> bool:
        """Single plugin file load করে।"""
        try:
            plugin_path = Path(path)
            plugin_name = plugin_path.stem

            spec = importlib.util.spec_from_file_location(plugin_name, plugin_path)
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)

            # Plugin validate করি
            if not self._validate_plugin(module, plugin_name):
                return False

            # Plugin register করি
            plugin_info = {
                "name": plugin_name,
                "path": str(plugin_path),
                "module": module,
                "description": getattr(module, "DESCRIPTION", ""),
                "version": getattr(module, "VERSION", "1.0"),
                "tools": getattr(module, "TOOLS", []),
            }

            self.loaded_plugins[plugin_name] = plugin_info

            # Tool registry তে register করি — track which tools this
            # plugin adds so we can cleanly unregister them later.
            registered = []
            if self.tool_registry and hasattr(module, "register_tools"):
                before = set(getattr(self.tool_registry, "_tools", {}).keys())
                module.register_tools(self.tool_registry)
                after = set(getattr(self.tool_registry, "_tools", {}).keys())
                registered = sorted(after - before)
                log.info(f"Plugin loaded: {plugin_name} v{plugin_info['version']}")
            plugin_info["registered_tools"] = registered

            return True

        except Exception as e:
            log.error(f"Failed to load plugin {path}: {e}")
            return False

    def reload_plugin(self, plugin_name: str) -> bool:
        """Plugin hot reload করে।"""
        if plugin_name not in self.loaded_plugins:
            log.warning(f"Plugin not found: {plugin_name}")
            return False

        path = self.loaded_plugins[plugin_name]["path"]
        del self.loaded_plugins[plugin_name]
        return self.load_plugin(path)

    def list_plugins(self) -> List[Dict]:
        """Loaded plugins এর list।"""
        return [
            {
                "name": p["name"],
                "description": p["description"],
                "version": p["version"],
                "tools": p["tools"],
                "enabled": self._enabled_state.get(p["name"], True),
            }
            for p in self.loaded_plugins.values()
        ]

    def set_enabled(self, name: str, enabled: bool) -> bool:
        """Enable/disable a plugin AND its tools. Disabling now actually
        unregisters the plugin's tools from the registry (ToolRegistry
        gained unregister()), so a disabled plugin's tools are no longer
        callable. Re-enabling re-runs the plugin's register_tools()."""
        info = self.loaded_plugins.get(name)
        if info is None:
            return False
        enabled = bool(enabled)
        currently = self._enabled_state.get(name, True)
        if enabled == currently:
            self._enabled_state[name] = enabled
            return True
        if not enabled:
            self._unregister_plugin_tools(info)
        else:
            module = info.get("module")
            if self.tool_registry and module and hasattr(module, "register_tools"):
                before = set(getattr(self.tool_registry, "_tools", {}).keys())
                try:
                    module.register_tools(self.tool_registry)
                except Exception as e:
                    log.warning(f"Re-enable failed for {name}: {e}")
                    return False
                after = set(getattr(self.tool_registry, "_tools", {}).keys())
                info["registered_tools"] = sorted(after - before)
        self._enabled_state[name] = enabled
        return True

    def _unregister_plugin_tools(self, info: Dict) -> int:
        """Retract every tool a plugin registered. Returns how many."""
        removed = 0
        if self.tool_registry and hasattr(self.tool_registry, "unregister"):
            for tool_name in info.get("registered_tools", []):
                if self.tool_registry.unregister(tool_name):
                    removed += 1
        return removed

    def install(self, name: str) -> bool:
        """Stub — there's no plugin catalog/marketplace in this codebase to
        install FROM yet, so this can't actually fetch and load a new
        plugin by name. Returns False rather than raising, so the endpoint
        can respond clearly instead of crashing with an AttributeError like
        it used to (this method didn't exist at all before)."""
        return False

    def uninstall(self, name: str) -> bool:
        """Remove a plugin: retract its tools from the registry, drop it
        from the loaded set, and delete its file. Tools are now actually
        unregistered (ToolRegistry.unregister), so they stop being
        callable immediately — no restart required."""
        info = self.loaded_plugins.get(name)
        if info is None:
            return False
        self._unregister_plugin_tools(info)
        path = info.get("path")
        del self.loaded_plugins[name]
        self._enabled_state.pop(name, None)
        if path:
            try:
                Path(path).unlink(missing_ok=True)
            except Exception as e:
                log.warning(f"Could not delete plugin file {path}: {e}")
        return True

    def install_from_code(self, name: str, code: str) -> Dict:
        """Install a plugin from source code: validate it parses, write it
        to the plugins dir, and load it. Gives the API a real install path
        (the old install() had nothing to install from). Raises ValueError
        on bad input."""
        import ast as _ast
        safe = "".join(ch for ch in (name or "") if ch.isalnum() or ch in "_-")
        if not safe:
            raise ValueError("invalid plugin name")
        if not code or not code.strip():
            raise ValueError("plugin code is empty")
        try:
            _ast.parse(code)
        except SyntaxError as e:
            raise ValueError(f"plugin code has a syntax error: {e}")
        if "register_tools" not in code:
            raise ValueError("plugin must define a register_tools(registry) function")
        target = self.plugins_dir / f"{safe}.py"
        target.write_text(code, encoding="utf-8")
        if not self.load_plugin(str(target)):
            try:
                target.unlink()
            except Exception:
                pass
            raise ValueError("plugin failed to load")
        return self.loaded_plugins.get(safe, {"name": safe})

    def get_plugin(self, name: str) -> Optional[Dict]:
        return self.loaded_plugins.get(name)

    def _validate_plugin(self, module, name: str) -> bool:
        """Plugin valid কিনা check করে।"""
        if not hasattr(module, "DESCRIPTION"):
            log.warning(f"Plugin {name} missing DESCRIPTION")
        return True


class PluginTemplate:
    """
    নতুন plugin বানানোর template।
    এই format follow করে plugin বানাও।
    """
    TEMPLATE = '''"""
Maya 2.0 Plugin: {name}
"""

DESCRIPTION = "{description}"
VERSION = "1.0"
TOOLS = ["{tool_name}"]


def {tool_name}(query: str) -> str:
    """
    Tool implementation.
    """
    # Your code here
    return f"Result for: {query}"


def register_tools(registry):
    """Tool registry তে register করে।"""
    registry.register(
        name="{tool_name}",
        func={tool_name},
        description="{description}",
        category="plugin"
    )
'''

    @classmethod
    def create(cls, name: str, description: str, tool_name: str, output_dir: str = None) -> str:
        """নতুন plugin file তৈরি করে।"""
        content = cls.TEMPLATE.format(
            name=name,
            description=description,
            tool_name=tool_name
        )
        output_path = Path(output_dir or ".") / f"{name}.py"
        output_path.write_text(content)
        return str(output_path)
