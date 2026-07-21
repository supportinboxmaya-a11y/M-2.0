"""
Maya 2.0 — Phase 31: Build → Deploy Pipeline
---------------------------------------------
Orchestrates the full lifecycle: validate local source → SCP to VPS →
docker build → docker run → auto-register in Phase 30 AppRegistry.

Delegates to ``remote_deployer`` (SSH + Docker) and ``app_registry``
(remote container registry).  No reinvention of SSH, Docker, or registry.

Thread-safe via ``_lock``.  ``plan()`` is pure-local validation — no SSH,
no side effects.  ``execute()`` is state-changing — callers MUST gate
through RBAC + RiskChecker + ApprovalManager (see api.py Phase 31 block).
"""

import os
import shutil
import subprocess
import tarfile
import threading
import time
import tempfile
from typing import Dict, List, Optional

from infrastructure.remote_deploy import remote_deployer, DEFAULT_SSH_PORT
from infrastructure.app_registry import app_registry

DEPLOY_PIPELINE_ENABLED = (
    os.environ.get("DEPLOY_PIPELINE_ENABLED", "false").lower() == "true"
)


class DeployPipeline:
    """Orchestrate build->deploy->register on the remote VPS.

    Delegates SSH and Docker operations to ``remote_deployer`` (module
    singleton) and registry writes to ``app_registry``.

    Parameters
    ----------
    rd : optional
        Mockable remote_deployer replacement.  Defaults to the module
        singleton ``infrastructure.remote_deploy.remote_deployer``.
    ar : optional
        Mockable app_registry replacement.  Defaults to the module
        singleton ``infrastructure.app_registry.app_registry``.
    """

    def __init__(
        self,
        rd=None,
        ar=None,
    ) -> None:
        self._lock = threading.Lock()
        self._rd = rd or remote_deployer
        self._ar = ar or app_registry
        self._last_result: Optional[dict] = None

    # ── Public API ────────────────────────────────────────────────────────────

    def plan(
        self,
        app_name: str,
        source_dir: str,
        ports: Optional[Dict[str, str]] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> dict:
        """Validate inputs and return a step-by-step plan.

        Reads ``source_dir/Dockerfile`` locally.  No SSH, no changes to
        the VPS or registry.
        """
        warnings: List[str] = []
        errors: List[str] = []

        # Validate app_name
        if not app_name or not app_name.strip():
            errors.append("app_name is required")
        elif not app_name.replace("-", "").replace("_", "").isalnum():
            warnings.append(
                "app_name contains special chars — docker may truncate"
            )

        # Validate source_dir
        if not source_dir:
            errors.append("source_dir is required")
        else:
            resolved = os.path.abspath(os.path.expanduser(source_dir))
            if not os.path.isdir(resolved):
                errors.append(f"source_dir not found: {resolved}")
            elif not os.path.isfile(os.path.join(resolved, "Dockerfile")):
                errors.append(f"No Dockerfile found in {resolved}")

        # Validate VPS configured
        if not self._rd.configured:
            errors.append("Remote VPS not configured (VPS_HOST not set)")

        steps: List[dict] = [
            {
                "step": 1,
                "action": "SCP source directory to VPS",
                "detail": (
                    f"tar+scp {source_dir} "
                    f"\u2192 VPS:/tmp/deploy-{app_name}-<ts>/"
                ),
            },
            {
                "step": 2,
                "action": "Docker build",
                "detail": f"docker build -t {app_name} on VPS",
            },
            {
                "step": 3,
                "action": "Docker run",
                "detail": self._run_cmd_template(app_name, ports, env),
            },
            {
                "step": 4,
                "action": "Register in AppRegistry",
                "detail": f"app_registry.register(name={app_name}, ...)",
            },
        ]

        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "steps": steps,
            "estimated_impact": (
                "Builds and runs a Docker container on the remote VPS. "
                "Consumes disk and CPU on the VPS during build. "
                "Creates a new container and registers it in the monitoring "
                "registry."
            ),
        }

    def execute(
        self,
        app_name: str,
        source_dir: str,
        ports: Optional[Dict[str, str]] = None,
        env: Optional[Dict[str, str]] = None,
        confirm: bool = False,
    ) -> dict:
        """Execute the full build\u2192deploy\u2192register pipeline.

        If ``confirm`` is ``False`` (the default), returns a plan-only
        preview without making any changes (same as ``plan()``).
        """
        if not confirm:
            plan_result = self.plan(app_name, source_dir, ports, env)
            return {
                "ok": False,
                "detail": "Dry-run \u2014 set confirm=true to execute",
                "plan": plan_result,
            }

        # Validate first
        plan_result = self.plan(app_name, source_dir, ports, env)
        if not plan_result["valid"]:
            return {
                "ok": False,
                "detail": "Validation failed",
                "errors": plan_result["errors"],
                "plan": plan_result,
            }

        resolved = os.path.abspath(os.path.expanduser(source_dir))
        timestamp = int(time.time())
        remote_dir = f"/tmp/deploy-{app_name}-{timestamp}"
        steps_log: List[dict] = []
        container_id = ""

        with self._lock:
            try:
                # ── Step 1: SCP source to VPS ────────────────────────
                steps_log.append(
                    {"step": 1, "action": "SCP source", "status": "running"}
                )
                self._scp_to_vps(resolved, remote_dir)
                steps_log[-1]["status"] = "done"
                steps_log[-1]["detail"] = f"{resolved} \u2192 {remote_dir}"

                # ── Step 2: Docker build ─────────────────────────────
                steps_log.append(
                    {"step": 2, "action": "docker build", "status": "running"}
                )
                build_result = self._rd.build_image(app_name, remote_dir)
                if not build_result.get("ok"):
                    raise RuntimeError(
                        f"Docker build failed: "
                        f"{build_result.get('error', 'unknown error')}"
                    )
                steps_log[-1]["status"] = "done"
                steps_log[-1]["detail"] = build_result.get("output", "")

                # ── Step 3: Docker run ───────────────────────────────
                steps_log.append(
                    {"step": 3, "action": "docker run", "status": "running"}
                )
                run_result = self._rd.run_container(
                    app=app_name,
                    image=app_name,
                    ports=ports,
                    env=env,
                )
                if not run_result.get("ok"):
                    raise RuntimeError(
                        f"Docker run failed: "
                        f"{run_result.get('error', 'unknown error')}"
                    )
                container_id = run_result.get("container_id", "")
                steps_log[-1]["status"] = "done"
                steps_log[-1]["detail"] = f"container_id={container_id}"

                # ── Step 4: Register in AppRegistry ──────────────────
                steps_log.append(
                    {
                        "step": 4,
                        "action": "register in AppRegistry",
                        "status": "running",
                    }
                )
                host = os.environ.get("VPS_HOST", "")
                registry_entry = self._ar.register(
                    name=app_name,
                    container_id=container_id,
                    image=app_name,
                    host=host,
                )
                steps_log[-1]["status"] = "done"
                steps_log[-1]["detail"] = f"app_registry name={app_name}"

                result: dict = {
                    "ok": True,
                    "app_name": app_name,
                    "container_id": container_id,
                    "registry_entry": registry_entry,
                    "steps_log": steps_log,
                    "rollback_actions": [],
                }

            except Exception as e:
                # ── Rollback ─────────────────────────────────────────
                rollback_log: List[str] = []

                # Remove remote dir if SCP completed (step 1)
                if (
                    len(steps_log) >= 1
                    and steps_log[0]["status"] == "done"
                ):
                    try:
                        self._rd._ssh(f"rm -rf {remote_dir} 2>/dev/null")
                        rollback_log.append(f"rm -rf {remote_dir}")
                    except RuntimeError as rb_err:
                        rollback_log.append(
                            f"rollback rm -rf failed: {rb_err}"
                        )

                # Remove image if build completed (step 2)
                if (
                    len(steps_log) >= 2
                    and steps_log[1]["status"] == "done"
                ):
                    try:
                        q = self._rd._q(app_name)
                        self._rd._ssh(f"docker rmi {q} 2>/dev/null")
                        rollback_log.append(f"docker rmi {app_name}")
                    except RuntimeError as rb_err:
                        rollback_log.append(
                            f"rollback docker rmi failed: {rb_err}"
                        )

                # Remove container if run completed (step 3)
                if container_id:
                    short = container_id[:12]
                    try:
                        q = self._rd._q(short)
                        self._rd._ssh(f"docker rm -f {q} 2>/dev/null")
                        rollback_log.append(f"docker rm -f {short}")
                    except RuntimeError:
                        pass

                result = {
                    "ok": False,
                    "app_name": app_name,
                    "error": str(e),
                    "steps_log": steps_log,
                    "rollback_actions": rollback_log,
                }

            self._last_result = result
            return result

    def status(self) -> dict:
        """Return the last pipeline execution result, or ``None``."""
        return {
            "has_result": self._last_result is not None,
            "result": self._last_result,
        }

    # ── Internal helpers ─────────────────────────────────────────────────

    def _scp_to_vps(self, local_path: str, remote_path: str) -> None:
        """Tar the local directory, SCP to VPS, extract remotely.

        Uses system ``tar``, ``scp``, and ``ssh`` binaries.
        Authenticates via the same env vars as ``RemoteDeployer``.
        """
        host = os.environ.get("VPS_HOST", "").strip()
        if not host:
            raise RuntimeError("VPS not configured (VPS_HOST is not set)")
        port = os.environ.get("VPS_PORT", str(DEFAULT_SSH_PORT)).strip()
        user = os.environ.get("VPS_USER", "root").strip()
        password = os.environ.get("VPS_PASSWORD", "")
        key_path = os.environ.get("VPS_SSH_KEY_PATH", "")

        scp_bin = shutil.which("scp")
        ssh_bin = shutil.which("ssh")
        tar_bin = shutil.which("tar")
        if not scp_bin:
            raise RuntimeError("scp binary not found on PATH")
        if not tar_bin:
            raise RuntimeError("tar binary not found on PATH")

        # Create tar archive in a temp location
        dir_name = os.path.basename(local_path.rstrip("/"))
        fd, tar_path = tempfile.mkstemp(suffix=".tar.gz")
        os.close(fd)
        try:
            with tarfile.open(tar_path, "w:gz") as tar:
                tar.add(local_path, arcname=dir_name)

            # ── SCP the tar to VPS ──────────────────────────────────
            scp_args = [
                scp_bin,
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-P", port,
            ]
            if key_path and os.path.isfile(key_path):
                scp_args += ["-i", key_path]
            if password and shutil.which("sshpass"):
                scp_args = [shutil.which("sshpass"), "-e"] + scp_args
                os.environ["SSHPASS"] = password

            scp_args += [tar_path, f"{user}@{host}:{remote_path}.tar.gz"]

            scp_result = subprocess.run(
                scp_args, capture_output=True, text=True, timeout=120
            )
            if scp_result.returncode != 0:
                err = (scp_result.stderr or scp_result.stdout or "").strip()
                raise RuntimeError(f"SCP failed: {err}")

            # ── SSH to create target dir and extract ────────────────
            ssh_args = [
                ssh_bin,
                "-o", "StrictHostKeyChecking=no",
                "-o", "UserKnownHostsFile=/dev/null",
                "-p", port,
            ]
            if key_path and os.path.isfile(key_path):
                ssh_args += ["-i", key_path]
            if password and shutil.which("sshpass"):
                ssh_args = [shutil.which("sshpass"), "-e"] + ssh_args
                os.environ["SSHPASS"] = password

            extract_cmd = (
                f"mkdir -p {remote_path} && "
                f"tar xzf {remote_path}.tar.gz -C {remote_path} && "
                f"rm {remote_path}.tar.gz"
            )
            ssh_args += [f"{user}@{host}", extract_cmd]

            ssh_result = subprocess.run(
                ssh_args, capture_output=True, text=True, timeout=60
            )
            if ssh_result.returncode != 0:
                err = (ssh_result.stderr or ssh_result.stdout or "").strip()
                raise RuntimeError(f"SSH extract failed: {err}")
        finally:
            try:
                os.remove(tar_path)
            except OSError:
                pass

    @staticmethod
    def _run_cmd_template(
        app_name: str,
        ports: Optional[Dict[str, str]] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> str:
        """Return the concrete ``docker run`` command for display in plans."""
        parts = ["docker run -d", f"--name {app_name}"]
        if ports:
            for host_p, cont_p in ports.items():
                parts.append(f"-p {host_p}:{cont_p}")
        if env:
            for k in env:
                parts.append(f"-e {k}=<redacted>")
        parts.append("--restart unless-stopped")
        parts.append(app_name)
        return " ".join(parts)


# ── Module singleton ────────────────────────────────────────────────────────
deploy_pipeline = DeployPipeline()
