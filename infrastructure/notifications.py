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
    push    : phone push via FCM (Firebase). If no push provider is
              configured the call degrades to an in-app notification so
              the phone can still pick it up by polling.

Design:
- notify(event, title, body, channels=..., **meta) fans out to the
  requested channels and returns a per-channel result dict.
- Delivery never raises: a broken SMTP server or URL degrades to a
  recorded failure, so notifications can't take down the caller.
- In-app notifications are per-recipient (email/uid) and support
  read/unread + listing, so the UI can show a notification center.
- notify_phone(title, body, level, recipient) is a convenience helper
  that tries FCM push first and falls back to the in-app store.
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

# ── Optional FCM push ─────────────────────────────────────────────────────
try:
    import firebase_admin
    from firebase_admin import credentials, messaging as _fcm_messaging
    _HAS_FCM = True
except ImportError:
    _HAS_FCM = False
    _fcm_messaging = None

# Lazy-init FCM app singleton so import of this module never connects
# to Firebase — only the first push attempt triggers it.
_FCM_APP = None


def _ensure_fcm():
    """Initialise the Firebase Admin SDK on first use, or return False if
    the SDK is not installed or no credentials are configured."""
    global _FCM_APP
    if _FCM_APP is not None:
        return True
    if not _HAS_FCM:
        return False
    cred_path = env_first("FCM_CREDENTIALS_PATH", "FCM_CREDENTIALS")
    if not cred_path:
        return False
    try:
        _FCM_APP = firebase_admin.initialize_app(
            credentials.Certificate(cred_path),
        )
        return True
    except Exception:
        return False


# ── Module-level helper (zero-import singleton) ───────────────────────────
_notifier_instance: Optional["Notifier"] = None


def notify_phone(title: str, body: str = "", level: str = "info",
                 recipient: str = "") -> dict:
    """Convenience function importable by any module.

    Tries FCM push first.  Falls back to storing an in-app notification
    so the phone can poll ``GET /api/v1/notifications/unread``.
    """
    global _notifier_instance
    if _notifier_instance is None:
        _notifier_instance = Notifier()
    return _notifier_instance.notify_phone(title, body, level, recipient)


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
            c.execute("""CREATE TABLE IF NOT EXISTS push_tokens (
                token TEXT PRIMARY KEY,
                platform TEXT NOT NULL,
                recipient TEXT NOT NULL,
                created_at REAL
            )""")
            c.execute("CREATE INDEX IF NOT EXISTS idx_push_recipient "
                      "ON push_tokens(recipient)")

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

    # ── channel: phone push (FCM) ──────────────────────────────────
    def _send_push(self, title: str, body: str, level: str,
                   token: str, platform: str) -> Dict:
        """Send a single push notification via FCM.  Returns per-token
        result dict — never raises."""
        if not _ensure_fcm():
            return {"ok": False, "skipped": "FCM not configured"}
        try:
            msg = _fcm_messaging.Message(
                notification=_fcm_messaging.Notification(title=title, body=body),
                data={"level": level},
                token=token,
            )
            response = _fcm_messaging.send(msg)
            return {"ok": True, "fcm_id": response}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── device registration ────────────────────────────────────────
    def register_device(self, token: str, platform: str,
                        recipient: str) -> Dict:
        """Store or update a push token.  Idempotent — re-registering
        the same token updates its recipient/platform."""
        try:
            with self._lock, self._conn() as c:
                c.execute(
                    "INSERT OR REPLACE INTO push_tokens "
                    "(token, platform, recipient, created_at) "
                    "VALUES (?,?,?,?)",
                    (token, platform, recipient, time.time()),
                )
            return {"ok": True, "token": token[:8] + "…"}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    def unregister_device(self, token: str) -> bool:
        """Remove a push token (e.g. on logout)."""
        try:
            with self._lock, self._conn() as c:
                return c.execute("DELETE FROM push_tokens WHERE token=?",
                                 (token,)).rowcount > 0
        except Exception:
            return False

    # ── phone notification helper (push + in-app fallback) ─────────
    def notify_phone(self, title: str, body: str = "",
                     level: str = "info", recipient: str = "") -> Dict:
        """Push to phone via FCM.  Falls back to storing an in-app
        notification so the phone can poll on next request.

        Level can be ``"info"``, ``"warn"``, or ``"error"`` — mapped
        to an FCM data field so the app can colour the alert."""
        pushed = False
        push_results: list = []
        if recipient:
            try:
                with self._conn() as c:
                    rows = c.execute(
                        "SELECT token, platform FROM push_tokens "
                        "WHERE recipient=? ORDER BY created_at DESC",
                        (recipient,),
                    ).fetchall()
                for row in rows:
                    r = self._send_push(title, body, level,
                                        row["token"], row["platform"])
                    push_results.append(r)
                    if r.get("ok"):
                        pushed = True
            except Exception:
                pass

        # Always store in-app as fallback
        stored = self._store("phone_push", title, body, recipient,
                             {"level": level, "pushed": pushed})
        return {
            "pushed": pushed,
            "push_results": push_results,
            "in_app": stored,
        }

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
