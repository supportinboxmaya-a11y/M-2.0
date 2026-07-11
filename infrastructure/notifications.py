"""
Maya 2.0 - Notifications
------------------------
Sends alerts through multiple channels when things happen (task done,
task failed, scheduled run, webhook fired, …).

Channels:
    in_app  : always on — persisted to SQLite, read via the API bell.
    email   : SMTP, configured via env (SMTP_HOST/PORT/USER/PASS/FROM).
              No config -> email channel is simply skipped, never errors.
    webhook : POST the notification to a URL (reuses the outbound idea).

Design:
- notify(event, title, body, channels=..., **meta) fans out to the
  requested channels and returns a per-channel result dict.
- Delivery never raises: a broken SMTP server or URL degrades to a
  recorded failure, so notifications can't take down the caller.
- In-app notifications are per-recipient (email/uid) and support
  read/unread + listing, so the UI can show a notification center.
"""

import json
import smtplib
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from email.mime.text import MIMEText
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR, env_first

NOTIF_DIR = STORAGE_DIR / "notifications"
NOTIF_DIR.mkdir(parents=True, exist_ok=True)
NOTIF_DB = str(NOTIF_DIR / "notifications.db")


class Notifier:
    """Multi-channel notification dispatcher with an in-app store."""

    def __init__(self, db_path: str = NOTIF_DB):
        self.db = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _init_db(self):
        with self._conn() as c:
            c.execute("""CREATE TABLE IF NOT EXISTS notifications (
                id TEXT PRIMARY KEY,
                recipient TEXT DEFAULT '',
                event TEXT DEFAULT '',
                title TEXT NOT NULL,
                body TEXT DEFAULT '',
                meta TEXT DEFAULT '{}',
                read INTEGER DEFAULT 0,
                created_at REAL
            )""")
            c.execute("CREATE INDEX IF NOT EXISTS idx_notif_recipient "
                      "ON notifications(recipient, read)")

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

    # ── dispatch ──────────────────────────────────────────────────
    def notify(self, event: str, title: str, body: str = "",
               channels: Optional[List[str]] = None, recipient: str = "",
               email_to: str = "", webhook_url: str = "",
               meta: Optional[Dict] = None) -> Dict:
        """Fan out a notification. Returns per-channel results.
        `channels` defaults to ["in_app"]. Delivery never raises."""
        channels = channels or ["in_app"]
        meta = meta or {}
        results: Dict[str, dict] = {}

        if "in_app" in channels:
            results["in_app"] = self._store(event, title, body, recipient, meta)
        if "email" in channels:
            results["email"] = self._send_email(email_to or recipient, title, body)
        if "webhook" in channels:
            results["webhook"] = self._post_webhook(webhook_url, event, title,
                                                    body, meta)
        return {"event": event, "results": results}

    # ── channel: in-app ───────────────────────────────────────────
    def _store(self, event: str, title: str, body: str, recipient: str,
               meta: Dict) -> Dict:
        nid = uuid.uuid4().hex[:12]
        try:
            with self._lock, self._conn() as c:
                c.execute("INSERT INTO notifications "
                          "(id, recipient, event, title, body, meta, read, created_at) "
                          "VALUES (?,?,?,?,?,?,0,?)",
                          (nid, recipient, event, title, body,
                           json.dumps(meta), time.time()))
            return {"ok": True, "id": nid}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    def list(self, recipient: str = "", unread_only: bool = False,
             limit: int = 50) -> List[Dict]:
        with self._conn() as c:
            q = "SELECT * FROM notifications WHERE 1=1"
            args: list = []
            if recipient:
                q += " AND recipient=?"
                args.append(recipient)
            if unread_only:
                q += " AND read=0"
            q += " ORDER BY created_at DESC LIMIT ?"
            args.append(limit)
            rows = c.execute(q, tuple(args)).fetchall()
        return [self._row(r) for r in rows]

    def unread_count(self, recipient: str = "") -> int:
        with self._conn() as c:
            if recipient:
                row = c.execute("SELECT COUNT(*) AS n FROM notifications "
                                "WHERE recipient=? AND read=0", (recipient,)).fetchone()
            else:
                row = c.execute("SELECT COUNT(*) AS n FROM notifications "
                                "WHERE read=0").fetchone()
        return row["n"]

    def mark_read(self, nid: str) -> bool:
        with self._lock, self._conn() as c:
            return c.execute("UPDATE notifications SET read=1 WHERE id=?",
                             (nid,)).rowcount > 0

    def mark_all_read(self, recipient: str = "") -> int:
        with self._lock, self._conn() as c:
            if recipient:
                cur = c.execute("UPDATE notifications SET read=1 "
                                "WHERE recipient=? AND read=0", (recipient,))
            else:
                cur = c.execute("UPDATE notifications SET read=1 WHERE read=0")
            return cur.rowcount

    # ── channel: email (SMTP) ─────────────────────────────────────
    @staticmethod
    def email_configured() -> bool:
        return bool(env_first("SMTP_HOST") and env_first("SMTP_FROM"))

    def _send_email(self, to_addr: str, subject: str, body: str) -> Dict:
        if not self.email_configured():
            return {"ok": False, "skipped": "SMTP not configured"}
        if not to_addr:
            return {"ok": False, "error": "no recipient address"}
        host = env_first("SMTP_HOST")
        port = int(env_first("SMTP_PORT", default="587") or "587")
        user = env_first("SMTP_USER")
        password = env_first("SMTP_PASS", "SMTP_PASSWORD")
        sender = env_first("SMTP_FROM")
        try:
            msg = MIMEText(body or subject)
            msg["Subject"] = subject
            msg["From"] = sender
            msg["To"] = to_addr
            with smtplib.SMTP(host, port, timeout=10) as server:
                server.starttls()
                if user and password:
                    server.login(user, password)
                server.sendmail(sender, [to_addr], msg.as_string())
            return {"ok": True, "to": to_addr}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── channel: webhook ──────────────────────────────────────────
    @staticmethod
    def _post_webhook(url: str, event: str, title: str, body: str,
                      meta: Dict) -> Dict:
        if not url:
            return {"ok": False, "error": "no webhook url"}
        try:
            import requests
            resp = requests.post(url, json={"event": event, "title": title,
                                            "body": body, "meta": meta},
                                 timeout=8)
            return {"ok": 200 <= resp.status_code < 300,
                    "status": resp.status_code}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def _row(row) -> Dict:
        return {"id": row["id"], "recipient": row["recipient"],
                "event": row["event"], "title": row["title"],
                "body": row["body"], "meta": json.loads(row["meta"] or "{}"),
                "read": bool(row["read"]), "created_at": row["created_at"]}
