"""Maya 2.0 - CSV Tool (read/write CSV files, workspace-scoped)"""
import csv
from .safe_path import resolve_safe_path


class CsvTool:
    def read(self, filename: str, limit: int = 100, **kwargs) -> str:
        try:
            path = resolve_safe_path(filename)
            if not path.exists():
                return f"Error: file not found: {filename}"
            with open(path, newline="", encoding="utf-8") as f:
                reader = csv.DictReader(f)
                rows = []
                for i, row in enumerate(reader):
                    if i >= limit:
                        break
                    rows.append(row)
            if not rows:
                return "(empty or header-only CSV)"
            headers = list(rows[0].keys())
            lines = [", ".join(headers)]
            for r in rows:
                lines.append(", ".join(str(r.get(h, "")) for h in headers))
            return "\n".join(lines)
        except ValueError as e:
            return f"Error: {e}"
        except csv.Error as e:
            return f"Error: malformed CSV ({e})"
        except Exception as e:
            return f"Error: could not read CSV ({e})"

    def write(self, filename: str, rows: list, headers: list = None, **kwargs) -> str:
        if not rows:
            return "Error: no rows provided"
        try:
            path = resolve_safe_path(filename)
            path.parent.mkdir(parents=True, exist_ok=True)
            cols = headers or (list(rows[0].keys()) if isinstance(rows[0], dict) else None)
            if not cols:
                return "Error: could not determine CSV headers - provide 'headers' or use dict rows"
            with open(path, "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=cols)
                writer.writeheader()
                for r in rows:
                    writer.writerow(r if isinstance(r, dict) else dict(zip(cols, r)))
            return f"Wrote {len(rows)} row(s) to {filename}"
        except ValueError as e:
            return f"Error: {e}"
        except Exception as e:
            return f"Error: could not write CSV ({e})"
