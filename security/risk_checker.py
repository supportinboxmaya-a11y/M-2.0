from typing import Dict
from config.constants import RISK_LOW, RISK_MEDIUM, RISK_HIGH, RISK_CRITICAL

class RiskChecker:
    HIGH_RISK_KEYWORDS = ["rm -rf", "format", "delete all", "drop table", "sudo rm", "mkfs"]
    MEDIUM_RISK_KEYWORDS = ["delete", "remove", "kill", "stop", "disable"]

    def check(self, action: str) -> Dict:
        action_lower = action.lower()
        for kw in self.HIGH_RISK_KEYWORDS:
            if kw in action_lower:
                return {"level": RISK_HIGH, "reason": f"Dangerous keyword: {kw}", "allow": False}
        for kw in self.MEDIUM_RISK_KEYWORDS:
            if kw in action_lower:
                return {"level": RISK_MEDIUM, "reason": f"Risky keyword: {kw}", "allow": True, "warn": True}
        return {"level": RISK_LOW, "reason": "Safe", "allow": True}

    def is_safe(self, action: str) -> bool:
        return self.check(action).get("allow", False)
