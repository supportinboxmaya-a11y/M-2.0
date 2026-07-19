"""
Maya 2.0 — Remote VPS Deployer
-------------------------------
Deploys and manages Docker containers on a remote VPS over SSH.

Uses **paramiko** (when installed) with automatic fallback to the system
``ssh`` / ``scp`` CLI binaries.  Reads VPS credentials exclusively from
environment variables — never hardcodes secrets.

Approved env vars:
  VPS_HOST           — hostname or IP (required to be configured)
  VPS_PORT           — SSH port (default 22)
  VPS_USER           — SSH user (default root)
  VPS_PASSWORD       — password auth (optional, mutually-exclusive with key)
  VPS_SSH_KEY_PATH   — path to private key file (optional, takes precedence)

Design matches ``hosting_manager.py``: threading lock, JSON persistence,
module singleton ``remote_deployer``.
"""

import json
import os
import shutil
import subprocess
import threading
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

# ── Constants ──────────────────────────────────────────────────────────────

VPS_STATE_FILE = str(STORAGE_DIR / "remote_vps.json")
DEFAULT_SSH_PORT = 22

# ── Optional paramiko ──────────────────────────────────────────────────────

_HAS_PARAMIKO = False
try:
    import paramiko  # type: ignore[import-untyped]
    _HAS_PARAMIKO = True
except ImportError:
    pass


