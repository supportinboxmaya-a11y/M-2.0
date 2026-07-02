"""The 11 specialist agents from the MAYA 3.0 spec."""
from .base import BaseAgent

_SPEC = [
    # name, role, skills(routing keywords), permissions(tool categories)
    ("planner", "Planner", ("plan", "goal", "decompose", "strategy"), ()),
    ("research", "Research", ("search", "research", "find", "news", "lookup"), ("web", "memory")),
    ("coding", "Coding", ("code", "script", "function", "implement", "python", "api"), ("code", "file")),
    ("reviewer", "Reviewer", ("review", "critique", "quality", "refactor"), ("file",)),
    ("testing", "Testing", ("test", "verify", "validate", "qa"), ("code", "shell")),
    ("security", "Security", ("security", "vulnerability", "permission", "audit"), ("file",)),
    ("deployment", "Deployment", ("deploy", "release", "docker", "server", "render"), ("shell", "web")),
    ("documentation", "Documentation", ("document", "readme", "docs", "explain"), ("file",)),
    ("database", "Database", ("database", "sql", "schema", "query", "migration"), ("code", "file")),
    ("frontend", "Frontend", ("frontend", "ui", "react", "css", "component"), ("code", "file")),
    ("backend", "Backend", ("backend", "endpoint", "fastapi", "route", "service"), ("code", "file", "shell")),
]


def build_default_agents() -> list:
    agents = []
    for name, role, skills, perms in _SPEC:
        agents.append(BaseAgent(
            name=name, role=role, skills=skills, permissions=perms,
            system_prompt=(f"You are Maya's {role} agent. Stay strictly within "
                           f"your specialty: {', '.join(skills)}. Be precise and safe.")))
    return agents
