"""
Shared path-safety helper for file-based tools (zip/csv/json/excel).

Every new file tool resolves user/LLM-given filenames through this instead
of joining paths directly — without it, a filename like "../../etc/passwd"
or an absolute path would let a tool read/write outside the workspace.
"""
from pathlib import Path
from config.settings import WORKSPACE_DIR


def resolve_safe_path(filename: str) -> Path:
    """Resolves `filename` to a path inside WORKSPACE_DIR.
    Raises ValueError if it would escape that directory."""
    if not filename or not str(filename).strip():
        raise ValueError("filename is required")
    workspace = Path(WORKSPACE_DIR).resolve()
    target = (workspace / filename).resolve()
    try:
        target.relative_to(workspace)
    except ValueError:
        raise ValueError(f"path '{filename}' escapes the workspace directory")
    return target
