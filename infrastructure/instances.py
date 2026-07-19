"""
Maya 2.0 — Instance Manager
----------------------------
Manages named Maya instances, each with its own persona, skill set,
budget, and — critically — an isolated *memory_scope* so multiple
Mayas never share memory.  Persisted to a JSON file so instances
survive server restarts.

Scope format (matching ``enterprise/workspace.py`` convention):

    "maya:<instance_id>"

This fits alongside the existing ``"default"``, ``"user:<uid>"``, and
``"team:<team_id>"`` scopes so the same ``ScopedMemory`` SQLite store
can partition memory per-instance without any schema changes.
"""

import json
import threading
import time
import uuid
from pathlib import Path
from typing import Dict, List, Optional

from config.settings import STORAGE_DIR

INSTANCES_FILE = str(STORAGE_DIR / "instances.json")


class InstanceManager:
    """Persistent registry of Maya instances.

    Thread-safe (file writes are locked).  JSON persistence means zero
    database dependencies — works on every platform.
    """

    def __init__(self, path: str = INSTANCES_FILE):
        self._path = path
        self._lock = threading.Lock()
        self._instances: Dict[str, dict] = {}
        self._load()

    # ── persistence ──────────────────────────────────────────────────

    def _load(self) -> None:
        try:
            with open(self._path, "r", encoding="utf-8") as f:
                self._instances = json.load(f)
        except (FileNotFoundError, ValueError):
            self._instances = {}

    def _save(self) -> None:
        p = Path(self._path)
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(self._path, "w", encoding="utf-8") as f:
            json.dump(self._instances, f, indent=2, default=str)

    # ── CRUD ─────────────────────────────────────────────────────────

    def create(self, name: str, persona: str, skills: Optional[List[str]] = None,
               budget_usd: float = 5.0, owner: str = "system") -> dict:
        """Register a new Maya instance.

        Returns the instance dict.  *memory_scope* is auto-generated as
        ``"maya:<uuid>"`` so it is always unique.
        """
        iid = uuid.uuid4().hex
        now = time.time()
        instance = {
            "id": iid,
            "name": name,
            "persona": persona,
            "memory_scope": f"maya:{iid}",
            "skills": skills or [],
            "budget_usd": float(budget_usd),
            "owner": owner,
            "created_at": now,
        }
        with self._lock:
            self._instances[iid] = instance
            self._save()
        return dict(instance)

    def list(self, owner: Optional[str] = None) -> List[dict]:
        """Return all instances, optionally filtered by *owner*."""
        with self._lock:
            items = list(self._instances.values())
        if owner:
            items = [i for i in items if i.get("owner") == owner]
        return sorted(items, key=lambda i: i.get("created_at", 0), reverse=True)

    def get(self, iid: str) -> Optional[dict]:
        """Return a single instance by id, or ``None``."""
        with self._lock:
            return dict(self._instances[iid]) if iid in self._instances else None

    def delete(self, iid: str) -> bool:
        """Remove an instance.  Returns ``True`` if it existed."""
        with self._lock:
            if iid in self._instances:
                del self._instances[iid]
                self._save()
                return True
            return False


# ── Module singleton ──────────────────────────────────────────────────────
instance_manager = InstanceManager()


# ── Self-test (runs once at import time when invoked directly) ────────────
if __name__ == "__main__":
    import sys

    print("InstanceManager self-test…")

    mgr = InstanceManager(path=STORAGE_DIR / "instances.test.json")

    # Clean start
    for i in mgr.list():
        mgr.delete(i["id"])

    a = mgr.create(name="Alpha", persona="A helpful coding assistant",
                   skills=["web_search", "run_code"], owner="alice")
    b = mgr.create(name="Beta", persona="A creative writing partner",
                   skills=["image_gen", "web_search"], owner="bob")

    assert a["memory_scope"] != b["memory_scope"], \
        f"memory_scope collision: {a['memory_scope']} == {b['memory_scope']}"
    print(f"  ✓ memory_scope isolation:  {a['memory_scope']}  ≠  {b['memory_scope']}")

    assert len(mgr.list()) == 2
    print(f"  ✓ list() returns {len(mgr.list())} instances")

    alice_instances = mgr.list(owner="alice")
    assert len(alice_instances) == 1
    assert alice_instances[0]["name"] == "Alpha"
    print(f"  ✓ list(owner='alice') returns Alice's instance")

    fetched = mgr.get(a["id"])
    assert fetched is not None
    assert fetched["id"] == a["id"]
    print(f"  ✓ get('{a['id'][:8]}…') returns the right instance")

    assert mgr.delete(a["id"]) is True
    assert mgr.get(a["id"]) is None
    assert len(mgr.list()) == 1
    print(f"  ✓ delete() removes and leaves other instances intact")

    assert mgr.delete("nonexistent") is False
    print(f"  ✓ delete('nonexistent') returns False")

    # Clean up test file
    import os as _os
    try:
        _os.remove(str(STORAGE_DIR / "instances.test.json"))
    except Exception:
        pass

    print("All InstanceManager self-tests passed.")
    sys.exit(0)
