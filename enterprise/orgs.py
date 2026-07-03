"""Organizations, teams, and memberships."""
import time
import uuid

from ._db import DB


class OrgStore:
    def __init__(self, db: DB | None = None, path: str = "storage/enterprise.db"):
        self.db = db or DB(path)
        self.db.execute("""CREATE TABLE IF NOT EXISTS orgs(
            id TEXT PRIMARY KEY, name TEXT UNIQUE, created REAL)""")
        self.db.execute("""CREATE TABLE IF NOT EXISTS teams(
            id TEXT PRIMARY KEY, org_id TEXT, name TEXT, created REAL)""")
        self.db.execute("""CREATE TABLE IF NOT EXISTS members(
            email TEXT, org_id TEXT, team_id TEXT, role TEXT, created REAL,
            PRIMARY KEY(email, org_id))""")

    # orgs
    def create_org(self, name: str) -> dict:
        oid = uuid.uuid4().hex[:10]
        self.db.execute("INSERT INTO orgs VALUES(?,?,?)", (oid, name, time.time()))
        return {"id": oid, "name": name}

    def list_orgs(self) -> list:
        return self.db.query("SELECT * FROM orgs ORDER BY created")

    # teams
    def create_team(self, org_id: str, name: str) -> dict:
        tid = uuid.uuid4().hex[:10]
        self.db.execute("INSERT INTO teams VALUES(?,?,?,?)",
                        (tid, org_id, name, time.time()))
        return {"id": tid, "org_id": org_id, "name": name}

    def list_teams(self, org_id: str) -> list:
        return self.db.query("SELECT * FROM teams WHERE org_id=?", (org_id,))

    # members
    def add_member(self, email: str, org_id: str, role: str = "viewer",
                   team_id: str | None = None) -> dict:
        self.db.execute("INSERT OR REPLACE INTO members VALUES(?,?,?,?,?)",
                        (email, org_id, team_id, role, time.time()))
        return {"email": email, "org_id": org_id, "team_id": team_id, "role": role}

    def members(self, org_id: str) -> list:
        return self.db.query("SELECT * FROM members WHERE org_id=?", (org_id,))

    def role_of(self, email: str, org_id: str) -> str | None:
        rows = self.db.query("SELECT role FROM members WHERE email=? AND org_id=?",
                             (email, org_id))
        return rows[0]["role"] if rows else None

    def remove_member(self, email: str, org_id: str) -> bool:
        self.db.execute("DELETE FROM members WHERE email=? AND org_id=?",
                        (email, org_id))
        return True
