"""API key lifecycle: create (hash-stored), verify, list (masked), revoke.

Raw keys are shown ONCE at creation and never stored or logged.
"""
import hashlib
import secrets as _secrets
import time
import uuid

from ._db import DB


class APIKeyManager:
    def __init__(self, db: DB | None = None, path: str = "storage/enterprise.db"):
        self.db = db or DB(path)
        self.db.execute("""CREATE TABLE IF NOT EXISTS api_keys(
            id TEXT PRIMARY KEY, name TEXT, hash TEXT UNIQUE, prefix TEXT,
            owner TEXT, revoked INTEGER DEFAULT 0, created REAL, last_used REAL)""")

    @staticmethod
    def _hash(raw: str) -> str:
        return hashlib.sha256(raw.encode()).hexdigest()

    def create(self, name: str, owner: str = "admin") -> dict:
        raw = "maya_" + _secrets.token_urlsafe(32)
        kid = uuid.uuid4().hex[:10]
        self.db.execute(
            "INSERT INTO api_keys(id,name,hash,prefix,owner,created) VALUES(?,?,?,?,?,?)",
            (kid, name, self._hash(raw), raw[:10], owner, time.time()))
        return {"id": kid, "name": name, "key": raw,     # raw returned once
                "note": "Store this key now; it cannot be shown again."}

    def verify(self, raw: str) -> dict | None:
        rows = self.db.query(
            "SELECT id,name,owner FROM api_keys WHERE hash=? AND revoked=0",
            (self._hash(raw or ""),))
        if not rows:
            return None
        self.db.execute("UPDATE api_keys SET last_used=? WHERE id=?",
                        (time.time(), rows[0]["id"]))
        return rows[0]

    def list(self) -> list:
        return self.db.query(
            "SELECT id,name,prefix,owner,revoked,created,last_used "
            "FROM api_keys ORDER BY created DESC")

    def revoke(self, key_id: str) -> bool:
        self.db.execute("UPDATE api_keys SET revoked=1 WHERE id=?", (key_id,))
        return True
