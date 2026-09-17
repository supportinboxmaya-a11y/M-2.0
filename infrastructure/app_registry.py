"""
Maya 2.0 — Phase 30: App Registry + Remote Monitoring
------------------------------------------------------
Tracks deployed Docker containers on the remote VPS and provides health
checks, auto-restart (gated), and log access.

**Boundary vs Phase 15:** Phase 15 (HostingManager) manages LOCAL
subprocesses (Termux ASGI/Node/static servers) with JSON persistence.
Phase 30 manages REMOTE Docker containers on a VPS with SQLite
persistence.  They are independent domains that share nothing.
"""

import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

# The remote VPS deployer singleton — provides SSH + Docker operations.
from infrastructure.remote_deploy import remote_deployer

# ── Constants ──────────────────────────────────────────────────────────────

REGISTRY_DIR = STORAGE_DIR / "app_registry"
REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
REGISTRY_DB = str(REGISTRY_DIR / "app_registry.db")

APP_MONITOR_ENABLED = os.environ.get("APP_MONITOR_ENABLED", "false").lower() == "true"


class AppRegistry:
    """SQLite-backed registry of deployed remote apps with health checking.

    Thread-safe via ``_lock`` + WAL mode.  Depends on the module-level
    ``remote_deployer`` singleton for all SSH/Docker interactions.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._init_db()

    # ── DB init ───────────────────────────────────────────────────────────

    def _init_db(self) -> None:
        try:
            with self._conn() as c:
                c.executescript("""
                CREATE TABLE IF NOT EXISTS apps (
                    name          TEXT PRIMARY KEY,
                    host          TEXT NOT NULL DEFAULT '',
                    container_id  TEXT DEFAULT '',
                    image         TEXT DEFAULT '',
                    status        TEXT DEFAULT 'unknown',
                    deployed_at   REAL,
                    last_seen     REAL,
                    last_error    TEXT DEFAULT '',
                    monitor       INTEGER DEFAULT 1
                );
                """)
        except Exception as e:
            print(f"WARNING: AppRegistry DB init error: {e}")

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(REGISTRY_DB, check_same_thread=False, timeout=10)
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

    # ── CRUD ──────────────────────────────────────────────────────────────

    def register(
        self,
        name: str,
        container_id: str = "",
        image: str = "",
        host: str = "",
    ) -> dict:
        """Insert or update a tracked app."""
        now = time.time()
        with self._lock, self._conn() as c:
            existing = c.execute(
                "SELECT * FROM apps WHERE name = ?", (name,)
            ).fetchone()
            if existing:
                c.execute(
                    "UPDATE apps SET container_id=?, image=?, host=?, "
                    "last_seen=? WHERE name=?",
                    (container_id, image, host, now, name),
                )
            else:
                c.execute(
                    "INSERT INTO apps (name, host, container_id, image, "
                    "deployed_at, last_seen, status) "
                    "VALUES (?,?,?,?,?,?,?)",
                    (name, host, container_id, image, now, now, "unknown"),
                )
        return self.get(name)

    def unregister(self, name: str) -> bool:
        """Remove an app from the registry."""
        with self._lock, self._conn() as c:
            cur = c.execute("DELETE FROM apps WHERE name = ?", (name,))
            return cur.rowcount > 0

    def list(self) -> List[dict]:
        """Return all tracked apps."""
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM apps ORDER BY name"
            ).fetchall()
        return [self._row_dict(r) for r in rows]

    def get(self, name: str) -> Optional[dict]:
        """Return a single app, or ``None``."""
        with self._conn() as c:
            row = c.execute(
                "SELECT * FROM apps WHERE name = ?", (name,)
            ).fetchone()
        return self._row_dict(row) if row else None

    def set_monitor(self, name: str, enabled: bool) -> bool:
        """Toggle health monitoring for an app."""
        with self._lock, self._conn() as c:
            cur = c.execute(
                "UPDATE apps SET monitor = ? WHERE name = ?",
                (int(enabled), name),
            )
            return cur.rowcount > 0

    # ── Health checks (single + batch) ────────────────────────────────────

    def health_check(self, name: str) -> dict:
        """Check a single app's container status via remote SSH.

        Opens one SSH call.  For bulk operations prefer ``check_all()``
        which reuses a single connection for the whole sweep.
        """
        app = self.get(name)
        if not app:
            return {"ok": False, "name": name, "error": "not found"}

        status = "unknown"
        last_error = ""
        try:
            containers = remote_deployer.list_containers()
            running = any(
                c.get("Names") == name or c.get("name") == name
                for c in containers
            )
            status = "running" if running else "stopped"
            if not running:
                last_error = "Container not running"
        except RuntimeError as e:
            status = "error"
            last_error = str(e)

        now = time.time()
        with self._lock, self._conn() as c:
            c.execute(
                "UPDATE apps SET status=?, last_seen=?, last_error=? WHERE name=?",
                (status, now, last_error[:500], name),
            )
        return {"ok": True, "name": name, "status": status}

    def _update_status(self, name: str, status: str, last_error: str = "") -> None:
        """Internal helper — update status fields without re-checking."""
        now = time.time()
        with self._lock, self._conn() as c:
            c.execute(
                "UPDATE apps SET status=?, last_seen=?, last_error=? WHERE name=?",
                (status, now, last_error[:500], name),
            )

    def check_all(self) -> List[dict]:
        """Health-check all monitored apps in a single remote sweep.

        Opens ONE SSH connection (via ``batch_container_status()``) and
        checks every tracked app's container status in one go, then
        updates the store.  Far more efficient than N sequential
        ``health_check()`` calls.
        """
        if not remote_deployer.configured:
            return []

        monitored = [a for a in self.list() if a.get("monitor", True)]
        if not monitored:
            return []

        # Single SSH call — batch-status all monitored container names.
        try:
            statuses = remote_deployer.batch_container_status(
                [a["name"] for a in monitored]
            )
        except RuntimeError as e:
            err = str(e)
            results = []
            for app in monitored:
                self._update_status(app["name"], "error", err)
                results.append({"name": app["name"], "status": "error", "error": err})
            return results

        results = []
        for app in monitored:
            name = app["name"]
            raw = statuses.get(name, "not found")
            if raw == "not found":
                status = "stopped"
                last_error = "Container not found on remote host"
            elif raw.startswith("Up"):
                status = "running"
                last_error = ""
            else:
                status = "stopped"
                last_error = raw
            self._update_status(name, status, last_error)
            results.append({"name": name, "status": status})

        return results

    # ── Lifecycle (gated) ─────────────────────────────────────────────────

    def restart(self, name: str) -> dict:
        """Restart a container through the approval gate.

        The ``api.py`` Phase 30 routes apply RiskChecker + ApprovalManager
        *before* calling this method.
        """
        app = self.get(name)
        if not app:
            return {"ok": False, "error": f"app '{name}' not found"}
        return remote_deployer.restart_container(name)

    def logs(self, name: str, lines: int = 100) -> dict:
        """Fetch remote container logs."""
        app = self.get(name)
        if not app:
            return {"ok": False, "error": f"app '{name}' not found"}
        return remote_deployer.container_logs(name, lines)

    # ── Scheduler integration ─────────────────────────────────────────────

    def start_monitor(
        self,
        interval: int = 60,
        approval_mgr: Optional[object] = None,
        scheduler: Optional[object] = None,
        task_queue: Optional[object] = None,
    ) -> Optional[str]:
        """Register the health-check loop with the scheduler.

        Only registers when ``APP_MONITOR_ENABLED=true``.  When an app is
        found ``stopped``, it attempts an auto-restart through the
        approval gate (if provided).

        Returns a schedule id, or ``None`` if not registered.
        """
        if not APP_MONITOR_ENABLED:
            print(
                "INFO: APP_MONITOR_ENABLED is false — "
                "health monitor not started"
            )
            return None
        if not task_queue or not scheduler:
            print(
                "WARNING: AppRegistry has no task_queue or scheduler — "
                "cannot register monitor"
            )
            return None

        async def _monitor_cycle() -> dict:
            """One tick: health-check all, then auto-restart stopped apps."""
            results = self.check_all()
            revived = 0
            for r in results:
                if r.get("status") == "stopped" and approval_mgr:
                    try:
                        needs = approval_mgr.needs_approval(
                            f"appregistry:restart:{r['name']}",
                            risk_level="low",
                        )
                        if needs:
                            approved = approval_mgr.request_approval(
                                action=f"[AppRegistry] Auto-restart '{r['name']}'",
                                reason="Container not running",
                                risk_level="low",
                                task_id=r["name"],
                            )
                            if not approved:
                                continue
                        self.restart(r["name"])
                        revived += 1
                    except Exception:
                        pass
            return {
                "action": "monitor_cycle",
                "checked": len(results),
                "revived": revived,
            }

        # Register the handler and add a recurring schedule.
        try:
            task_queue.register("appregistry_monitor", _monitor_cycle)
            sched = scheduler.add(
                name="appregistry_monitor",
                cron=f"*/{interval} * * * * *",
                job="appregistry_monitor",
                args=[],
                kwargs={},
            )
            self._schedule_id = sched["id"]
            print(
                f"INFO: AppRegistry monitor registered (schedule={sched['id']}, "
                f"interval={interval}s)"
            )
            return sched["id"]
        except Exception as e:
            print(f"WARNING: Failed to register AppRegistry monitor: {e}")
            return None

    # ── Internals ─────────────────────────────────────────────────────────

    @staticmethod
    def _row_dict(row) -> dict:
        d = dict(row)
        if "monitor" in d:
            d["monitor"] = bool(d["monitor"])
        return d


# ── Module singleton ────────────────────────────────────────────────────────
app_registry = AppRegistry()
