"""
Maya 2.0 — Publish Engine (Phase 21)

Guarded real-world publish action for static sites. Uses the existing
WebBuilderTool to deploy to Netlify, but wraps it with a risk-based
approval gate and a permanent, write-once audit trail.

Flow:
  1. Propose — save full proposed content + metadata to audit DB
  2. Risk Check — classify as low-risk (auto-apply) or high-risk (needs approval)
  3. Low-risk: auto-apply, log result
  4. High-risk: show exact content in approval prompt, block until decision
  5. On approval: call WebBuilderTool.deploy(); on reject, log it

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

from config.constants import RISK_LOW, RISK_HIGH, RISK_CRITICAL
from config.settings import STORAGE_DIR

PUBLISH_DIR = STORAGE_DIR / "publish"
PUBLISH_DIR.mkdir(parents=True, exist_ok=True)
PUBLISH_DB = str(PUBLISH_DIR / "publish_audit.db")


# ── Risk Classification for Publish Requests ──────────────────────────────

# Low-risk: UI text changes, minor config, read-only, documentation
LOW_RISK_KEYWORDS = [
    "ui text", "text change", "copy change", "copy update",
    "minor config", "config tweak", "read-only", "documentation",
    "readme", "docs/", "changelog", "license", "comment",
    "color", "font", "spacing", "margin", "padding",
    "typo", "spelling", "grammar", "wording", "label",
    "button text", "link text", "heading", "title",
    "meta tag", "seo", "alt text", "title tag",
]

# High-risk: code deploy, VPS/instance change, delete, security, autonomous
HIGH_RISK_KEYWORDS = [
    "code deploy", "deploy code", "push code", "git push",
    "vps", "instance", "server", "container",
    "delete", "destroy", "terminate", "remove",
    "security", "auth", "password", "secret", "key",
    "autonomous", "auto mode", "cognition", "cognitive",
    "database", "drop", "truncate", "wipe",
    "production", "prod", "live",
    "payment", "billing", "charge", "spend",
    "docker restart", "docker start", "docker stop",
    "docker kill", "docker rm", "docker rmi",
    "shutdown", "reboot", "poweroff",
]


def classify_publish_risk(site_name: str, files: Dict[str, str], description: str = "") -> str:
    """Classify publish request as 'low' or 'high' risk.
    
    Returns: 'low' or 'high'
    """
    # Combine all content for analysis
    content = f"{site_name} {description} "
    for path, body in files.items():
        content += f" {path} {body}"
    
    content_lower = content.lower()
    
    # Check high-risk first (more conservative)
    for kw in HIGH_RISK_KEYWORDS:
        if kw in content_lower:
            return RISK_HIGH
    
    # Check low-risk
    for kw in LOW_RISK_KEYWORDS:
        if kw in content_lower:
            return RISK_LOW
    
    # Default to high-risk for safety (unknown = high-risk)
    return RISK_HIGH


class PublishEngine:
    """Publish static sites with a risk-based approval gate and permanent audit.

    Flow:
      1. Propose — save full proposed content + metadata to audit DB
      2. Risk Check — classify as low-risk (auto-apply) or high-risk (needs approval)
      3. Low-risk: auto-apply, log result
      4. High-risk: show exact content in approval prompt, block until decision
      5. On approval: call WebBuilderTool.deploy(); on reject, log it
    """

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
                    risk_level  TEXT DEFAULT 'high',
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

        Returns the proposal dict with risk classification.  
        The ``files_json`` field is frozen at this point and never modified,
        providing a permanent record of exactly what was proposed.
        """
        pid = uuid.uuid4().hex[:12]
        now = time.time()
        
        # Classify risk level
        risk_level = classify_publish_risk(site_name, files, description)
        
        record = {
            "id": pid,
            "site_name": site_name,
            "files_json": json.dumps(files, sort_keys=True),
            "description": description,
            "action": "proposed",
            "approver": "",
            "result_url": "",
            "error": "",
            "risk_level": risk_level,
            "created_at": now,
            "decided_at": None,
        }
        try:
            with self._lock, self._conn() as c:
                c.execute(
                    "INSERT INTO publish_audit "
                    "(id, site_name, files_json, description, action, "
                    "approver, result_url, error, risk_level, created_at, decided_at) "
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                    (
                        record["id"],
                        record["site_name"],
                        record["files_json"],
                        record["description"],
                        record["action"],
                        record["approver"],
                        record["result_url"],
                        record["error"],
                        record["risk_level"],
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
        """Execute the publish for *proposal_id* through the risk-based approval gate.

        1. Load the proposal (must exist and be 'proposed')
        2. Check risk level:
           - Low-risk: auto-apply, log result, return success
           - High-risk: show exact content in approval prompt, block until decision
        3. On approval: call WebBuilderTool.deploy(); on reject, log it

        Returns the updated proposal dict with result.
        """
        record = self._get_record(proposal_id)
        if not record:
            return {"error": "Proposal not found"}
        if record["action"] != "proposed":
            return {"error": f"Proposal is '{record['action']}' — must be 'proposed'"}

        site_name = record["site_name"]
        description = record.get("description", "")
        risk_level = record.get("risk_level", RISK_HIGH)
        try:
            files: Dict[str, str] = json.loads(record["files_json"])
        except (json.JSONDecodeError, TypeError):
            return {"error": "Corrupted files_json in proposal"}

        # Render exact content for approval prompt (used for high-risk)
        content_lines = [f"Site: {site_name}"]
        if description:
            content_lines.append(f"Description: {description}")
        content_lines.append("")
        for path in sorted(files.keys()):
            body = files[path]
            content_lines.append(f"--- {path} ---")
            if body:
                content_lines.append(body)
            else:
                content_lines.append("(empty file)")
            content_lines.append("")
        reason_text = "\n".join(content_lines)

        # ── Low-risk: Auto-apply ────────────────────────────────────
        if risk_level == RISK_LOW:
            user_label = user.get("email", user.get("username", "unknown")) if user else "system"
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
                        "risk_level": "low",
                        "auto_applied": True,
                    }
                else:
                    error_msg = result
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

        # ── High-risk: Show exact content in approval prompt ────────
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
                    "risk_level": "high",
                    "auto_applied": False,
                }
            else:
                error_msg = result
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

    def get_proposal(self, proposal_id: str) -> Optional[Dict[str, Any]]:
        """Get a single proposal with full detail (including files_json)."""
        return self._get_record(proposal_id)

    def decide(
        self,
        proposal_id: str,
        decision: str,
        user: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        """Decide on a publish proposal (approve or reject).
        
        Args:
            proposal_id: The ID of the proposal to decide on
            decision: Either "approve" or "reject"
            user: Optional user info for audit log
            
        Returns:
            Updated proposal dict with result
        """
        record = self._get_record(proposal_id)
        if not record:
            return {"error": "Proposal not found"}
        if record["action"] != "proposed":
            return {"error": f"Proposal is '{record['action']}' — must be 'proposed'"}
        
        if decision not in ("approve", "reject"):
            return {"error": "Decision must be 'approve' or 'reject'"}
        
        site_name = record["site_name"]
        description = record.get("description", "")
        risk_level = record.get("risk_level", RISK_HIGH)
        try:
            files: Dict[str, str] = json.loads(record["files_json"])
        except (json.JSONDecodeError, TypeError):
            return {"error": "Corrupted files_json in proposal"}
        
        user_label = user.get("email", user.get("username", "unknown")) if user else "unknown"
        
        if decision == "reject":
            self._update_record(proposal_id, {
                "action": "rejected",
                "approver": user_label,
                "decided_at": time.time(),
                "error": "Rejected by user",
            })
            return {"error": "Publish rejected by user"}
        
        # decision == "approve"
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
                    "risk_level": risk_level,
                    "auto_applied": False,
                }
            else:
                error_msg = result
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
