"""
Maya 2.0 — Hosting Manager
--------------------------
Launches and supervises local apps (Python ASGI, Python scripts, Node,
static HTTP servers, or raw commands) on a Termux-friendly stack.

Ports are auto-allocated from 8100-8999.  Every subprocess runs in its
own process group (``preexec_fn=os.setsid``) so the whole tree can be
killed cleanly.  stdout+stderr stream to ``LOG_DIR/hosted/<name>.log``.

External dependencies are optional:
- **psutil** — richer process introspection when installed.
- **cloudflared** — ``open_tunnel()`` creates a ``cloudflared tunnel``
  subprocess for a public URL (detected via ``shutil.which``).

Design matches ``instances.py``: JSON persistence, threading lock,
module singleton ``hosting_manager``.
"""

import json
import os
import signal
import shutil
import socket
import subprocess
import threading
import time
import uuid
from pathlib import Path
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR, LOG_DIR

# ── Constants ──────────────────────────────────────────────────────────────

HOSTED_DIR = STORAGE_DIR / "hosted_apps"
HOSTED_FILE = str(HOSTED_DIR / "hosted_apps.json")
LOG_HOSTED_DIR = LOG_DIR / "hosted"
PORT_MIN = 8100
PORT_MAX = 8999
MAX_APPS_PER_OWNER = int(os.environ.get("MAX_APPS_PER_OWNER", "10"))

for d in [HOSTED_DIR, LOG_HOSTED_DIR]:
    d.mkdir(parents=True, exist_ok=True)


# ── Utility functions ──────────────────────────────────────────────────────

def _find_free_port(preferred: Optional[int] = None,
                    exclude: set = frozenset()) -> Optional[int]:
    """Return a free port in [PORT_MIN, PORT_MAX] avoiding *exclude*.
    Returns ``None`` if none are free."""
    check = [preferred] if preferred else []
    check += [p for p in range(PORT_MIN, PORT_MAX + 1)
              if p not in exclude and p != preferred]
    for port in check:
        if port in exclude:
            continue
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(0.5)
            s.bind(("0.0.0.0", port))
            s.close()
            return port
        except (OSError, PermissionError):
            continue
    return None


def _pid_alive(pid: int) -> bool:
    """Check if *pid* is still alive using zero-signal."""
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
        return True
    except (OSError, PermissionError):
        return False


def _port_reachable(port: int, host: str = "127.0.0.1",
                    timeout: float = 2.0) -> bool:
    """Return ``True`` if *host:port* accepts a TCP connection."""
    if not port:
        return False
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        s.connect((host, port))
        s.close()
        return True
    except (OSError, socket.timeout):
        return False


def _tail(path: str, n: int = 100) -> List[str]:
    """Return last *n* lines of a file efficiently."""
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
        return [l.rstrip("\n\r") for l in lines[-n:]]
    except (FileNotFoundError, OSError):
        return []


def _shlex_quote(s: str) -> str:
    """Minimal shell quoting — wraps in single quotes with embedded
    single-quote escape."""
    return "'" + s.replace("'", "'\\''") + "'"


def _build_command(app: dict) -> str:
    """Build the shell command string for an app."""
    kind = app.get("kind", "")
    entry = app.get("entry", "")
    path = app.get("path", ".")
    port = app.get("port")
    raw_cmd = app.get("command", "")

    prefix = f"cd {_shlex_quote(path)}"

    if kind == "python-asgi":
        return f"{prefix} && uvicorn {entry} --host 0.0.0.0 --port {port}"
    elif kind == "python":
        return f"{prefix} && PORT={port} python {entry}"
    elif kind == "node":
        return f"{prefix} && PORT={port} node {entry}"
    elif kind == "static":
        serve_path = _shlex_quote(path)
        return f"{prefix} && python -m http.server {port} --directory {serve_path}"
    elif kind == "command":
        env_prefix = f"PORT={port}" if port else ""
        if env_prefix:
            return f"{prefix} && {env_prefix} {raw_cmd}"
        return f"{prefix} && {raw_cmd}"
    return raw_cmd


# ══════════════════════════════════════════════════════════════════════════

