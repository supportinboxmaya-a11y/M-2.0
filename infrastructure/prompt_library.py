"""
Maya 2.0 - Prompt Library
--------------------------
Save, organize, and reuse prompt templates. A prompt template stores
reusable text with {{variable}} placeholders that get filled at use
time, so common instructions ("summarize in N bullet points", "review
this PR", "translate to X") become one-click reusable assets.

Features:
- Templates with typed variables (name, description, default).
- Categories + tags for organization; full-text-ish search.
- Versioning: editing a prompt keeps the previous body in history.
- Usage counter so popular prompts surface.
- render(id, values) fills placeholders; missing required vars raise,
  optional vars fall back to their default.

Storage: SQLite (WAL), matching the rest of the codebase.
"""

import json
import re
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

PROMPT_DIR = STORAGE_DIR / "prompts"
PROMPT_DIR.mkdir(parents=True, exist_ok=True)
PROMPT_DB = str(PROMPT_DIR / "prompts.db")

_VAR = re.compile(r"\{\{\s*([a-zA-Z0-9_]+)\s*\}\}")


class PromptLibrary:
    """Store and render reusable prompt templates."""

    def __init__(self, db_path: str = PROMPT_DB):
        self.db = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS prompts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                body TEXT NOT NULL,
                description TEXT DEFAULT '',
                category TEXT DEFAULT 'general',
                tags TEXT DEFAULT '[]',
                variables TEXT DEFAULT '[]',
                version INTEGER DEFAULT 1,
                uses INTEGER DEFAULT 0,
                created_at REAL,
                updated_at REAL
            )""")
            c.execute("CREATE INDEX IF NOT EXISTS idx_prompt_cat "
                      "ON prompts(category)")
            c.execute("""CREATE TABLE IF NOT EXISTS prompt_versions (
                prompt_id TEXT NOT NULL,
                version INTEGER NOT NULL,
                body TEXT NOT NULL,
                superseded_at REAL,
                PRIMARY KEY (prompt_id, version)
            )""")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(self.db, check_same_thread=False, timeout=10)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    # ── variable inference ────────────────────────────────────────
    @staticmethod
    def extract_variables(body: str) -> List[str]:
        """Unique {{variable}} names in order of first appearance."""
        seen, out = set(), []
        for m in _VAR.finditer(body or ""):
            v = m.group(1)
            if v not in seen:
                seen.add(v)
                out.append(v)
        return out

    # ── writes ────────────────────────────────────────────────────
    def create(self, name: str, body: str, description: str = "",
               category: str = "general", tags: Optional[List[str]] = None,
               variables: Optional[List[Dict]] = None) -> Dict:
        if not name or not body:
            raise ValueError("name and body are required")
        # Auto-derive variables from the body, merged with any provided
        # metadata (description/default per variable).
        found = self.extract_variables(body)
        meta = {v["name"]: v for v in (variables or []) if v.get("name")}
        var_defs = [{"name": v, "description": meta.get(v, {}).get("description", ""),
                     "default": meta.get(v, {}).get("default", None),
                     "required": meta.get(v, {}).get("default") is None}
                    for v in found]
        pid = uuid.uuid4().hex[:12]
        now = time.time()
        with self._lock, self._conn() as c:
            c.execute("INSERT INTO prompts "
                      "(id, name, body, description, category, tags, variables, "
                      " version, uses, created_at, updated_at) "
                      "VALUES (?,?,?,?,?,?,?,1,0,?,?)",
                      (pid, name, body, description, category,
                       json.dumps(tags or []), json.dumps(var_defs), now, now))
        return self.get(pid)

    def update(self, pid: str, body: Optional[str] = None,
               name: Optional[str] = None, description: Optional[str] = None,
               category: Optional[str] = None,
               tags: Optional[List[str]] = None) -> Optional[Dict]:
        cur = self.get(pid)
        if not cur:
            return None
        with self._lock, self._conn() as c:
            if body is not None and body != cur["body"]:
                # archive the old body, bump version, re-derive variables
                c.execute("INSERT INTO prompt_versions VALUES (?,?,?,?)",
                          (pid, cur["version"], cur["body"], time.time()))
                new_vars = json.dumps([{"name": v, "description": "",
                                        "default": None, "required": True}
                                       for v in self.extract_variables(body)])
                c.execute("UPDATE prompts SET body=?, version=version+1, "
                          "variables=?, updated_at=? WHERE id=?",
                          (body, new_vars, time.time(), pid))
            fields, args = [], []
            for col, val in (("name", name), ("description", description),
                             ("category", category)):
                if val is not None:
                    fields.append(f"{col}=?")
                    args.append(val)
            if tags is not None:
                fields.append("tags=?")
                args.append(json.dumps(tags))
            if fields:
                args.append(pid)
                c.execute(f"UPDATE prompts SET {', '.join(fields)}, "
                          f"updated_at={time.time()} WHERE id=?", tuple(args))
        return self.get(pid)

    def delete(self, pid: str) -> bool:
        with self._lock, self._conn() as c:
            c.execute("DELETE FROM prompt_versions WHERE prompt_id=?", (pid,))
            return c.execute("DELETE FROM prompts WHERE id=?", (pid,)).rowcount > 0

    # ── reads ─────────────────────────────────────────────────────
    def get(self, pid: str) -> Optional[Dict]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM prompts WHERE id=?", (pid,)).fetchone()
        return self._row(row) if row else None

    def list(self, category: Optional[str] = None, query: str = "",
             limit: int = 100) -> List[Dict]:
        with self._conn() as c:
            q = "SELECT * FROM prompts WHERE 1=1"
            args: list = []
            if category:
                q += " AND category=?"
                args.append(category)
            if query:
                q += " AND (name LIKE ? OR body LIKE ? OR description LIKE ?)"
                like = f"%{query}%"
                args += [like, like, like]
            q += " ORDER BY uses DESC, updated_at DESC LIMIT ?"
            args.append(limit)
            rows = c.execute(q, tuple(args)).fetchall()
        return [self._row(r) for r in rows]

    def categories(self) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute("SELECT category, COUNT(*) AS n FROM prompts "
                             "GROUP BY category ORDER BY n DESC").fetchall()
        return [{"category": r["category"], "count": r["n"]} for r in rows]

    def history(self, pid: str) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute("SELECT version, body, superseded_at FROM "
                             "prompt_versions WHERE prompt_id=? ORDER BY version",
                             (pid,)).fetchall()
        return [{"version": r["version"], "body": r["body"],
                 "superseded_at": r["superseded_at"]} for r in rows]

    # ── rendering ─────────────────────────────────────────────────
    def render(self, pid: str, values: Optional[Dict] = None,
               count_use: bool = True) -> str:
        """Fill the template's {{variables}} with `values`. Required
        variables (no default) that are missing raise ValueError."""
        p = self.get(pid)
        if not p:
            raise ValueError("prompt not found")
        values = values or {}
        defaults = {v["name"]: v.get("default") for v in p["variables"]}
        required = {v["name"] for v in p["variables"] if v.get("required")}

        missing = [name for name in required
                   if name not in values or values[name] in (None, "")]
        if missing:
            raise ValueError(f"missing required variables: {', '.join(missing)}")

        def sub(m):
            name = m.group(1)
            if name in values and values[name] not in (None, ""):
                return str(values[name])
            if defaults.get(name) is not None:
                return str(defaults[name])
            return ""
        rendered = _VAR.sub(sub, p["body"])

        if count_use:
            with self._lock, self._conn() as c:
                c.execute("UPDATE prompts SET uses=uses+1 WHERE id=?", (pid,))
        return rendered

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _row(row) -> Dict:
        return {"id": row["id"], "name": row["name"], "body": row["body"],
                "description": row["description"], "category": row["category"],
                "tags": json.loads(row["tags"] or "[]"),
                "variables": json.loads(row["variables"] or "[]"),
                "version": row["version"], "uses": row["uses"],
                "created_at": row["created_at"], "updated_at": row["updated_at"]}
