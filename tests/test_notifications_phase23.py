"""Phase 23 tests — multi-channel notifications.
Offline, real SQLite temp dir, fake SMTP/webhook transports."""
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

# Ensure no SMTP env leaks in
for _k in ("SMTP_HOST", "SMTP_FROM", "SMTP_USER", "SMTP_PASS", "SMTP_PORT"):
    os.environ.pop(_k, None)

from infrastructure.notifications import Notifier

_tmp = tempfile.mkdtemp(prefix="maya_notif23_")


def _notifier(tag):
    return Notifier(db_path=os.path.join(_tmp, f"n_{tag}.db"))


def test_in_app_store_and_list():
    n = _notifier("store")
    r = n.notify("task.done", "Build finished", "All green",
                 recipient="alice@x.com")
    assert r["results"]["in_app"]["ok"]
    items = n.list("alice@x.com")
    assert len(items) == 1 and items[0]["title"] == "Build finished"
    assert items[0]["read"] is False
    # a different recipient sees nothing
    assert n.list("bob@x.com") == []
    print("PASS in-app store + per-recipient listing")


def test_unread_and_mark_read():
    n = _notifier("unread")
    for i in range(3):
        n.notify("e", f"msg {i}", recipient="u@x.com")
    assert n.unread_count("u@x.com") == 3
    items = n.list("u@x.com")
    assert n.mark_read(items[0]["id"]) is True
    assert n.unread_count("u@x.com") == 2
    assert n.mark_all_read("u@x.com") == 2
    assert n.unread_count("u@x.com") == 0
    print("PASS unread count + mark read/all")


def test_email_skipped_when_unconfigured():
    n = _notifier("email")
    r = n.notify("e", "hi", channels=["email"], email_to="x@y.com")
    assert r["results"]["email"]["ok"] is False
    assert "not configured" in r["results"]["email"]["skipped"]
    print("PASS email skipped when SMTP unconfigured")


def test_email_sent_when_configured(monkeypatch=None):
    os.environ["SMTP_HOST"] = "smtp.test"
    os.environ["SMTP_FROM"] = "maya@test"
    sent = {}
    import infrastructure.notifications as mod

    class _FakeSMTP:
        def __init__(self, host, port, timeout=10):
            sent["host"] = host
        def __enter__(self): return self
        def __exit__(self, *a): return False
        def starttls(self): pass
        def login(self, u, p): pass
        def sendmail(self, s, to, msg):
            sent["to"] = to
            sent["msg"] = msg
    orig = mod.smtplib.SMTP
    mod.smtplib.SMTP = _FakeSMTP
    try:
        n = _notifier("email2")
        assert n.email_configured() is True
        r = n.notify("e", "Subject line", "email body",
                     channels=["email"], email_to="to@x.com")
        assert r["results"]["email"]["ok"] is True
        assert sent["to"] == ["to@x.com"] and "Subject line" in sent["msg"]
    finally:
        mod.smtplib.SMTP = orig
        os.environ.pop("SMTP_HOST", None)
        os.environ.pop("SMTP_FROM", None)
    print("PASS email sent when SMTP configured")


def test_webhook_channel():
    import infrastructure.notifications as mod
    posted = {}

    class _Resp:
        status_code = 204
    fake = types.ModuleType("requests")
    fake.post = lambda url, **kw: (posted.update(url=url, kw=kw) or _Resp())
    old = sys.modules.get("requests")
    sys.modules["requests"] = fake
    try:
        n = _notifier("wh")
        r = n.notify("task.failed", "It failed", "stacktrace",
                     channels=["webhook"], webhook_url="https://hook.test/x")
        assert r["results"]["webhook"]["ok"] is True
        assert posted["url"] == "https://hook.test/x"
        assert posted["kw"]["json"]["event"] == "task.failed"
    finally:
        if old is not None:
            sys.modules["requests"] = old
        else:
            # Purge requests AND its cached submodules: deleting only
            # "requests" leaves stale requests.* entries, so the next
            # import rebuilds a parent missing the `exceptions` attribute.
            for _k in [k for k in sys.modules
                       if k == "requests" or k.startswith("requests.")]:
                del sys.modules[_k]
    # no url -> graceful failure
    n2 = _notifier("wh2")
    r2 = n2.notify("e", "t", channels=["webhook"])
    assert r2["results"]["webhook"]["ok"] is False
    print("PASS webhook channel + missing url handled")


def test_multi_channel_fanout():
    n = _notifier("multi")
    r = n.notify("job.done", "Done", "body",
                 channels=["in_app", "email"], recipient="a@x.com")
    assert set(r["results"].keys()) == {"in_app", "email"}
    assert r["results"]["in_app"]["ok"] is True
    print("PASS multi-channel fan-out")


def test_send_requires_nothing_extra_and_persists():
    db = os.path.join(_tmp, "persist.db")
    n1 = Notifier(db_path=db)
    n1.notify("e", "persisted note", recipient="p@x.com")
    n2 = Notifier(db_path=db)
    assert n2.list("p@x.com")[0]["title"] == "persisted note"
    print("PASS notifications persist across instances")


if __name__ == "__main__":
    try:
        test_in_app_store_and_list()
        test_unread_and_mark_read()
        test_email_skipped_when_unconfigured()
        test_email_sent_when_configured()
        test_webhook_channel()
        test_multi_channel_fanout()
        test_send_requires_nothing_extra_and_persists()
        print("\nAll notification tests passed")
    finally:
        shutil.rmtree(_tmp, ignore_errors=True)
