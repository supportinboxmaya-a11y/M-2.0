"""BaseAgent: identity, permissions, health, and a handle() contract."""
import time


class BaseAgent:
    def __init__(self, name: str, role: str, skills: tuple = (),
                 permissions: tuple = (), system_prompt: str = ""):
        self.name = name
        self.role = role
        self.skills = tuple(s.lower() for s in skills)          # routing keywords
        self.permissions = tuple(permissions)                    # allowed tool categories
        self.system_prompt = system_prompt or f"You are the {role} agent."
        self.memory: list = []                                   # agent-local scratch
        self._ok = 0
        self._err = 0
        self._last_error = None
        self._last_active = None

    # ---- permissions (never bypassed) ----
    def can_use(self, tool_category: str | None) -> bool:
        if tool_category is None:
            return True                                          # pure-LLM step
        return tool_category in self.permissions

    # ---- work contract ----
    def handle(self, task: str, context: str = "", llm_fn=None) -> str:
        """Default behavior: delegate to llm_fn with the agent persona."""
        self._last_active = time.time()
        if llm_fn is None:
            raise RuntimeError(f"{self.name}: no llm_fn provided")
        return llm_fn(f"{self.system_prompt}\nContext: {context}\nTask: {task}")

    # ---- health ----
    def record_success(self) -> None:
        self._ok += 1
        self._last_active = time.time()

    def record_error(self, error: str) -> None:
        self._err += 1
        self._last_error = str(error)[:300]
        self._last_active = time.time()

    def health(self) -> dict:
        total = self._ok + self._err
        return {"name": self.name, "role": self.role,
                "ok": self._ok, "errors": self._err,
                "success_rate": round(self._ok / total, 3) if total else None,
                "last_error": self._last_error, "last_active": self._last_active,
                "status": "degraded" if self._err > self._ok and total >= 3 else "healthy"}

    def remember(self, note: str) -> None:
        self.memory.append(note)
        if len(self.memory) > 50:
            del self.memory[:len(self.memory) - 50]
