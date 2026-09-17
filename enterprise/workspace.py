"""
Maya 2.0 - Workspace Context
----------------------------
Resolves the *workspace scope* a request should read/write, and enforces
that a user may only touch a team workspace they belong to.

Scopes are opaque string keys used to partition memory / knowledge:

    "default"          - the legacy single-user space (backward compat)
    "user:<uid>"       - a user's private workspace
    "team:<team_id>"   - a shared team workspace

Membership is checked against the existing enterprise OrgStore (teams +
members), so this layer adds no new source of truth — it reuses what the
enterprise package already tracks.

The design keeps single-user deployments untouched: when no workspace is
requested, everything resolves to "default", exactly as before.
"""

from dataclasses import dataclass
from typing import List, Optional

DEFAULT_SCOPE = "default"


class WorkspaceError(Exception):
    """Raised when a user requests a workspace they may not access."""


@dataclass
class Workspace:
    scope: str
    kind: str          # "default" | "personal" | "team"
    label: str
    team_id: Optional[str] = None

    def to_dict(self) -> dict:
        return {"scope": self.scope, "kind": self.kind,
                "label": self.label, "team_id": self.team_id}


class WorkspaceContext:
    """Resolves and authorizes workspace scopes for a user."""

    def __init__(self, org_store=None):
        # org_store is the enterprise OrgStore (teams + members). Optional:
        # without it, only 'default' and personal workspaces are available.
        self.orgs = org_store

    # ── resolution ────────────────────────────────────────────────
    def resolve(self, user: dict, workspace: Optional[str] = None) -> Workspace:
        """Return the Workspace a request targets.

        `workspace` may be:
            None / "" / "default"  -> the legacy default space
            "personal"             -> the user's private space (user:<uid>)
            "team:<team_id>"       -> a team space (membership enforced)
        """
        ws = (workspace or "").strip()
        uid = (user or {}).get("uid") or ""
        email = (user or {}).get("email") or ""

        if not ws or ws == DEFAULT_SCOPE:
            return Workspace(DEFAULT_SCOPE, "default", "Default")

        if ws == "personal":
            if not uid:
                raise WorkspaceError("no user id for a personal workspace")
            return Workspace(f"user:{uid}", "personal", "Personal")

        if ws.startswith("team:"):
            team_id = ws.split(":", 1)[1].strip()
            if not team_id:
                raise WorkspaceError("team id is required")
            self._require_team_member(email, team_id)
            return Workspace(f"team:{team_id}", "team",
                             self._team_label(team_id), team_id=team_id)

        # An already-resolved "user:<uid>" scope: only the owner may use it.
        if ws.startswith("user:"):
            owner = ws.split(":", 1)[1].strip()
            if owner != uid:
                raise WorkspaceError("cannot access another user's workspace")
            return Workspace(ws, "personal", "Personal")

        raise WorkspaceError(f"unknown workspace '{workspace}'")

    # ── listing ───────────────────────────────────────────────────
    def available(self, user: dict) -> List[Workspace]:
        """Every workspace this user may select."""
        out = [Workspace(DEFAULT_SCOPE, "default", "Default")]
        uid = (user or {}).get("uid") or ""
        email = (user or {}).get("email") or ""
        if uid:
            out.append(Workspace(f"user:{uid}", "personal", "Personal"))
        for team_id, org_id in self._teams_of(email):
            out.append(Workspace(f"team:{team_id}", "team",
                                  self._team_label(team_id), team_id=team_id))
        return out

    # ── membership helpers (via enterprise OrgStore) ──────────────
    def _require_team_member(self, email: str, team_id: str) -> None:
        if self.orgs is None:
            raise WorkspaceError("team workspaces require the enterprise store")
        if not self._is_team_member(email, team_id):
            raise WorkspaceError("you are not a member of this team")

    def _is_team_member(self, email: str, team_id: str) -> bool:
        try:
            rows = self.orgs.db.query(
                "SELECT 1 FROM members WHERE email=? AND team_id=?",
                (email, team_id))
            return bool(rows)
        except Exception:
            return False

    def _teams_of(self, email: str):
        if self.orgs is None or not email:
            return []
        try:
            rows = self.orgs.db.query(
                "SELECT team_id, org_id FROM members "
                "WHERE email=? AND team_id IS NOT NULL", (email,))
            return [(r["team_id"], r["org_id"]) for r in rows]
        except Exception:
            return []

    def _team_label(self, team_id: str) -> str:
        if self.orgs is None:
            return f"Team {team_id}"
        try:
            rows = self.orgs.db.query("SELECT name FROM teams WHERE id=?",
                                      (team_id,))
            return rows[0]["name"] if rows else f"Team {team_id}"
        except Exception:
            return f"Team {team_id}"
