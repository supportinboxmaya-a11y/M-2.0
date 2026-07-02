"""In-memory message bus for agent communication (with history)."""
import time
from collections import defaultdict, deque


class MessageBus:
    def __init__(self, max_history: int = 500):
        self._inbox: dict = defaultdict(deque)
        self._history: deque = deque(maxlen=max_history)

    def send(self, sender: str, to: str, content) -> dict:
        msg = {"from": sender, "to": to, "content": content, "ts": time.time()}
        self._inbox[to].append(msg)
        self._history.append(msg)
        return msg

    def receive(self, name: str) -> list:
        """Drain and return all pending messages for an agent."""
        out = list(self._inbox[name])
        self._inbox[name].clear()
        return out

    def broadcast(self, sender: str, agents: list, content) -> int:
        for a in agents:
            if a != sender:
                self.send(sender, a, content)
        return len(agents)

    def history(self, limit: int = 50) -> list:
        return list(self._history)[-limit:]
