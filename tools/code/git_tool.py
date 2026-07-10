"""
Maya 2.0 - Local Git Tool
-------------------------
Real git operations on repositories inside the workspace: init, status,
log, diff, add, commit, branch, checkout, merge.

Complements the GitHub API tool (tools/web/github_tool.py) which can
only read remote repos — this one lets agents version their own work.

Security:
- Every repo path is confined to WORKSPACE_DIR (same contract as
  tools/files/safe_path.py).
- Commands run as argument lists (never shell=True) so filenames or
  messages cannot inject shell syntax.
- Values that look like git options (leading "-") are rejected to
  prevent option-injection (e.g. branch name "--force").
- Only local subcommands are exposed — no push/pull/clone/remote, so
  no credentials are ever involved.
"""

import subprocess
from pathlib import Path
from typing import Optional

from config.settings import WORKSPACE_DIR

GIT_TIMEOUT = 30
OUTPUT_LIMIT = 5000


class GitTool:
    def __init__(self, workspace: Optional[str] = None):
        self.workspace = Path(workspace or WORKSPACE_DIR).resolve()

    # ── internals ─────────────────────────────────────────────────
    def _repo_path(self, repo: str) -> Path:
        repo = (repo or ".").strip() or "."
        target = (self.workspace / repo).resolve()
        try:
            target.relative_to(self.workspace)
        except ValueError:
            raise ValueError(f"repo path '{repo}' escapes the workspace")
        return target

    @staticmethod
    def _check_arg(value: str, label: str) -> str:
        value = (value or "").strip()
        if not value:
            raise ValueError(f"{label} is required")
        if value.startswith("-"):
            raise ValueError(f"{label} may not start with '-'")
        return value

    def _git(self, repo: str, *args: str) -> str:
        try:
            path = self._repo_path(repo)
        except ValueError as e:
            return f"Error: {e}"
        if not path.is_dir():
            return f"Error: directory not found: {repo}"
        try:
            r = subprocess.run(
                ["git", "-c", "user.name=Maya", "-c", "user.email=maya@local",
                 *args],
                cwd=str(path), capture_output=True, text=True,
                timeout=GIT_TIMEOUT)
        except FileNotFoundError:
            return "Error: git is not installed on this system"
        except subprocess.TimeoutExpired:
            return "Error: git command timed out"
        out = (r.stdout + (("\n" + r.stderr) if r.stderr else "")).strip()
        out = out[:OUTPUT_LIMIT]
        if r.returncode != 0:
            return f"Error (exit {r.returncode}): {out or 'git command failed'}"
        return out or "OK"

    # ── operations ────────────────────────────────────────────────
    def init(self, repo: str = ".") -> str:
        """Initialize a git repository."""
        return self._git(repo, "init")

    def status(self, repo: str = ".") -> str:
        """Working tree status (short format)."""
        return self._git(repo, "status", "--short", "--branch")

    def log(self, repo: str = ".", limit: int = 10) -> str:
        """Recent commit history."""
        limit = max(1, min(int(limit or 10), 100))
        return self._git(repo, "log", "--oneline", "--decorate", f"-{limit}")

    def diff(self, repo: str = ".", staged: bool = False) -> str:
        """Unstaged changes, or staged ones with staged=True."""
        args = ["diff", "--stat", "-p"]
        if staged:
            args.insert(1, "--cached")
        return self._git(repo, *args)

    def add(self, repo: str = ".", paths: str = ".") -> str:
        """Stage files (space-separated paths, '.' for everything)."""
        parts = []
        for p in (paths or ".").split():
            try:
                parts.append(self._check_arg(p, "path"))
            except ValueError as e:
                return f"Error: {e}"
        return self._git(repo, "add", "--", *parts)

    def commit(self, repo: str = ".", message: str = "") -> str:
        """Commit staged changes with a message."""
        message = (message or "").strip()
        if not message:
            return "Error: commit message is required"
        return self._git(repo, "commit", "-m", message)

    def branch(self, repo: str = ".", name: str = "") -> str:
        """List branches, or create+switch to `name` if given."""
        if not (name or "").strip():
            return self._git(repo, "branch", "--list")
        try:
            name = self._check_arg(name, "branch name")
        except ValueError as e:
            return f"Error: {e}"
        return self._git(repo, "checkout", "-b", name)

    def checkout(self, repo: str = ".", name: str = "") -> str:
        """Switch to an existing branch."""
        try:
            name = self._check_arg(name, "branch name")
        except ValueError as e:
            return f"Error: {e}"
        return self._git(repo, "checkout", name)

    def merge(self, repo: str = ".", name: str = "") -> str:
        """Merge `name` into the current branch (aborts on conflict)."""
        try:
            name = self._check_arg(name, "branch name")
        except ValueError as e:
            return f"Error: {e}"
        out = self._git(repo, "merge", "--no-edit", name)
        if out.startswith("Error") and "CONFLICT" in out:
            self._git(repo, "merge", "--abort")
            return ("Error: merge conflict detected — merge aborted. "
                    "Resolve differences between the branches first.\n" + out)
        return out
