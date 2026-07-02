"""Task dependency graph with topological execution order.

Supports dynamic replanning: fail a node, inject new nodes, resume.
Stdlib-only, no I/O.
"""
import uuid


class TaskNode:
    __slots__ = ("id", "description", "tool", "agent", "depends_on", "state",
                 "result", "error", "attempts")

    def __init__(self, description: str, tool: str | None = None,
                 agent: str | None = None, depends_on: list | None = None,
                 node_id: str | None = None):
        self.id = node_id or uuid.uuid4().hex[:8]
        self.description = description
        self.tool = tool
        self.agent = agent
        self.depends_on = list(depends_on or [])
        self.state = "pending"          # pending | running | done | failed | blocked
        self.result = None
        self.error = None
        self.attempts = 0

    def to_dict(self) -> dict:
        return {"id": self.id, "description": self.description, "tool": self.tool,
                "agent": self.agent, "depends_on": self.depends_on,
                "state": self.state, "attempts": self.attempts, "error": self.error}


class TaskGraph:
    def __init__(self):
        self.nodes: dict[str, TaskNode] = {}

    def add(self, node: TaskNode) -> TaskNode:
        for dep in node.depends_on:
            if dep not in self.nodes:
                raise ValueError(f"Unknown dependency: {dep}")
        self.nodes[node.id] = node
        if self._has_cycle():
            del self.nodes[node.id]
            raise ValueError("Dependency cycle detected")
        return node

    def ready(self) -> list:
        """Nodes whose dependencies are all done and that can run now."""
        out = []
        for n in self.nodes.values():
            if n.state == "pending" and all(
                    self.nodes[d].state == "done" for d in n.depends_on):
                out.append(n)
        return out

    def start(self, node_id: str) -> None:
        n = self.nodes[node_id]
        n.state = "running"
        n.attempts += 1

    def complete(self, node_id: str, result=None) -> None:
        n = self.nodes[node_id]
        n.state = "done"
        n.result = result

    def fail(self, node_id: str, error: str = "") -> list:
        """Mark failed; downstream dependents become blocked. Returns blocked ids."""
        n = self.nodes[node_id]
        n.state = "failed"
        n.error = error
        blocked = []
        for m in self.nodes.values():
            if n.id in self._all_deps(m) and m.state == "pending":
                m.state = "blocked"
                blocked.append(m.id)
        return blocked

    def retry(self, node_id: str) -> None:
        """Reset a failed node (and unblock its dependents) for replanning."""
        n = self.nodes[node_id]
        if n.state != "failed":
            return
        n.state = "pending"
        n.error = None
        for m in self.nodes.values():
            if m.state == "blocked" and all(
                    self.nodes[d].state != "failed" for d in self._all_deps(m)):
                m.state = "pending"

    def progress(self) -> dict:
        states = {}
        for n in self.nodes.values():
            states[n.state] = states.get(n.state, 0) + 1
        done = states.get("done", 0)
        total = len(self.nodes)
        return {"total": total, "states": states,
                "percent": round(done / total * 100, 1) if total else 0.0,
                "finished": done == total and total > 0,
                "stuck": states.get("failed", 0) > 0 and not self.ready()}

    def to_dict(self) -> dict:
        return {"nodes": [n.to_dict() for n in self.nodes.values()],
                "progress": self.progress()}

    def _all_deps(self, node: TaskNode, seen=None) -> set:
        seen = seen or set()
        for d in node.depends_on:
            if d not in seen:
                seen.add(d)
                self._all_deps(self.nodes[d], seen)
        return seen

    def _has_cycle(self) -> bool:
        WHITE, GRAY, BLACK = 0, 1, 2
        color = {i: WHITE for i in self.nodes}

        def visit(i):
            color[i] = GRAY
            for d in self.nodes[i].depends_on:
                if color.get(d) == GRAY or (color.get(d) == WHITE and visit(d)):
                    return True
            color[i] = BLACK
            return False

        return any(color[i] == WHITE and visit(i) for i in list(self.nodes))
