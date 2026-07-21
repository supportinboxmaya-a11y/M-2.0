"""Phase 31 tests — Build→Deploy→Register pipeline.

Offline — all SSH/Docker/Registry dependencies are mocked.
No real VPS, no real SSH, no real Docker needed.
"""
import os
import sys
import tempfile
import json
from pathlib import Path
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from infrastructure.deploy_pipeline import DeployPipeline


# ── Helpers ──────────────────────────────────────────────────────────────────

def _make_source_dir():
    """Create a temp dir with a minimal Dockerfile."""
    tmp = Path(tempfile.mkdtemp(prefix="maya_p31_"))
    (tmp / "Dockerfile").write_text("FROM alpine:latest\nCMD [\"echo\", \"ok\"]\n")
    (tmp / "index.html").write_text("<h1>test</h1>\n")
    return str(tmp)


def _make_empty_dir():
    """Create a temp dir with NO Dockerfile."""
    tmp = Path(tempfile.mkdtemp(prefix="maya_empty_"))
    return str(tmp)


def _fake_ssh(cmd: str) -> str:
    """Fake SSH that returns canned Docker output."""
    if "docker ps --format" in cmd:
        return (
            '{"Command":"...","CreatedAt":"...","ID":"abc123","Image":"nginx",'
            '"Names":"testnginx","State":"running","Status":"Up 2 hours"}\n'
        )
    if "docker build" in cmd:
        return "Successfully built abc123\nSuccessfully tagged test-app:latest\n"
    if "docker run" in cmd:
        return "abc123def456\n"
    if "docker ps -a" in cmd:
        return "Up 2 hours"
    if "docker info" in cmd:
        return "29.1.3"
    if "docker rmi" in cmd:
        return "Untagged: test-app:latest\n"
    if "docker rm" in cmd:
        return "test-app\n"
    if "journalctl" in cmd:
        return "-- No entries --\n"
    if "rm -rf" in cmd:
        return ""
    return cmd


_FAKE_CONTAINER_LIST = [
    {
        "Command": "...",
        "CreatedAt": "...",
        "ID": "abc123",
        "Image": "nginx",
        "Names": "testnginx",
        "State": "running",
        "Status": "Up 2 hours",
    }
]


def _mock_rd():
    """Build a mock RemoteDeployer with canned responses."""
    rd = MagicMock()
    rd.configured = True
    rd._ssh.side_effect = _fake_ssh
    rd.list_containers.return_value = _FAKE_CONTAINER_LIST
    rd.build_image.return_value = {
        "ok": True, "app": "test-app", "output": "Successfully built abc123"
    }
    rd.run_container.return_value = {
        "ok": True, "app": "test-app", "container_id": "abc123def456"
    }
    rd._q.side_effect = lambda s: f"'{s}'"
    return rd


def _mock_ar():
    """Build a mock AppRegistry."""
    ar = MagicMock()
    ar.register.return_value = {
        "name": "test-app",
        "container_id": "abc123def456",
        "image": "test-app",
        "host": "127.0.0.1",
    }
    return ar


# ── Tests ────────────────────────────────────────────────────────────────────


class TestPlan:
    """DeployPipeline.plan() — pure validation, no SSH, no side effects."""

    def setup_method(self):
        self.rd = _mock_rd()
        self.ar = _mock_ar()
        self.pipe = DeployPipeline(rd=self.rd, ar=self.ar)

    def test_valid_input(self):
        """Plan returns valid=True with 4 steps for valid input."""
        result = self.pipe.plan("test-app", _make_source_dir(), ports={"80": "80"})
        assert result["valid"] is True, f"errors: {result['errors']}"
        assert len(result["steps"]) == 4
        assert result["steps"][0]["action"] == "SCP source directory to VPS"
        assert result["steps"][1]["action"] == "Docker build"
        assert result["steps"][2]["action"] == "Docker run"
        assert result["steps"][3]["action"] == "Register in AppRegistry"
        # No SSH calls were made
        self.rd._ssh.assert_not_called()

    def test_missing_app_name(self):
        """Plan returns error for empty app_name."""
        result = self.pipe.plan("", _make_source_dir())
        assert result["valid"] is False
        assert any("app_name is required" in e for e in result["errors"]), result

    def test_missing_source_dir(self):
        """Plan returns error for nonexistent source_dir."""
        result = self.pipe.plan("test-app", "/nonexistent/path")
        assert result["valid"] is False
        assert any("source_dir not found" in e for e in result["errors"]), result

    def test_missing_dockerfile(self):
        """Plan returns error when Dockerfile is missing."""
        result = self.pipe.plan("test-app", _make_empty_dir())
        assert result["valid"] is False
        assert any("No Dockerfile found" in e for e in result["errors"]), result

    def test_vps_not_configured(self):
        """Plan reports VPS not configured when rd.configured is False."""
        self.rd.configured = False
        result = self.pipe.plan("test-app", _make_source_dir())
        assert result["valid"] is False
        assert any("VPS_HOST" in e for e in result["errors"]), result

    def test_special_chars_warning(self):
        """Plan warns but does not error on special chars in app_name."""
        result = self.pipe.plan("my app!!", _make_source_dir())
        assert result["valid"] is True
        assert any("special chars" in w for w in result["warnings"]), result

    def test_no_ssh_calls_in_plan(self):
        """Confirm plan() never calls _ssh or any remote method."""
        result = self.pipe.plan("test-app", _make_source_dir())
        self.rd._ssh.assert_not_called()
        self.rd.build_image.assert_not_called()
        self.rd.run_container.assert_not_called()
        self.ar.register.assert_not_called()


