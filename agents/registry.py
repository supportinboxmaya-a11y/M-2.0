"""Agent registry: registration, lookup, capability-based routing."""


class AgentRegistry:
    def __init__(self):
        self._agents: dict = {}

    def register(self, agent) -> None:
        self._agents[agent.name] = agent

    def get(self, name: str):
        return self._agents.get(name)

    def list(self) -> list:
        return list(self._agents.values())

    def route(self, description: str, preferred: str | None = None,
              tool: str | None = None):
        """Pick the best agent: explicit name > skill keyword match > permission fit."""
        if preferred and preferred in self._agents:
            return self._agents[preferred]
        text = (description or "").lower()
        best, best_score = None, 0
        for a in self._agents.values():
            score = sum(2 for s in a.skills if s in text)
            if tool and a.can_use(tool):
                score += 1
            if score > best_score:
                best, best_score = a, score
        if best:
            return best
        # fallback: any agent allowed to use the tool, else the planner
        for a in self._agents.values():
            if a.can_use(tool):
                return a
        return next(iter(self._agents.values()), None)

    def health_report(self) -> list:
        return [a.health() for a in self._agents.values()]
