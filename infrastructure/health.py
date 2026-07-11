"""
Maya 2.0 - Deployment Health & Monitoring
-----------------------------------------
Production-grade health checks and system info for deployment behind a
load balancer / orchestrator (Render, Kubernetes, Docker).

Three levels:
    liveness()   - is the process up? (cheap, never touches deps) →
                   used by orchestrators to decide whether to restart.
    readiness()  - can we actually serve traffic? checks storage is
                   writable, the SQLite layer works, and at least one
                   LLM provider is configured → used to gate traffic.
    system_info() - process/runtime metrics (uptime, memory, python,
                   platform) for dashboards and debugging.

Everything is dependency-light (stdlib + optional psutil) and every
check is wrapped so a failing probe reports "unhealthy" instead of
raising.
"""

import os
import platform
import shutil
import sqlite3
import time
from typing import Dict

from config.settings import STORAGE_DIR

_START_TIME = time.time()


class HealthMonitor:
    """Liveness / readiness / system info for deployment."""

    def __init__(self, provider_checker=None):
        # provider_checker() -> list[str] of available LLM providers.
        self.provider_checker = provider_checker

    # ── liveness ──────────────────────────────────────────────────
    def liveness(self) -> Dict:
        """Cheap: the process is running and can respond."""
        return {"status": "alive", "uptime_seconds": round(self.uptime(), 1)}

    # ── readiness ─────────────────────────────────────────────────
    def readiness(self) -> Dict:
        """Deep: can we serve real requests? Aggregates dependency checks."""
        checks = {
            "storage_writable": self._check_storage(),
            "database": self._check_sqlite(),
            "llm_provider": self._check_providers(),
        }
        ready = all(c["ok"] for c in checks.values())
        return {"status": "ready" if ready else "not_ready",
                "ready": ready, "checks": checks,
                "uptime_seconds": round(self.uptime(), 1)}

    # ── individual checks ─────────────────────────────────────────
    @staticmethod
    def _check_storage() -> Dict:
        try:
            STORAGE_DIR.mkdir(parents=True, exist_ok=True)
            probe = STORAGE_DIR / ".health_probe"
            probe.write_text("ok")
            probe.unlink()
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    @staticmethod
    def _check_sqlite() -> Dict:
        try:
            conn = sqlite3.connect(":memory:")
            conn.execute("SELECT 1")
            conn.close()
            return {"ok": True}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    def _check_providers(self) -> Dict:
        try:
            if self.provider_checker is None:
                # fall back to scanning common env keys
                keys = ["GROQ_KEY", "GROQ_API_KEY", "GEMINI_KEY",
                        "GEMINI_API_KEY", "OPENAI_KEY", "OPENAI_API_KEY",
                        "ANTHROPIC_KEY", "ANTHROPIC_API_KEY"]
                available = [k for k in keys if os.getenv(k)]
                ok = len(available) > 0
                return {"ok": ok, "configured": ok}
            providers = self.provider_checker() or []
            return {"ok": len(providers) > 0, "providers": list(providers)}
        except Exception as e:
            return {"ok": False, "error": str(e)}

    # ── system info ───────────────────────────────────────────────
    def system_info(self) -> Dict:
        info = {
            "uptime_seconds": round(self.uptime(), 1),
            "python_version": platform.python_version(),
            "platform": platform.platform(),
            "pid": os.getpid(),
        }
        # Disk usage of the storage volume (useful for capacity alerts).
        try:
            total, used, free = shutil.disk_usage(str(STORAGE_DIR))
            info["disk"] = {"total_mb": total // (1024 * 1024),
                            "used_mb": used // (1024 * 1024),
                            "free_mb": free // (1024 * 1024),
                            "percent_used": round(used / total * 100, 1)}
        except Exception:
            info["disk"] = None
        # Memory (optional — only if psutil is installed).
        try:
            import psutil
            p = psutil.Process(os.getpid())
            info["memory"] = {"rss_mb": round(p.memory_info().rss / (1024 * 1024), 1),
                              "percent": round(p.memory_percent(), 1)}
            info["cpu_percent"] = psutil.cpu_percent(interval=None)
        except Exception:
            info["memory"] = None
        return info

    # ── helpers ───────────────────────────────────────────────────
    @staticmethod
    def uptime() -> float:
        return time.time() - _START_TIME
