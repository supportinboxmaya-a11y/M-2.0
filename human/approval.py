from config.constants import APPROVAL_AUTO, APPROVAL_HUMAN, RISK_HIGH

class ApprovalManager:
    def __init__(self, mode: str = APPROVAL_AUTO):
        self.mode = mode
        # Pluggable hook. api.py sets this at startup to a function that
        # creates a web-based approval request (shown on the Approvals page,
        # pushed live over the websocket) and blocks the calling thread until
        # someone approves/rejects it there, or it times out.
        #
        # Without this hook (e.g. running Maya from the command line instead
        # of behind the API server), it falls back to the original input()
        # prompt below. On a deployed server there is no terminal attached to
        # the process, so input() would hang or error with no way for anyone
        # to actually approve the action from the web UI — that disconnect
        # is exactly what this hook fixes.
        self.request_handler = None

    def needs_approval(self, action: str, risk_level: str = "low") -> bool:
        if self.mode == APPROVAL_AUTO:
            return risk_level in [RISK_HIGH, "critical"]
        elif self.mode == APPROVAL_HUMAN:
            return True
        return False

    def request_approval(self, action: str, reason: str = "", risk_level: str = "high", task_id: str = None) -> bool:
        if self.request_handler:
            return self.request_handler(action, reason, risk_level, task_id)
        # Fallback: original CLI behavior, for local/terminal use only.
        print(f"\n⚠️  Approval needed: {action}")
        if reason:
            print(f"   Reason: {reason}")
        response = input("   Approve? (y/n): ").strip().lower()
        return response == "y"
