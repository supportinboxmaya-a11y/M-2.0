"""Maya 2.0 - JSON Tool (read/write/query JSON files, workspace-scoped)"""
import json
from .safe_path import resolve_safe_path


class JsonTool:
    def read(self, filename: str, path_query: str = "", **kwargs) -> str:
        """path_query: dot-separated path like 'users.0.name' to drill into the JSON."""
        try:
            fpath = resolve_safe_path(filename)
            if not fpath.exists():
                return f"Error: file not found: {filename}"
            with open(fpath, encoding="utf-8") as f:
                data = json.load(f)
            if path_query:
                data = self._drill(data, path_query)
                if data is None:
                    return f"Error: path '{path_query}' not found"
            return json.dumps(data, indent=2, ensure_ascii=False)
        except ValueError as e:
            return f"Error: {e}"
        except json.JSONDecodeError as e:
            return f"Error: invalid JSON in file ({e})"
        except Exception as e:
            return f"Error: could not read JSON ({e})"

    def write(self, filename: str, data, **kwargs) -> str:
        try:
            fpath = resolve_safe_path(filename)
            fpath.parent.mkdir(parents=True, exist_ok=True)
            with open(fpath, "w", encoding="utf-8") as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            return f"Wrote JSON to {filename}"
        except ValueError as e:
            return f"Error: {e}"
        except (TypeError, OverflowError) as e:
            return f"Error: data is not JSON-serializable ({e})"
        except Exception as e:
            return f"Error: could not write JSON ({e})"

    def _drill(self, data, path_query: str):
        current = data
        for part in path_query.split("."):
            if isinstance(current, list):
                try:
                    current = current[int(part)]
                except (ValueError, IndexError):
                    return None
            elif isinstance(current, dict):
                if part not in current:
                    return None
                current = current[part]
            else:
                return None
        return current
