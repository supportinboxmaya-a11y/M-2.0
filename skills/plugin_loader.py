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

            # Tool registry তে register করি
            if self.tool_registry and hasattr(module, "register_tools"):
                module.register_tools(self.tool_registry)
                log.info(f"Plugin loaded: {plugin_name} v{plugin_info['version']}")

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
                "tools": p["tools"]
            }
            for p in self.loaded_plugins.values()
        ]

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
