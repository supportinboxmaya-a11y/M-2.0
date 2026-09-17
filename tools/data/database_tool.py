"""
Maya 2.0 - Database Tool

Gives the agent its own SQLite database to create tables and store/query
structured data in — deliberately a SEPARATE file from Maya's internal app
databases (auth, memory, tasks). Whatever SQL the agent runs here can never
reach those, regardless of what a goal or prompt injection tries.
"""
import sqlite3
from pathlib import Path
from config.settings import WORKSPACE_DIR


class DatabaseTool:
    def __init__(self):
        self.db_path = Path(WORKSPACE_DIR) / "agent_data.db"

    def run_query(self, query: str, params: list = None, **kwargs) -> str:
        if not query or not query.strip():
            return "Error: query required"
        try:
            conn = sqlite3.connect(self.db_path)
            conn.row_factory = sqlite3.Row
            cur = conn.execute(query, params or [])
            if query.strip().upper().startswith(("SELECT", "PRAGMA")):
                rows = cur.fetchall()
                conn.close()
                if not rows:
                    return "(no rows)"
                headers = rows[0].keys()
                lines = [", ".join(headers)]
                for r in rows:
                    lines.append(", ".join(str(v) for v in r))
                return "\n".join(lines)
            else:
                conn.commit()
                affected = cur.rowcount
                conn.close()
                return f"Query executed. Rows affected: {affected}"
        except sqlite3.Error as e:
            return f"Error: SQL error ({e})"
        except Exception as e:
            return f"Error: {e}"

    def list_tables(self, **kwargs) -> str:
        return self.run_query("SELECT name FROM sqlite_master WHERE type='table'")
