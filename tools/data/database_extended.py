"""
Maya 2.0 - Extended Database Management Tools
Provides additional SQLite management capabilities beyond basic query.
"""

import sqlite3
import shutil
import os
from pathlib import Path
from config.settings import WORKSPACE_DIR


class DatabaseExtendedTool:
    def __init__(self):
        self.db_path = Path(WORKSPACE_DIR) / "agent_data.db"
        self.backup_dir = Path(WORKSPACE_DIR) / "backups"
        self.backup_dir.mkdir(exist_ok=True)

    def _get_connection(self):
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn

    def execute_sql(self, query: str, params: list = None) -> dict:
        """Execute any SQL statement (INSERT, UPDATE, DELETE, CREATE, etc.)."""
        if not query or not query.strip():
            return {"success": False, "error": "query required"}
        try:
            conn = self._get_connection()
            cur = conn.execute(query, params or [])
            if query.strip().upper().startswith(("SELECT", "PRAGMA", "EXPLAIN")):
                rows = cur.fetchall()
                conn.close()
                if not rows:
                    return {"success": True, "rows": [], "columns": []}
                columns = rows[0].keys()
                return {"success": True, "rows": [dict(r) for r in rows], "columns": list(columns)}
            else:
                conn.commit()
                affected = cur.rowcount
                conn.close()
                return {"success": True, "rows_affected": affected}
        except sqlite3.Error as e:
            return {"success": False, "error": f"SQL error: {e}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def fetch_all(self, query: str, params: list = None) -> dict:
        """Fetch all rows from a SELECT query."""
        return self.execute_sql(query, params)

    def fetch_one(self, query: str, params: list = None) -> dict:
        """Fetch a single row from a SELECT query."""
        result = self.execute_sql(query, params)
        if result.get("success") and result.get("rows"):
            result["rows"] = [result["rows"][0]]
        return result

    def backup(self, backup_name: str = "") -> dict:
        """Create a backup of the database."""
        try:
            if not backup_name:
                from datetime import datetime
                backup_name = f"agent_data_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}.db"
            elif not backup_name.endswith(".db"):
                backup_name += ".db"
            
            backup_path = self.backup_dir / backup_name
            shutil.copy2(self.db_path, backup_path)
            return {"success": True, "backup_path": str(backup_path), "size_bytes": backup_path.stat().st_size}
        except Exception as e:
            return {"success": False, "error": f"Backup failed: {e}"}

    def schema_info(self, table_name: str = "") -> dict:
        """Get schema information for tables."""
        try:
            conn = self._get_connection()
            if table_name:
                query = "SELECT sql FROM sqlite_master WHERE type='table' AND name=?"
                cur = conn.execute(query, [table_name])
            else:
                query = "SELECT name, sql FROM sqlite_master WHERE type='table'"
                cur = conn.execute(query)
            rows = cur.fetchall()
            conn.close()
            return {"success": True, "tables": [dict(r) for r in rows]}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def wal_mode_checkpoint(self) -> dict:
        """Perform WAL checkpoint for better concurrency."""
        try:
            conn = self._get_connection()
            conn.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            conn.close()
            return {"success": True, "message": "WAL checkpoint completed"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def cache_purge(self) -> dict:
        """Purge database cache and optimize."""
        try:
            conn = self._get_connection()
            conn.execute("VACUUM")
            conn.execute("ANALYZE")
            conn.close()
            return {"success": True, "message": "Database optimized and cache purged"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    # Tool registry entry points
    def db_execute_sql(self, query: str, params: list = None, **kwargs) -> str:
        result = self.execute_sql(query, params)
        if result.get("success"):
            if "rows" in result:
                if not result["rows"]:
                    return "(no rows)"
                lines = [", ".join(result["columns"])]
                for r in result["rows"]:
                    lines.append(", ".join(str(v) for v in r.values()))
                return "\n".join(lines)
            return f"Query executed. Rows affected: {result.get('rows_affected', 0)}"
        return f"Error: {result.get('error')}"

    def db_fetch_all(self, query: str, params: list = None, **kwargs) -> str:
        return self.db_execute_sql(query, params, **kwargs)

    def db_fetch_one(self, query: str, params: list = None, **kwargs) -> str:
        result = self.fetch_one(query, params)
        if result.get("success") and result.get("rows"):
            r = result["rows"][0]
            return ", ".join(f"{k}={v}" for k, v in r.items())
        return "(no rows)"

    def db_backup(self, backup_name: str = "", **kwargs) -> str:
        result = self.backup(backup_name)
        if result.get("success"):
            return f"Backup created: {result['backup_path']} ({result['size_bytes']} bytes)"
        return f"Error: {result.get('error')}"

    def db_schema_info(self, table_name: str = "", **kwargs) -> str:
        result = self.schema_info(table_name)
        if result.get("success"):
            if not result["tables"]:
                return "(no tables)"
            lines = []
            for t in result["tables"]:
                lines.append(f"Table: {t.get('name', '?')}")
                if t.get('sql'):
                    lines.append(f"  SQL: {t['sql']}")
            return "\n".join(lines)
        return f"Error: {result.get('error')}"

    def wal_mode_checkpoint(self, **kwargs) -> str:
        result = self.wal_mode_checkpoint()
        if result.get("success"):
            return result["message"]
        return f"Error: {result.get('error')}"

    def cache_purge(self, **kwargs) -> str:
        result = self.cache_purge()
        if result.get("success"):
            return result["message"]
        return f"Error: {result.get('error')}"