"""
Maya 2.0 - Web Builder Tool
---------------------------
Turns the code an agent has *written* into something a user can actually
open: it scaffolds a set of files into a project folder, zips it into a
downloadable deliverable, and (optionally) deploys it to Netlify so the
user gets a real live URL back.

This fills the gap where Maya's coding/frontend agents could produce
HTML/CSS/JS but had no way to hand it over as a running site.

Operations
----------
  - build(name, files)          -> scaffold + zip a project (no network,
                                   no token). Returns the zip path.
  - deploy(name, files=None)    -> zip the project and push it to Netlify,
                                   returns the live https URL.

Security (same contract as git_tool.py / safe_path.py)
------------------------------------------------------
  - Every project path is confined to WORKSPACE_DIR; names that try to
    escape (via "..", leading "/", etc.) are rejected.
  - Each file path inside a project is confined the same way.
  - Deploy needs a NETLIFY_TOKEN in the environment; without it deploy
    refuses cleanly instead of half-working.
"""

import io
import os
import re
import zipfile
from pathlib import Path
from typing import Dict, Optional

import requests

from config.settings import WORKSPACE_DIR

DEPLOY_TIMEOUT = 120
NETLIFY_API = "https://api.netlify.com/api/v1/sites"
_SAFE_NAME = re.compile(r"^[A-Za-z0-9._-]+$")


class WebBuilderTool:
    def __init__(self, workspace: Optional[str] = None):
        self.workspace = Path(workspace or WORKSPACE_DIR).resolve()
        self.workspace.mkdir(parents=True, exist_ok=True)

    # ── internals ─────────────────────────────────────────────────
    def _project_dir(self, name: str) -> Path:
        name = (name or "").strip()
        if not name:
            raise ValueError("project name is required")
        if not _SAFE_NAME.match(name):
            raise ValueError("project name may only contain letters, "
                             "numbers, '.', '_' and '-'")
        target = (self.workspace / name).resolve()
        try:
            target.relative_to(self.workspace)
        except ValueError:
            raise ValueError(f"project '{name}' escapes the workspace")
        return target

    def _safe_child(self, root: Path, rel: str) -> Path:
        rel = (rel or "").strip().lstrip("/\\")
        if not rel:
            raise ValueError("empty file path")
        target = (root / rel).resolve()
        try:
            target.relative_to(root)
        except ValueError:
            raise ValueError(f"file path '{rel}' escapes the project")
        return target

    def _write_files(self, root: Path, files: Dict[str, str]) -> int:
        if not isinstance(files, dict) or not files:
            raise ValueError("files must be a non-empty {path: content} map")
        count = 0
        for rel, content in files.items():
            path = self._safe_child(root, rel)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content if content is not None else "",
                            encoding="utf-8")
            count += 1
        return count

    def _zip_dir(self, root: Path) -> Path:
        zip_path = root.with_suffix(".zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for p in root.rglob("*"):
                if p.is_file():
                    zf.write(p, p.relative_to(root))
        return zip_path

    # ── operations ────────────────────────────────────────────────
    def build(self, name: str = "site", files: Dict[str, str] = None) -> str:
        """Scaffold `files` into a project folder and zip it.

        `files` is a {relative_path: text_content} map, e.g.
        {"index.html": "<!doctype html>...", "style.css": "body{...}"}.
        Returns a short report with the zip path (the deliverable).
        """
        try:
            root = self._project_dir(name)
            root.mkdir(parents=True, exist_ok=True)
            n = self._write_files(root, files or {})
            zip_path = self._zip_dir(root)
        except ValueError as e:
            return f"Error: {e}"
        except Exception as e:
            return f"Error: build failed ({e})"
        return (f"OK: built '{name}' with {n} file(s).\n"
                f"Folder: {root}\nZip: {zip_path}")

    def deploy(self, name: str = "site", files: Dict[str, str] = None) -> str:
        """Deploy the project to Netlify and return a live URL.

        If `files` is given, the project is (re)built first; otherwise an
        already-built folder of that name is deployed. Requires the
        NETLIFY_TOKEN environment variable.
        """
        token = os.environ.get("NETLIFY_TOKEN", "").strip()
        if not token:
            return ("Error: NETLIFY_TOKEN is not set. Add a Netlify personal "
                    "access token to the environment to enable deploys.")
        try:
            root = self._project_dir(name)
            if files:
                root.mkdir(parents=True, exist_ok=True)
                self._write_files(root, files)
            if not root.is_dir():
                return f"Error: project '{name}' not found — build it first."

            buf = io.BytesIO()
            with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
                has_index = False
                for p in root.rglob("*"):
                    if p.is_file():
                        arc = p.relative_to(root)
                        if str(arc) == "index.html":
                            has_index = True
                        zf.write(p, arc)
            if not has_index:
                return ("Error: no index.html at the project root — Netlify "
                        "needs one as the site entry point.")
            buf.seek(0)

            r = requests.post(
                NETLIFY_API,
                headers={"Authorization": f"Bearer {token}",
                         "Content-Type": "application/zip"},
                data=buf.getvalue(),
                timeout=DEPLOY_TIMEOUT,
            )
        except ValueError as e:
            return f"Error: {e}"
        except requests.RequestException as e:
            return f"Error: deploy request failed ({e})"

        if r.status_code not in (200, 201):
            return (f"Error: Netlify returned {r.status_code}: "
                    f"{r.text[:300]}")
        data = r.json()
        url = data.get("ssl_url") or data.get("url") or "(url missing)"
        return f"OK: deployed '{name}'. Live URL: {url}"
