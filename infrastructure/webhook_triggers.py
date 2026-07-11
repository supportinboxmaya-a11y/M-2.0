"""
Maya 2.0 - Inbound Webhook Triggers
-----------------------------------
Lets external services (GitHub, Slack, forms, Zapier, …) call Maya to
*trigger* work. This complements the existing OUTBOUND webhooks (Maya
notifying others when a task finishes).

A trigger = {id, name, secret, job, template, enabled, ...}. When a
request hits POST /api/v1/hooks/{id}:
    1. the raw body is verified against the trigger's secret using HMAC
       SHA-256 (constant-time compare) — unless the trigger is unsigned;
    2. a goal string is built from the trigger's `template`, filled with
       values pulled from the incoming JSON payload;
    3. the goal is enqueued on the persistent task queue (restart-proof).

Storage is SQLite (WAL), matching the rest of the codebase. Secrets are
generated server-side and only returned once at creation time.
"""

import hashlib
import hmac
import json
import re
import secrets as _secrets
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

HOOK_DIR = STORAGE_DIR / "hooks"
HOOK_DIR.mkdir(parents=True, exist_ok=True)
HOOK_DB = str(HOOK_DIR / "triggers.db")

_PLACEHOLDER = re.compile(r"\{\{\s*([a-zA-Z0-9_.]+)\s*\}\}")


class WebhookTriggers:
    """Store + verify + render inbound webhook triggers."""

    def __init__(self, db_path: str = HOOK_DB):
        self.db = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS triggers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                secret TEXT,
                job TEXT NOT NULL,
                template TEXT NOT NULL,
                enabled INTEGER DEFAULT 1,
                created_at REAL,
                last_fired REAL,
                fire_count INTEGER DEFAULT 0
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

    # ── management ────────────────────────────────────────────────
    def create(self, name: str, job: str, template: str,
               signed: bool = True) -> Dict:
        """Create a trigger. Returns the record INCLUDING the secret
        (shown only once). `template` may contain {{path.to.field}}
        placeholders resolved against the incoming JSON payload."""
        if not name or not job or not template:
            raise ValueError("name, job and template are required")
        tid = uuid.uuid4().hex[:12]
        secret = _secrets.token_urlsafe(24) if signed else None
        with self._lock, self._conn() as c:
            c.execute("INSERT INTO triggers "
                      "(id, name, secret, job, template, enabled, created_at) "
                      "VALUES (?,?,?,?,?,1,?)",
                      (tid, name, secret, job, template, time.time()))
        return {"id": tid, "name": name, "job": job, "template": template,
                "signed": signed, "secret": secret,
                "url": f"/api/v1/hooks/{tid}"}

    def delete(self, tid: str) -> bool:
        with self._lock, self._conn() as c:
            return c.execute("DELETE FROM triggers WHERE id=?",
                             (tid,)).rowcount > 0

    def set_enabled(self, tid: str, enabled: bool) -> bool:
        with self._lock, self._conn() as c:
            return c.execute("UPDATE triggers SET enabled=? WHERE id=?",
                             (1 if enabled else 0, tid)).rowcount > 0

    def list(self) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute("SELECT * FROM triggers ORDER BY created_at").fetchall()
        return [self._public(r) for r in rows]

    def get(self, tid: str) -> Optional[Dict]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM triggers WHERE id=?", (tid,)).fetchone()
        return dict(row) if row else None

    # ── verification + rendering ──────────────────────────────────
    @staticmethod
    def verify_signature(secret: str, raw_body: bytes, signature: str) -> bool:
        """Constant-time HMAC-SHA256 check. `signature` may be the hex
        digest or GitHub-style 'sha256=<hex>'."""
        if not secret:
            return True                      # unsigned trigger
        if not signature:
            return False
        sig = signature.strip()
        if sig.startswith("sha256="):
            sig = sig[7:]
        expected = hmac.new(secret.encode(), raw_body or b"",
                            hashlib.sha256).hexdigest()
        return hmac.compare_digest(expected, sig)

    @staticmethod
    def render_goal(template: str, payload: Dict) -> str:
        """Fill {{path.to.field}} placeholders from the JSON payload.
        Missing paths render as empty strings (never raises)."""
        def resolve(path: str):
            cur = payload
            for part in path.split("."):
                if isinstance(cur, dict) and part in cur:
                    cur = cur[part]
                elif isinstance(cur, list) and part.isdigit() and \
                        int(part) < len(cur):
                    cur = cur[int(part)]
                else:
                    return ""
            if isinstance(cur, (dict, list)):
                return json.dumps(cur, ensure_ascii=False)[:500]
            return str(cur)
        return _PLACEHOLDER.sub(lambda m: resolve(m.group(1)), template)

    def mark_fired(self, tid: str):
        with self._lock, self._conn() as c:
            c.execute("UPDATE triggers SET last_fired=?, "
                      "fire_count=fire_count+1 WHERE id=?", (time.time(), tid))

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _public(row) -> Dict:
        """Public view — never leaks the secret."""
        return {"id": row["id"], "name": row["name"], "job": row["job"],
                "template": row["template"], "signed": bool(row["secret"]),
                "enabled": bool(row["enabled"]),
                "created_at": row["created_at"], "last_fired": row["last_fired"],
                "fire_count": row["fire_count"],
                "url": f"/api/v1/hooks/{row['id']}"}
