"""Checkpoint stores for workflow state (memory + JSON file)."""
import json
import pathlib
import threading


class MemoryCheckpoint:
    def __init__(self):
        self._data: dict = {}
        self._lock = threading.Lock()

    def save(self, run_id: str, state: dict) -> None:
        with self._lock:
            self._data[run_id] = json.loads(json.dumps(state))  # deep copy

    def load(self, run_id: str) -> dict | None:
        with self._lock:
            return self._data.get(run_id)

    def list(self) -> list:
        with self._lock:
            return list(self._data.keys())


class FileCheckpoint:
    def __init__(self, directory: str = "storage/checkpoints"):
        self.dir = pathlib.Path(directory)
        self.dir.mkdir(parents=True, exist_ok=True)

    def save(self, run_id: str, state: dict) -> None:
        (self.dir / f"{run_id}.json").write_text(json.dumps(state, default=str))

    def load(self, run_id: str) -> dict | None:
        p = self.dir / f"{run_id}.json"
        return json.loads(p.read_text()) if p.exists() else None

    def list(self) -> list:
        return [p.stem for p in self.dir.glob("*.json")]
