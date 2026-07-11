"""Phase 20 tests — multi-user workspaces + scoped memory isolation.
Offline, real SQLite temp dir."""
import os, shutil, sys, tempfile, types
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

for _name in ("loguru", "dotenv"):
    if _name not in sys.modules:
        try:
            __import__(_name)
        except ImportError:
            _m = types.ModuleType(_name)
            if _name == "loguru":
                class _L:
                    def __getattr__(self, k):
                        return lambda *a, **kw: self
                _m.logger = _L()
            if _name == "dotenv":
                _m.load_dotenv = lambda *a, **kw: None
            sys.modules[_name] = _m

from enterprise.workspace import WorkspaceContext, WorkspaceError, DEFAULT_SCOPE
from enterprise.scoped_memory import ScopedMemory
from enterprise.orgs import OrgStore
from enterprise._db import DB

_tmp = tempfile.mkdtemp(prefix="maya_ws20_")

USER_A = {"uid": "uidA", "email": "alice@example.com", "role": "admin"}
USER_B = {"uid": "uidB", "email": "bob@example.com", "role": "viewer"}


def _orgs():
    return OrgStore(db=DB(os.path.join(_tmp, f"ent_{os.urandom(3).hex()}.db")))


# ── workspace resolution ──────────────────────────────────────────
def test_default_and_personal_resolution():
    ctx = WorkspaceContext(org_store=None)
    assert ctx.resolve(USER_A, None).scope == DEFAULT_SCOPE
    assert ctx.resolve(USER_A, "default").scope == DEFAULT_SCOPE
    p = ctx.resolve(USER_A, "personal")
    assert p.scope == "user:uidA" and p.kind == "personal"
    print("PASS default + personal resolution")


def test_personal_isolation_between_users():
    ctx = WorkspaceContext(org_store=None)
    a = ctx.resolve(USER_A, "personal").scope
    b = ctx.resolve(USER_B, "personal").scope
    assert a != b
    # A cannot address B's already-resolved scope
    try:
        ctx.resolve(USER_A, "user:uidB")
        assert False
    except WorkspaceError:
        pass
    print("PASS personal scopes are isolated")


def test_team_membership_enforced():
    orgs = _orgs()
    org = orgs.create_org("Acme")
    team = orgs.create_team(org["id"], "Engineering")
    orgs.add_member(USER_A["email"], org["id"], role="editor",
                    team_id=team["id"])
    ctx = WorkspaceContext(org_store=orgs)
    # member A can resolve the team workspace
    ws = ctx.resolve(USER_A, f"team:{team['id']}")
    assert ws.kind == "team" and ws.scope == f"team:{team['id']}"
    assert ws.label == "Engineering"
    # non-member B cannot
    try:
        ctx.resolve(USER_B, f"team:{team['id']}")
        assert False
    except WorkspaceError as e:
        assert "not a member" in str(e)
    print("PASS team membership enforced")


def test_available_lists_teams():
    orgs = _orgs()
    org = orgs.create_org("Beta")
    t1 = orgs.create_team(org["id"], "Design")
    orgs.add_member(USER_A["email"], org["id"], team_id=t1["id"])
    ctx = WorkspaceContext(org_store=orgs)
    scopes = {w.scope for w in ctx.available(USER_A)}
    assert DEFAULT_SCOPE in scopes
    assert "user:uidA" in scopes
    assert f"team:{t1['id']}" in scopes
    # B (no teams) only sees default + personal
    b_scopes = {w.scope for w in ctx.available(USER_B)}
    assert b_scopes == {DEFAULT_SCOPE, "user:uidB"}
    print("PASS available lists correct workspaces")


def test_team_without_orgstore_rejected():
    ctx = WorkspaceContext(org_store=None)
    try:
        ctx.resolve(USER_A, "team:whatever")
        assert False
    except WorkspaceError:
        pass
    print("PASS team workspace needs enterprise store")


# ── scoped memory isolation ───────────────────────────────────────
def test_scoped_memory_isolation():
    mem = ScopedMemory(db_path=os.path.join(_tmp, "wsmem.db"))
    mem.add("user:uidA", "Alice's private note about project X", author="alice")
    mem.add("user:uidB", "Bob's private note about project Y", author="bob")
    mem.add("team:t1", "Shared team roadmap Q3", author="alice")

    a = mem.search("user:uidA", "project")
    assert len(a) == 1 and "Alice" in a[0]["content"]
    # A's search never returns B's memory
    assert all("Bob" not in r["content"] for r in mem.search("user:uidA", ""))
    # team space is shared and separate
    team = mem.list("team:t1")
    assert len(team) == 1 and "roadmap" in team[0]["content"]
    # empty query lists only that scope
    assert len(mem.list("user:uidB")) == 1
    print("PASS scoped memory isolation")


def test_scoped_delete_and_stats():
    mem = ScopedMemory(db_path=os.path.join(_tmp, "wsmem2.db"))
    mid = mem.add("team:t2", "temporary decision", memory_type="decision")
    mem.add("team:t2", "another item", memory_type="note")
    st = mem.stats("team:t2")
    assert st["total"] == 2 and st["by_type"]["decision"] == 1
    # cannot delete via the wrong scope
    assert mem.delete("user:uidA", mid) is False
    assert mem.delete("team:t2", mid) is True
    assert mem.stats("team:t2")["total"] == 1
    print("PASS scoped delete + stats")


def test_add_requires_content():
    mem = ScopedMemory(db_path=os.path.join(_tmp, "wsmem3.db"))
    try:
        mem.add("user:x", "   ")
        assert False
    except ValueError:
        pass
    print("PASS add requires content")


try:
    test_default_and_personal_resolution()
    test_personal_isolation_between_users()
    test_team_membership_enforced()
    test_available_lists_teams()
    test_team_without_orgstore_rejected()
    test_scoped_memory_isolation()
    test_scoped_delete_and_stats()
    test_add_requires_content()
    print("\nAll workspace tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
