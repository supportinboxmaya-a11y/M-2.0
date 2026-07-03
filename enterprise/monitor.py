"""Admin monitoring dashboard: one payload aggregating all subsystems.

Every source is optional — the dashboard degrades gracefully.
"""
import time


class Monitor:
    def __init__(self, metrics=None, agent_registry=None, provider_stats=None,
                 audit: "AuditLog|None" = None):
        self.metrics = metrics
        self.agents = agent_registry
        self.providers = provider_stats
        self.audit = audit
        self._started = time.time()

    def dashboard(self) -> dict:
        out = {"generated_at": time.time(),
               "monitor_uptime_s": round(time.time() - self._started, 1)}
        try:
            out["metrics"] = self.metrics.snapshot() if self.metrics else None
        except Exception as e:
            out["metrics"] = {"error": str(e)}
        try:
            out["agents"] = self.agents.health_report() if self.agents else None
        except Exception as e:
            out["agents"] = {"error": str(e)}
        try:
            out["providers"] = self.providers.snapshot() if self.providers else None
        except Exception as e:
            out["providers"] = {"error": str(e)}
        try:
            out["recent_audit"] = self.audit.query(limit=20) if self.audit else None
        except Exception as e:
            out["recent_audit"] = {"error": str(e)}
        return out
