"""Risk assessment for user goals.

Expanded categories for the phone approval gate (T1.3):

  HIGH      — dangerous action that blocks the goal until the phone user
              approves or rejects it via POST /api/v1/approvals/{id}/approve
              or /reject.  The handler also pushes a phone notification so
              the user knows something needs their attention.

  MEDIUM    — risky action that may warn the user; only gates in "human"
              approval mode.

  LOW       — safe, passes without any gate.
"""

from typing import Dict
from config.constants import RISK_LOW, RISK_MEDIUM, RISK_HIGH, RISK_CRITICAL


class RiskChecker:
    """Pattern-based risk classifier for Maya goals & tool calls."""

    # ── HIGH: action is blocked, phone approval required ────────────
    HIGH_RISK_KEYWORDS = [
        # Deleting a server / app / container
        "delete server", "destroy server", "terminate server",
        "delete app", "destroy app", "delete container",
        "destroy container", "remove container",
        "deprovision", "decommission",
        # Dropping / wiping a database
        "drop database", "drop table", "truncate table",
        "wipe database", "clear database", "delete database",
        # Spending money
        "spend money", "spend", "buy", "purchase", "charge", "pay",
        # Destructive shell commands
        "rm -rf /", "rm -rf /*", "rm -rf ~",
        "chmod 0", "chmod 000", "dd if=",
        "shutdown", "reboot", "poweroff", "halt",
        "kill -9", "killall",
        "sudo rm",
        # Filesystem destruction
        "format", "mkfs",
    ]

    # ── MEDIUM: risky, warns user but doesn't block in auto mode ────
    MEDIUM_RISK_KEYWORDS = [
        "delete", "remove", "kill", "stop", "disable",
        "terminate", "suspend", "uninstall",
    ]

    def check(self, action: str) -> Dict:
        """Return risk assessment for *action* (a goal string or tool call).

        Returns ``{"level", "reason", "allow"}``.  When ``allow`` is
        ``False`` the caller (``Maya.run``) returns immediately without
        executing the goal.
        """
        action_lower = action.lower()
        for kw in self.HIGH_RISK_KEYWORDS:
            if kw in action_lower:
                return {
                    "level": RISK_HIGH,
                    "reason": f"Dangerous keyword: {kw}",
                    "allow": False,  # blocked until phone approval
                }
        for kw in self.MEDIUM_RISK_KEYWORDS:
            if kw in action_lower:
                return {
                    "level": RISK_MEDIUM,
                    "reason": f"Risky keyword: {kw}",
                    "allow": True,
                    "warn": True,
                }
        return {"level": RISK_LOW, "reason": "Safe", "allow": True}

    def is_safe(self, action: str) -> bool:
        """Quick safety check — True if action passes without any gate."""
        return self.check(action).get("allow", False)
