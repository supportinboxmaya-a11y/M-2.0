"""Phase 22 tests — inbound webhook triggers (store, HMAC, rendering).
Offline, real SQLite temp dir."""
import hashlib, hmac, json, os, shutil, sys, tempfile, types
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

from infrastructure.webhook_triggers import WebhookTriggers

_tmp = tempfile.mkdtemp(prefix="maya_hook22_")


def _store(tag):
    return WebhookTriggers(db_path=os.path.join(_tmp, f"h_{tag}.db"))


def test_create_returns_secret_once():
    wt = _store("create")
    rec = wt.create("gh-push", "agent_goal", "Review PR {{pull_request.title}}")
    assert rec["secret"] and rec["url"].endswith(rec["id"])
    # list view never contains the secret
    listed = wt.list()
    assert listed and "secret" not in listed[0]
    assert listed[0]["signed"] is True
    print("PASS create returns secret once, list hides it")


def test_create_validation():
    wt = _store("val")
    for bad in [("", "job", "tpl"), ("n", "", "tpl"), ("n", "job", "")]:
        try:
            wt.create(*bad)
            assert False
        except ValueError:
            pass
    print("PASS create validation")


def test_hmac_signature_verification():
    wt = _store("hmac")
    secret = "topsecret"
    body = b'{"hello":"world"}'
    good = hmac.new(secret.encode(), body, hashlib.sha256).hexdigest()
    assert wt.verify_signature(secret, body, good) is True
    assert wt.verify_signature(secret, body, "sha256=" + good) is True  # gh style
    assert wt.verify_signature(secret, body, "deadbeef") is False
    assert wt.verify_signature(secret, body, "") is False
    assert wt.verify_signature(secret, b"tampered", good) is False
    # unsigned trigger accepts anything
    assert wt.verify_signature(None, body, "") is True
    print("PASS HMAC signature verification")


def test_template_rendering():
    wt = _store("tpl")
    payload = {"pull_request": {"title": "Fix login bug", "number": 42},
               "sender": {"login": "alice"},
               "labels": ["urgent", "backend"]}
    tpl = "PR #{{pull_request.number}} '{{pull_request.title}}' by {{sender.login}}"
    out = wt.render_goal(tpl, payload)
    assert out == "PR #42 'Fix login bug' by alice"
    # list index access
    assert wt.render_goal("first label {{labels.0}}", payload) == "first label urgent"
    # missing path -> empty, never raises
    assert wt.render_goal("x {{nope.missing}} y", payload) == "x  y"
    # nested object -> JSON string
    assert "title" in wt.render_goal("{{pull_request}}", payload)
    print("PASS template rendering")


def test_enable_delete_and_fire_count():
    wt = _store("life")
    rec = wt.create("t", "agent_goal", "do {{x}}")
    tid = rec["id"]
    assert wt.set_enabled(tid, False) is True
    assert wt.get(tid)["enabled"] == 0
    wt.mark_fired(tid)
    wt.mark_fired(tid)
    got = [t for t in wt.list() if t["id"] == tid][0]
    assert got["fire_count"] == 2 and got["last_fired"] is not None
    assert wt.delete(tid) is True and wt.delete(tid) is False
    print("PASS enable/delete/fire-count")


def test_unsigned_trigger_flow():
    wt = _store("unsigned")
    rec = wt.create("open", "agent_goal", "handle {{event}}", signed=False)
    assert rec["secret"] is None and rec["signed"] is False
    # verify accepts with no signature
    assert wt.verify_signature(rec["secret"], b"{}", "") is True
    print("PASS unsigned trigger flow")


def test_persistence_across_instances():
    db = os.path.join(_tmp, "persist.db")
    wt1 = WebhookTriggers(db_path=db)
    rec = wt1.create("keep", "agent_goal", "task {{id}}")
    wt2 = WebhookTriggers(db_path=db)
    assert wt2.get(rec["id"])["name"] == "keep"
    print("PASS triggers persist across instances")


try:
    test_create_returns_secret_once()
    test_create_validation()
    test_hmac_signature_verification()
    test_template_rendering()
    test_enable_delete_and_fire_count()
    test_unsigned_trigger_flow()
    test_persistence_across_instances()
    print("\nAll webhook-trigger tests passed")
finally:
    shutil.rmtree(_tmp, ignore_errors=True)
