"""
Maya 2.0 - Sandbox (Hardened)
-----------------------------
Confinement primitives shared by code-executing tools.

1. safe_path()      : workspace path confinement. The old check used a
                      raw startswith(), so a sibling directory like
                      "/workspace_evil" passed for "/workspace" — fixed
                      with a proper boundary-aware comparison.
2. scrubbed_env()   : minimal environment for child processes. The old
                      code runner passed the FULL parent environment to
                      executed code, so one line (`os.environ`) leaked
                      every API key. Children now see only PATH/HOME/
                      LANG — no secrets.
3. resource_limiter(): preexec hook applying kernel rlimits — memory,
                      CPU seconds, process count (fork bombs), and max
                      file size. No-op on platforms without `resource`
                      (e.g. Windows), where the wall-clock timeout still
                      applies.

Defaults are configurable via environment variables:
    SANDBOX_MEMORY_MB (512), SANDBOX_MAX_PROCS (64),
    SANDBOX_FSIZE_MB (50)
"""

import os
from typing import Callable, Optional

from config.settings import WORKSPACE_DIR

DEFAULT_MEMORY_MB = int(os.environ.get("SANDBOX_MEMORY_MB", "512"))
DEFAULT_MAX_PROCS = int(os.environ.get("SANDBOX_MAX_PROCS", "64"))
DEFAULT_FSIZE_MB = int(os.environ.get("SANDBOX_FSIZE_MB", "50"))


class Sandbox:
    """Restricts file operations to the workspace directory and provides
    hardened execution primitives for child processes."""

    def __init__(self, workspace: Optional[str] = None):
        self.workspace = os.path.realpath(str(workspace or WORKSPACE_DIR))

    # ── path confinement ──────────────────────────────────────────
    def safe_path(self, path: str) -> str:
        full = os.path.realpath(os.path.join(self.workspace, path))
        # Boundary-aware: equal to the workspace, or inside it. A plain
        # startswith() let "/workspace_evil" through for "/workspace".
        if full != self.workspace and \
                not full.startswith(self.workspace + os.sep):
            raise PermissionError(f"Access denied: {path} is outside workspace")
        return full

    def is_safe_path(self, path: str) -> bool:
        try:
            self.safe_path(path)
            return True
        except PermissionError:
            return False

    # ── execution hardening ───────────────────────────────────────
    def scrubbed_env(self) -> dict:
        """Minimal child environment — never inherits API keys/secrets."""
        return {
            "PATH": os.environ.get("PATH", "/usr/local/bin:/usr/bin:/bin"),
            "HOME": self.workspace,
            "LANG": os.environ.get("LANG", "C.UTF-8"),
            "LC_ALL": os.environ.get("LC_ALL", "C.UTF-8"),
            "PYTHONPATH": "",
            "PYTHONDONTWRITEBYTECODE": "1",
        }

    @staticmethod
    def resource_limiter(memory_mb: int = DEFAULT_MEMORY_MB,
                         cpu_seconds: int = 30,
                         max_procs: int = DEFAULT_MAX_PROCS,
                         fsize_mb: int = DEFAULT_FSIZE_MB
                         ) -> Optional[Callable]:
        """Returns a preexec_fn applying rlimits in the child, or None on
        platforms without the `resource` module (Windows)."""
        try:
            import resource
        except ImportError:
            return None

        def _apply():
            def _set(limit, value):
                try:
                    resource.setrlimit(limit, (value, value))
                except (ValueError, OSError):
                    pass  # container may already enforce a lower cap

            _set(resource.RLIMIT_AS, memory_mb * 1024 * 1024)
            _set(resource.RLIMIT_CPU, max(1, int(cpu_seconds)))
            _set(resource.RLIMIT_FSIZE, fsize_mb * 1024 * 1024)
            if hasattr(resource, "RLIMIT_NPROC"):
                _set(resource.RLIMIT_NPROC, max_procs)
            try:
                os.setsid()  # own process group -> clean kill on timeout
            except OSError:
                pass

        return _apply
