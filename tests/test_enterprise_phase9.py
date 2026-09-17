"""Phase 9 enterprise tests — offline, temp SQLite."""
import os, sys, tempfile, time
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from enterprise import RBAC, Role, OrgStore, APIKeyManager, AuditLog, Monitor
from enterprise._db import DB

TMP = tempfile.mkdtemp()


def _db(name):
    return DB(os.path.join(TMP, name + ".db"))


def test_rbac():
    r = RBAC()
    assert r.can(Role.ADMIN, "manage_keys") and r.can(Role.VIEWER, "read")
    assert not r.can(Role.VIEWER, "write") and not r.can(Role.DEVELOPER, "manage_users")
    r.require(Role.DEVELOPER, "execute")
    try:
        r.require(Role.VIEWER, "execute"); assert False
    except PermissionError: pass
    assert "admin" in r.roles()
    print("PASS rbac")


def test_orgs_teams_members():
    s = OrgStore(db=_db("orgs"))
    org = s.create_org("Acme")
    assert s.list_orgs()[0]["name"] == "Acme"
    team = s.create_team(org["id"], "Platform")
    assert s.list_teams(org["id"])[0]["name"] == "Platform"
    s.add_member("dev@acme.com", org["id"], role="developer", team_id=team["id"])
    s.add_member("boss@acme.com", org["id"], role="admin")
    assert len(s.members(org["id"])) == 2
    assert s.role_of("dev@acme.com", org["id"]) == "developer"
    assert s.role_of("ghost@acme.com", org["id"]) is None
    s.remove_member("dev@acme.com", org["id"])
    assert len(s.members(org["id"])) == 1
    print("PASS orgs")


def test_api_keys():
    m = APIKeyManager(db=_db("keys"))
    created = m.create("ci-bot", owner="admin")
    raw = created["key"]
    assert raw.startswith("maya_")
    ok = m.verify(raw)
    assert ok and ok["name"] == "ci-bot"
    assert m.verify("maya_wrongkey") is None
    listed = m.list()
    assert listed and "key" not in listed[0] and "hash" not in listed[0]
    assert listed[0]["prefix"] == raw[:10]
    m.revoke(created["id"])
    assert m.verify(raw) is None                       # revoked keys rejected
    assert m.verify(None) is None
    print("PASS api_keys")


def test_audit_and_billing():
    a = AuditLog(db=_db("audit"))
    a.record("admin", "login", "auth")
    a.record("admin", "llm_call", "groq", {"tokens": 500}, cost=0.002)
    a.record("bot", "llm_call", "openai", cost=0.05)
    assert len(a.query()) == 3
    assert len(a.query(actor="admin")) == 2
    assert len(a.query(action="llm_call")) == 2
    summary = a.usage_summary()
    assert summary["total_events"] == 3
    assert abs(summary["total_cost"] - 0.052) < 1e-9
    old = a.usage_summary(since_ts=time.time() + 10)
    assert old["total_events"] == 0
    print("PASS audit_billing")


def test_monitor_dashboard():
    class FakeMetrics:
        def snapshot(self): return {"counters": {"req": 1}}
    class FakeAgents:
        def health_report(self): return [{"name": "coding", "status": "healthy"}]
    class Broken:
        def snapshot(self): raise RuntimeError("down")
    a = AuditLog(db=_db("audit2")); a.record("x", "y")
    mon = Monitor(metrics=FakeMetrics(), agent_registry=FakeAgents(),
                  provider_stats=Broken(), audit=a)
    d = mon.dashboard()
    assert d["metrics"]["counters"]["req"] == 1
    assert d["agents"][0]["status"] == "healthy"
    assert "error" in d["providers"]                    # graceful degradation
    assert len(d["recent_audit"]) == 1
    empty = Monitor().dashboard()
    assert empty["metrics"] is None
    print("PASS monitor")


if __name__ == "__main__":
    test_rbac(); test_orgs_teams_members(); test_api_keys()
    test_audit_and_billing(); test_monitor_dashboard()
    print("\nAll Phase 9 enterprise tests passed!")