class TestExecute:
    """DeployPipeline.execute() — dry-run gate, build→run→register, rollback."""

    def setup_method(self):
        self.rd = _mock_rd()
        self.ar = _mock_ar()
        self.pipe = DeployPipeline(rd=self.rd, ar=self.ar)

    def test_dry_run_default(self):
        """execute() with confirm=False returns plan-only, no remote calls."""
        result = self.pipe.execute("test-app", _make_source_dir(), confirm=False)
        assert result["ok"] is False
        assert "Dry-run" in result["detail"]
        assert "plan" in result
        self.rd._ssh.assert_not_called()
        self.rd.build_image.assert_not_called()
        self.ar.register.assert_not_called()

    def test_execute_full_success(self):
        """execute() with confirm=True performs all 4 steps and registers."""
        src = _make_source_dir()
        result = self.pipe.execute(
            "test-app", src, ports={"8080": "80"}, env={"FOO": "bar"},
            confirm=True,
        )
        assert result["ok"] is True, f"error: {result.get('error')}"
        assert result["app_name"] == "test-app"
        assert result["container_id"] == "abc123def456"
        assert len(result["steps_log"]) == 4
        assert all(s["status"] == "done" for s in result["steps_log"]), result
        # Registry was called
        self.ar.register.assert_called_once_with(
            name="test-app",
            container_id="abc123def456",
            image="test-app",
            host=os.environ.get("VPS_HOST", ""),
        )

    def test_build_failure_rolls_back(self):
        """Build failure → no deploy → remote dir removed."""
        self.rd.build_image.return_value = {
            "ok": False, "error": "Build failed: no space"
        }
        src = _make_source_dir()
        result = self.pipe.execute("test-app", src, confirm=True)
        assert result["ok"] is False
        assert "Build failed" in result["error"]
        # Steps: step 1 done (SCP), step 2 failed (build)
        assert result["steps_log"][0]["status"] == "done", result
        assert result["steps_log"][1]["status"] == "running", result
        # Rollback cleaned remote dir
        assert any("rm -rf" in a for a in result["rollback_actions"]), result
        # No register call
        self.ar.register.assert_not_called()

    def test_run_failure_rolls_back(self):
        """Run failure → image and remote dir removed."""
        self.rd.run_container.return_value = {
            "ok": False, "error": "Port already in use"
        }
        src = _make_source_dir()
        result = self.pipe.execute("test-app", src, confirm=True)
        assert result["ok"] is False
        assert "Port already in use" in result["error"]
        # Steps: step 1 done (SCP), step 2 done (build), step 3 failed (run)
        assert result["steps_log"][0]["status"] == "done", result
        assert result["steps_log"][1]["status"] == "done", result
        assert result["steps_log"][2]["status"] == "running", result
        # Rollback: rm dir + docker rmi
        rollback_str = " ".join(result["rollback_actions"])
        assert "rm -rf" in rollback_str, result
        assert "docker rmi" in rollback_str, result
        self.ar.register.assert_not_called()

    def test_validation_failure_no_execution(self):
        """execute() with invalid inputs skips pipeline, no remote calls."""
        result = self.pipe.execute("test-app", _make_empty_dir(), confirm=True)
        assert result["ok"] is False
        assert "Validation failed" in result["detail"]
        self.rd._ssh.assert_not_called()
        self.rd.build_image.assert_not_called()
        self.rd.run_container.assert_not_called()
        self.ar.register.assert_not_called()

    def test_status_returns_last_result(self):
        """status() returns the last execution result."""
        assert self.pipe.status()["has_result"] is False
        src = _make_source_dir()
        self.pipe.execute("test-app", src, confirm=True)
        status = self.pipe.status()
        assert status["has_result"] is True
        assert status["result"]["ok"] is True
        assert status["result"]["app_name"] == "test-app"
