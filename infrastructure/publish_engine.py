"""
Maya 2.0 — Publish Engine (Phase 21)

Guarded real-world publish action for static sites. Uses the existing
WebBuilderTool to deploy to Netlify, but wraps it with a hard approval
gate and a permanent, write-once audit trail.

Flow:
  1. Propose — save full proposed content + metadata to audit DB
  2. Approve — show exact content in approval prompt, block until decision
  3. Execute — on approval, call WebBuilderTool.deploy(); on reject, log it

The audit row's ``files_json`` is set at proposal time and NEVER modified.
Only the ``action`` field advances (proposed → published/rejected/failed).
"""

import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Any, Dict, List, Optional

from config.settings import STORAGE_DIR

PUBLISH_DIR = STORAGE_DIR / "publish"
PUBLISH_DIR.mkdir(parents=True, exist_ok=True)
PUBLISH_DB = str(PUBLISH_DIR / "publish_audit.db")


class PublishEngine:
    """Publish static sites with a hard approval gate and permanent audit."""

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._init_db()

    # ── DB init ────────────────────────────────────────────────────────────

    def _init_db(self) -> None:
        try:
            with self._conn() as c:
                c.executescript("""
                CREATE TABLE IF NOT EXISTS publish_audit (
                    id          TEXT PRIMARY KEY,
                    site_name   TEXT NOT NULL,
                    files_json  TEXT NOT NULL,
                    description TEXT DEFAULT '',
                    action      TEXT NOT NULL DEFAULT 'proposed',
                    approver    TEXT DEFAULT '',
                    result_url  TEXT DEFAULT '',
                    error       TEXT DEFAULT '',
                    created_at  REAL,
                    decided_at  REAL
                );

                CREATE INDEX IF NOT EXISTS idx_pub_audit_action
                    ON publish_audit(action);

                CREATE INDEX IF NOT EXISTS idx_pub_audit_created
                    ON publish_audit(created_at);
                """)
        except Exception as e:
            print(f"WARNING: PublishEngine DB init error: {e}")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(PUBLISH_DB, check_same_thread=False, timeout=10)
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

    # ── Proposal ──────────────────────────────────────────────────────────

    def propose(
        self,
        site_name: str,
        files: Dict[str, str],
        description: str = "",
    ) -> Dict[str, Any]:
        """Create a publish proposal and persist it to the audit DB.

        Returns the proposal dict.  The ``files_json`` field is frozen at
        this point and never modified, providing a permanent record of
        exactly what was proposed.
        """
        pid = uuid.uuid4().hex[:12]
        now = time.time()
        record = {
            "id": pid,
            "site_name": site_name,
            "files_json": json.dumps(files, sort_keys=True),
            "description": description,
            "action": "proposed",
            "approver": "",
            "result_url": "",
            "error": "",
            "created_at": now,
            "decided_at": None,
        }
        try:
            with self._lock, self._conn() as c:
                c.execute(
                    "INSERT INTO publish_audit "
                    "(id, site_name, files_json, description, action, "
                    "approver, result_url, error, created_at, decided_at) "
                    "VALUES (?,?,?,?,?,?,?,?,?,?)",
                    (
                        record["id"],
                        record["site_name"],
                        record["files_json"],
                        record["description"],
                        record["action"],
                        record["approver"],
                        record["result_url"],
                        record["error"],
                        record["created_at"],
                        record["decided_at"],
                    ),
                )
        except Exception as e:
            return {"error": f"Failed to save proposal: {e}"}
        return self._format_record(record)

    # ── Guarded publish ───────────────────────────────────────────────────

    def publish(
        self,
        proposal_id: str,
        approval: Any,
        user: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Execute the publish for *proposal_id* through the approval gate.

        1. Load the proposal (must exist and be 'proposed')
        2. Show exact content in the approval prompt
        3. Block until approved/rejected
        4. On approval: call WebBuilderTool.deploy(), log result
        5. On rejection: log rejection

        Returns the updated proposal dict with result.
        """
        record = self._get_record(proposal_id)
        if not record:
            return {"error": "Proposal not found"}
        if record["action"] != "proposed":
            return {"error": f"Proposal is '{record['action']}' — must be 'proposed'"}

        site_name = record["site_name"]
        description = record.get("description", "")
        try:
            files: Dict[str, str] = json.loads(record["files_json"])
        except (json.JSONDecodeError, TypeError):
            return {"error": "Corrupted files_json in proposal"}

        # Render exact content for approval prompt
        content_lines = [f"Site: {site_name}"]
        if description:
            content_lines.append(f"Description: {description}")
        content_lines.append("")
        # Sort for deterministic display order
        for path in sorted(files.keys()):
            body = files[path]
            content_lines.append(f"--- {path} ---")
            if body:
                content_lines.append(body)
            else:
                content_lines.append("(empty file)")
            content_lines.append("")
        reason_text = "\n".join(content_lines)

        # ── Hard approval gate (critical — gates in ALL modes) ────────
        action_label = f"Publish to Netlify: {site_name}"
        user_label = user.get("email", user.get("username", "unknown")) if user else "unknown"

        if approval is None:
            return {"error": "No approval manager configured — publish blocked"}

        approved = approval.request_approval(
            action=action_label,
            reason=reason_text,
            risk_level="critical",
        )

        if not approved:
            self._update_record(proposal_id, {
                "action": "rejected",
                "approver": user_label,
                "decided_at": time.time(),
                "error": "Rejected by user",
            })
            return {"error": "Publish rejected by user"}

        # ── Execute ──────────────────────────────────────────────────
        self._update_record(proposal_id, {
            "action": "approved",
            "approver": user_label,
            "decided_at": time.time(),
        })

        from tools.code.web_builder_tool import WebBuilderTool
        wbt = WebBuilderTool()

        try:
            result = wbt.deploy(name=site_name, files=files)
            if result.startswith("OK:"):
                # Extract URL from result like "OK: deployed 'site'. Live URL: https://..."
                url = result.split("Live URL:")[-1].strip() if "Live URL:" in result else ""
                self._update_record(proposal_id, {
                    "action": "published",
                    "result_url": url,
                })
                return {
                    "status": "published",
                    "site_name": site_name,
                    "url": url,
                    "proposal_id": proposal_id,
                }
            else:
                error_msg = result  # Error: ...
                self._update_record(proposal_id, {
                    "action": "failed",
                    "error": error_msg[:500],
                })
                return {"error": error_msg}
        except Exception as e:
            err = str(e)
            self._update_record(proposal_id, {
                "action": "failed",
                "error": err[:500],
            })
            return {"error": err}

    # ── Query ─────────────────────────────────────────────────────────────

    def list_history(self) -> List[Dict[str, Any]]:
        """List all publish proposals, newest first."""
        try:
            with self._conn() as c:
                rows = c.execute(
                    "SELECT id, site_name, description, action, "
                    "approver, result_url, created_at, decided_at "
                    "FROM publish_audit ORDER BY created_at DESC"
                ).fetchall()
            return [dict(r) for r in rows]
        except Exception:
            return []

    def get_proposal(self, proposal_id: str) -> Optional[Dict[str, Any]]:
        """Get a single proposal with full detail (including files_json)."""
        return self._get_record(proposal_id)

    # ── Internals ─────────────────────────────────────────────────────────

    def _get_record(self, proposal_id: str) -> Optional[Dict[str, Any]]:
        try:
            with self._conn() as c:
                row = c.execute(
                    "SELECT * FROM publish_audit WHERE id = ?",
                    (proposal_id,),
                ).fetchone()
            return dict(row) if row else None
        except Exception:
            return None

    def _update_record(
        self, proposal_id: str, fields: Dict[str, Any]
    ) -> None:
        """Update non-frozen fields on an audit record.

        ``files_json`` is never updated — it's frozen at proposal time.
        """
        allowed = {"action", "approver", "result_url", "error", "decided_at"}
        updates = {k: v for k, v in fields.items() if k in allowed}
        if not updates:
            return
        set_clause = ", ".join(f"{k} = ?" for k in updates)
        vals = list(updates.values()) + [proposal_id]
        try:
            with self._lock, self._conn() as c:
                c.execute(
                    f"UPDATE publish_audit SET {set_clause} WHERE id = ?",
                    vals,
                )
        except Exception:
            pass

    @staticmethod
    def _format_record(record: Dict[str, Any]) -> Dict[str, Any]:
        """Return a clean dict without raw JSON bloat for list views."""
        return {
            "id": record["id"],
            "site_name": record["site_name"],
            "description": record.get("description", ""),
            "action": record.get("action", "proposed"),
            "approver": record.get("approver", ""),
            "result_url": record.get("result_url", ""),
            "error": record.get("error", ""),
            "created_at": record.get("created_at"),
            "decided_at": record.get("decided_at"),
        }


# ── Module singleton ────────────────────────────────────────────────────────
publish_engine = PublishEngine()