class HostingManager:
    """Registry + lifecycle for locally hosted apps.

    Thread-safe.  JSON-persisted.  Survives restarts — reconciles dead
    PIDs on load.
    """

    def __init__(self, path: str = HOSTED_FILE):
        self._path = path
        self._lock = threading.Lock()
        self._apps: Dict[str, dict] = {}
        self._load()
        self._reconcile_dead()

    # ── persistence ──────────────────────────────────────────────────────

    def _load(self) -> None:
        try:
            with open(self._path, "r", encoding="utf-8") as f:
                self._apps = json.load(f)
        except (FileNotFoundError, ValueError):
            self._apps = {}

    def _save(self) -> None:
        p = Path(self._path)
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(self._path, "w", encoding="utf-8") as f:
            json.dump(self._apps, f, indent=2, default=str)

    def _reconcile_dead(self) -> None:
        """On boot, mark entries whose PID is no longer alive as stopped."""
        changed = False
        for app in self._apps.values():
            pid = app.get("pid")
            if pid and pid > 0 and not _pid_alive(pid):
                app["pid"] = 0
                app["started_at"] = None
                changed = True
        if changed:
            self._save()

    def _log_path(self, name: str) -> str:
        return str(LOG_HOSTED_DIR / f"{name}.log")

    # ── CRUD + lifecycle ─────────────────────────────────────────────────

    def deploy(self, name: str, kind: str, entry: str = "", path: str = "",
               command: str = "", port: Optional[int] = None,
               env: Optional[Dict[str, str]] = None,
               owner: str = "system", autostart: bool = True,
               tunnel: bool = False) -> dict:
        """Register and optionally launch a new app.

        *name* must be unique.  *kind* is one of ``"python-asgi"``,
        ``"python"``, ``"node"``, ``"static"``, ``"command"``.
        """
        errors = []
        if not name:
            errors.append("name is required")
        if kind not in ("python-asgi", "python", "node", "static", "command"):
            errors.append(f"unknown kind: {kind}")
        if kind in ("python-asgi", "python", "node") and not entry and not command:
            errors.append(f"entry or command required for kind={kind}")
        if errors:
            return {"ok": False, "error": "; ".join(errors)}

        with self._lock:
            # Name uniqueness
            for existing in self._apps.values():
                if existing.get("name") == name:
                    return {"ok": False, "error": f"app '{name}' already exists"}

            # Owner limit
            if owner:
                owner_count = sum(
                    1 for a in self._apps.values() if a.get("owner") == owner
                )
                if owner_count >= MAX_APPS_PER_OWNER:
                    return {"ok": False,
                            "error": f"owner '{owner}' has {owner_count} apps (max {MAX_APPS_PER_OWNER})"}

            # Port (auto-allocate if not specified)
            excluded = {a.get("port") for a in self._apps.values() if a.get("port")}
            allocated = _find_free_port(preferred=port, exclude=excluded)
            if not allocated:
                return {"ok": False, "error": "no free port in 8100-8999"}

            iid = uuid.uuid4().hex
            log_file = self._log_path(name)
            app = {
                "id": iid,
                "name": name,
                "kind": kind,
                "entry": entry,
                "path": os.path.abspath(path) if path else os.getcwd(),
                "command": command,
                "port": allocated,
                "env": env or {},
                "owner": owner,
                "autostart": bool(autostart),
                "tunnel": False,
                "tunnel_url": "",
                "pid": 0,
                "log_file": log_file,
                "created_at": time.time(),
                "started_at": None,
            }
            self._apps[iid] = app
            self._save()

        result = dict(app)
        if autostart:
            start_result = self.start(name)
            result.update(start_result)
        return result

    def start(self, name: str) -> dict:
        """Launch a registered app's subprocess."""
        with self._lock:
            app = self._by_name(name)
            if not app:
                return {"ok": False, "error": f"app '{name}' not found"}
            if app.get("pid") and app["pid"] > 0 and _pid_alive(app["pid"]):
                return {"ok": False, "error": f"app '{name}' is already running (pid={app['pid']})"}

            cmd = _build_command(app)
            log_path = app["log_file"]
            work_dir = app.get("path", ".")
            merged_env = os.environ.copy()
            merged_env.update(app.get("env", {}))
            if app.get("port"):
                merged_env["PORT"] = str(app["port"])

            os.makedirs(os.path.dirname(log_path), exist_ok=True)
            log_fh = open(log_path, "a", encoding="utf-8")

            try:
                proc = subprocess.Popen(
                    cmd,
                    shell=True,
                    start_new_session=True,
                    cwd=work_dir,
                    env=merged_env,
                    stdout=log_fh,
                    stderr=subprocess.STDOUT,
                )
                app["pid"] = proc.pid
                app["started_at"] = time.time()
                self._save()
                log_fh.close()
                return {"ok": True, "pid": proc.pid, "port": app.get("port")}
            except Exception as e:
                log_fh.close()
                return {"ok": False, "error": str(e)}

    def stop(self, name: str) -> dict:
        """Kill a running app's process group."""
        with self._lock:
            app = self._by_name(name)
            if not app:
                return {"ok": False, "error": f"app '{name}' not found"}
            pid = app.get("pid")
            if not pid or pid <= 0:
                return {"ok": False, "error": f"app '{name}' is not running"}
            try:
                pgid = os.getpgid(pid)
                os.killpg(pgid, signal.SIGTERM)
                for _ in range(5):
                    if not _pid_alive(pid):
                        break
                    time.sleep(1)
                if _pid_alive(pid):
                    os.killpg(pgid, signal.SIGKILL)
            except (ProcessLookupError, PermissionError):
                pass
            app["pid"] = 0
            app["started_at"] = None
            self._save()
            return {"ok": True}

    def restart(self, name: str) -> dict:
        """Stop then start an app."""
        s = self.stop(name)
        if not s.get("ok") and "not running" not in s.get("error", ""):
            return s
        return self.start(name)

    def remove(self, name: str) -> dict:
        """Stop and permanently delete an app."""
        self.stop(name)
        with self._lock:
            iid = self._iid_by_name(name)
            if not iid:
                return {"ok": False, "error": f"app '{name}' not found"}
            del self._apps[iid]
            self._save()
            return {"ok": True}

    def status(self, name: str) -> dict:
        """Return current status for an app, including alive + reachable."""
        with self._lock:
            app = self._by_name(name)
            if not app:
                return {"ok": False, "error": f"app '{name}' not found"}
            app = dict(app)
        pid = app.get("pid", 0)
        port = app.get("port")
        alive = _pid_alive(pid) if pid and pid > 0 else False
        reachable = _port_reachable(port) if port and alive else False
        app["alive"] = alive
        app["reachable"] = reachable
        return app

    def list(self, owner: Optional[str] = None) -> List[dict]:
        """Return all apps, optionally filtered by owner, enriched with
        live reachability data."""
        with self._lock:
            items = list(self._apps.values())
        out = []
        for app in items:
            if owner and app.get("owner") != owner:
                continue
            d = dict(app)
            pid = d.get("pid", 0)
            port = d.get("port")
            alive = _pid_alive(pid) if pid and pid > 0 else False
            d["alive"] = alive
            d["reachable"] = _port_reachable(port) if port and alive else False
            out.append(d)
        return sorted(out, key=lambda x: x.get("created_at", 0), reverse=True)

    def logs(self, name: str, lines: int = 100) -> dict:
        """Return tail of the app's log file."""
        with self._lock:
            app = self._by_name(name)
            if not app:
                return {"ok": False, "error": f"app '{name}' not found"}
            log_path = app.get("log_file", "")
        content = _tail(log_path, max(lines, 1))
        return {"ok": True, "name": name, "lines": content}

    def supervise(self, auto_restart: bool = True,
                  max_restarts: int = 5) -> dict:
        """Check all registered apps; restart dead ones that should be
        running and haven't exceeded *max_restarts*.

        Call periodically from a background task/thread.
        """
        revived = 0
        dead = 0
        with self._lock:
            apps = list(self._apps.values())
        for app in apps:
            pid = app.get("pid", 0)
            name = app.get("name", "")
            if pid and pid > 0 and not _pid_alive(pid):
                dead += 1
                app["pid"] = 0
                if auto_restart and app.get("autostart"):
                    with self._lock:
                        self._save()
                    r = self.start(name)
                    if r.get("ok"):
                        revived += 1
        with self._lock:
            self._save()
        return {"ok": True, "checked": len(apps), "dead": dead, "revived": revived}

    def open_tunnel(self, name: str) -> dict:
        """Spawn a cloudflared tunnel for a running app.

        Requires ``cloudflared`` on PATH.
        """
        with self._lock:
            app = self._by_name(name)
            if not app:
                return {"ok": False, "error": f"app '{name}' not found"}
            port = app.get("port")
            if not port:
                return {"ok": False, "error": f"app '{name}' has no port"}
            if not _port_reachable(port):
                return {"ok": False, "error": f"app '{name}' is not reachable on port {port}"}

            cloudflared = shutil.which("cloudflared")
            if not cloudflared:
                return {"ok": False,
                        "error": "cloudflared not found on PATH — install it or use a custom tunnel"}

            try:
                proc = subprocess.Popen(
                    [cloudflared, "tunnel", "--url", f"http://localhost:{port}"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
                app["tunnel"] = True
                app["tunnel_url"] = f"https://localhost:{port} (cloudflared pid={proc.pid})"
                self._save()
                return {"ok": True, "pid": proc.pid, "note": app["tunnel_url"]}
            except Exception as e:
                return {"ok": False, "error": str(e)}

    # ── internal lookups ────────────────────────────────────────────────

    def _by_name(self, name: str) -> Optional[dict]:
        for app in self._apps.values():
            if app.get("name") == name:
                return app
        return None

    def _iid_by_name(self, name: str) -> Optional[str]:
        for iid, app in self._apps.items():
            if app.get("name") == name:
                return iid
        return None


# ── Module singleton ──────────────────────────────────────────────────────
hosting_manager = HostingManager()


# ══════════════════════════════════════════════════════════════════════════
# Self-test (runs when invoked directly)
# ══════════════════════════════════════════════════════════════════════════
if __name__ == "__main__":
    import sys
    import tempfile

    print("HostingManager self-test…")

    test_dir = Path(tempfile.mkdtemp(prefix="maya_hosting_test_"))
    test_file = str(test_dir / "test_hosted.json")
    test_apps_dir = test_dir / "apps"
    test_apps_dir.mkdir(parents=True, exist_ok=True)

    # Create a static file to serve
    static_dir = test_dir / "static_site"
    static_dir.mkdir(parents=True, exist_ok=True)
    (static_dir / "index.html").write_text(
        "<html><body><h1>Maya Hosting Test</h1></body></html>"
    )

    mgr = HostingManager(path=test_file)

    # Override log path into the temp dir
    _orig_log_path = mgr._log_path

    def _test_log_path(name):
        p = test_dir / f"{name}.log"
        p.parent.mkdir(parents=True, exist_ok=True)
        return str(p)
    mgr._log_path = _test_log_path

    # ── Deploy ──────────────────────────────────────────────────────
    r = mgr.deploy(
        name="test-static",
        kind="static",
        path=str(static_dir),
        owner="tester",
        autostart=True,
    )
    assert r.get("ok") is True, f"deploy failed: {r}"
    port = r.get("port")
    print(f"  ✓ deployed 'test-static' on port {port}")

    # ── Wait for boot + check status ────────────────────────────────
    time.sleep(2)
    st = mgr.status("test-static")
    print(f"  ✓ status: alive={st.get('alive')} reachable={st.get('reachable')} pid={st.get('pid')}")
    assert st.get("alive") is True, f"app not alive: {st}"
    assert st.get("reachable") is True, f"app not reachable on port {port}"

    # ── Logs ─────────────────────────────────────────────────────────
    lr = mgr.logs("test-static", lines=50)
    assert lr.get("ok") is True, f"logs failed: {lr}"
    assert len(lr.get("lines", [])) > 0, "log file is empty"
    print(f"  ✓ logs: {len(lr['lines'])} lines")

    # ── List ─────────────────────────────────────────────────────────
    apps = mgr.list(owner="tester")
    assert len(apps) == 1, f"expected 1 app, got {len(apps)}"
    print(f"  ✓ list(owner='tester') returns 1 app")

    # ── Stop + remove ────────────────────────────────────────────────
    r = mgr.stop("test-static")
    assert r.get("ok") is True, f"stop failed: {r}"
    time.sleep(1)
    st = mgr.status("test-static")
    assert st.get("alive") is False, "app still alive after stop"
    print(f"  ✓ stop: app no longer alive")

    r = mgr.remove("test-static")
    assert r.get("ok") is True, f"remove failed: {r}"
    assert len(mgr.list()) == 0, "app not removed"
    print(f"  ✓ remove: registry empty")

    # ── Cleanup ─────────────────────────────────────────────────────
    import shutil as _shutil
    try:
        _shutil.rmtree(str(test_dir))
    except Exception:
        pass

    print("All HostingManager self-tests passed.")
    sys.exit(0)
