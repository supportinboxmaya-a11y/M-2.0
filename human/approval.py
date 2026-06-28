from config.constants import APPROVAL_AUTO, APPROVAL_HUMAN, RISK_HIGH

class ApprovalManager:
    def __init__(self, mode: str = APPROVAL_AUTO):
        self.mode = mode

    def needs_approval(self, action: str, risk_level: str = "low") -> bool:
        if self.mode == APPROVAL_AUTO:
            return risk_level in [RISK_HIGH, "critical"]
        elif self.mode == APPROVAL_HUMAN:
            return True
        return False

    def request_approval(self, action: str, reason: str = "") -> bool:
        print(f"\n⚠️  Approval needed: {action}")
        if reason:
            print(f"   Reason: {reason}")
        response = input("   Approve? (y/n): ").strip().lower()
        return response == "y"