class RemoteDeployer:
    """Deploy and manage Docker containers on a remote VPS over SSH.

    Thread-safe via ``_lock``.  State (running container metadata) is
    persisted to ``VPS_STATE_FILE`` for introspection across restarts.

    All public methods return ``{"ok": bool, ...}`` dicts matching the
    ``HostingManager`` contract used throughout the codebase.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._state: Dict[str, dict] = {}
        self._load()

    # ── public queries ────────────────────────────────────────────────────────

    @property
    def configured(self) -> bool:
        """``True`` when ``VPS_HOST`` is set to a non-empty value."""
        return bool(os.environ.get("VPS_HOST", "").strip())

    @property
    def config(self) -> dict:
        """Current VPS connection info (no secrets leaked in output)."""
        return {
            "host": os.environ.get("VPS_HOST", ""),
            "port": int(os.environ.get("VPS_PORT", str(DEFAULT_SSH_PORT))),
            "user": os.environ.get("VPS_USER", ""),
            "has_password": bool(os.environ.get("VPS_PASSWORD", "")),
            "has_key": bool(os.environ.get("VPS_SSH_KEY_PATH", "")),
            "ssh_cmd": shutil.which("ssh"),
            "scp_cmd": shutil.which("scp"),
            "paramiko": _HAS_PARAMIKO,
        }

    def list_containers(self) -> List[dict]:
        """List running Docker containers on the remote VPS.

        Parses ``docker ps --format '{{json .}}'`` output into a list of
        dicts.  Returns an empty list on failure (caller should inspect
        ``container_logs`` or the error for details).
        """
        try:
            out = self._ssh("docker ps --format '{{json .}}'")
        except RuntimeError:
            return []

        containers: List[dict] = []
        for line in out.strip().splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                containers.append(json.loads(line))
            except json.JSONDecodeError:
                pass
        return containers

    # ── lifecycle ─────────────────────────────────────────────────────────────

    def build_image(self, app: str, dockerfile_dir: str) -> dict:
        """SSH into VPS and run ``docker build -t <app> <dockerfile_dir>``.

        Returns ``{"ok": True, "app": ..., "output": ...}`` or
        ``{"ok": False, "error": ...}``.
        """
        cmd = f"docker build -t {self._q(app)} {self._q(dockerfile_dir)}"
        try:
            out = self._ssh(cmd)
            return {"ok": True, "app": app, "output": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    def run_container(
        self,
        app: str,
        image: str,
        ports: Optional[Dict[str, str]] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> dict:
        """SSH into VPS and ``docker run -d --name <app> ... <image>``.

        *ports* maps ``"host_port" → "container_port"`` (or
        ``"host_port/proto" → "container_port"``).
        *env* maps env var names to values passed as ``-e`` flags.

        Persists container metadata to the state file.
        """
        parts = ["docker run -d", f"--name {self._q(app)}"]
        if ports:
            for host_p, cont_p in ports.items():
                parts.append(f"-p {self._q(host_p)}:{self._q(cont_p)}")
        if env:
            for k, v in env.items():
                parts.append(f"-e {self._q(k)}={self._q(v)}")
        parts.append("--restart unless-stopped")
        parts.append(self._q(image))

        cmd = " ".join(parts)
        try:
            out = self._ssh(cmd)
            container_id = out.strip()
            self._save_app_state(
                app,
                {
                    "container_name": app,
                    "image": image,
                    "ports": ports,
                    "env_vars": list(env.keys()) if env else [],
                    "container_id": container_id,
                },
            )
            return {"ok": True, "app": app, "container_id": container_id, "output": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    def stop_container(self, app: str) -> dict:
        """SSH ``docker stop <app>``."""
        try:
            out = self._ssh(f"docker stop {self._q(app)}")
            return {"ok": True, "app": app, "output": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    def start_container(self, app: str) -> dict:
        """SSH ``docker start <app>``."""
        try:
            out = self._ssh(f"docker start {self._q(app)}")
            return {"ok": True, "app": app, "output": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    def restart_container(self, app: str) -> dict:
        """SSH ``docker restart <app>``."""
        try:
            out = self._ssh(f"docker restart {self._q(app)}")
            return {"ok": True, "app": app, "output": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    def remove_container(self, app: str) -> dict:
        """SSH ``docker rm -f <app>``.

        **Destructive** — caller MUST gate through the approval system.
        """
        try:
            out = self._ssh(f"docker rm -f {self._q(app)}")
            self._remove_app_state(app)
            return {"ok": True, "app": app, "output": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    def container_logs(self, app: str, lines: int = 100) -> dict:
        """SSH ``docker logs --tail <lines> <app>``."""
        try:
            out = self._ssh(f"docker logs --tail {lines} {self._q(app)}")
            return {"ok": True, "app": app, "logs": out}
        except RuntimeError as e:
            return {"ok": False, "error": str(e)}

    # ── internal SSH helpers ──────────────────────────────────────────────────

    def _ssh(self, cmd: str) -> str:
        """Execute *cmd* on the remote VPS and return stdout.

        Uses **paramiko** when installed, otherwise shells out to the
        ``ssh`` CLI binary.  Raises ``RuntimeError`` on any failure
        (connection, non-zero exit, timeout, etc.).
        """
        host = os.environ.get("VPS_HOST", "").strip()
        if not host:
            raise RuntimeError("VPS not configured (VPS_HOST is not set)")

        port_str = os.environ.get("VPS_PORT", str(DEFAULT_SSH_PORT)).strip()
        user = os.environ.get("VPS_USER", "root").strip()
        password = os.environ.get("VPS_PASSWORD", "")
        key_path = os.environ.get("VPS_SSH_KEY_PATH", "")

        if _HAS_PARAMIKO:
            return self._ssh_paramiko(host, int(port_str), user, password, key_path, cmd)
        return self._ssh_cli(host, port_str, user, password, key_path, cmd)

    def _ssh_paramiko(
        self,
        host: str,
        port: int,
        user: str,
        password: str,
        key_path: str,
        cmd: str,
    ) -> str:
        """SSH via the ``paramiko`` library."""
        client = paramiko.SSHClient()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            if key_path and os.path.isfile(key_path):
                client.connect(
                    host,
                    port=port,
                    username=user,
                    key_filename=key_path,
                    timeout=15,
                )
            else:
                client.connect(
                    host, port=port, username=user, password=password, timeout=15
                )

            _stdin, stdout, stderr = client.exec_command(cmd, timeout=30)
            out = stdout.read().decode("utf-8", errors="replace")
            err = stderr.read().decode("utf-8", errors="replace")
            rc = stdout.channel.recv_exit_status()
            if rc != 0:
                raise RuntimeError(f"SSH command failed (rc={rc}): {err.strip()}")
            return out
        except Exception as e:
            raise RuntimeError(f"paramiko SSH error: {e}")
        finally:
            client.close()

    def _ssh_cli(
        self,
        host: str,
        port: str,
        user: str,
        password: str,
        key_path: str,
        cmd: str,
    ) -> str:
        """SSH via the system ``ssh`` binary."""
        ssh_path = shutil.which("ssh")
        if not ssh_path:
            raise RuntimeError("ssh binary not found on PATH")

        args = [
            ssh_path,
            "-o", "StrictHostKeyChecking=no",
            "-o", "UserKnownHostsFile=/dev/null",
            "-p", port,
        ]

        if key_path and os.path.isfile(key_path):
            args += ["-i", key_path]

        target = f"{user}@{host}"

        # If password is set and sshpass is available, use it non-interactively
        if password and shutil.which("sshpass"):
            args = [shutil.which("sshpass"), "-e"] + args
            os.environ["SSHPASS"] = password

        args += [target, cmd]

        try:
            result = subprocess.run(
                args, capture_output=True, text=True, timeout=60
            )
        except subprocess.TimeoutExpired:
            raise RuntimeError("SSH command timed out after 60s")

        if result.returncode != 0:
            err = (result.stderr or result.stdout or "").strip()
            raise RuntimeError(f"SSH CLI failed (rc={result.returncode}): {err}")

        return result.stdout

    @staticmethod
    def _q(s: str) -> str:
        """Shell-quote a string for safe single-command SSH usage."""
        escaped = s.replace("'", "'\\''")
        return f"'{escaped}'"

    # ── state persistence ─────────────────────────────────────────────────────

    def _save_app_state(self, app: str, data: dict) -> None:
        with self._lock:
            self._state[app] = data
            self._save()

    def _remove_app_state(self, app: str) -> None:
        with self._lock:
            self._state.pop(app, None)
            self._save()

    def _load(self) -> None:
        try:
            with open(VPS_STATE_FILE) as f:
                self._state = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            self._state = {}

    def _save(self) -> None:
        try:
            with open(VPS_STATE_FILE, "w") as f:
                json.dump(self._state, f, indent=2)
        except OSError:
            pass


# ── Module singleton ──────────────────────────────────────────────────────────
remote_deployer = RemoteDeployer()
