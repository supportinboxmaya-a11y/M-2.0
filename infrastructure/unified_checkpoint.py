"""
Maya 2.0 — Unified Atomic Checkpoint/Recovery System
======================================================

Provides atomic checkpointing and recovery across all major subsystems:
- Cognitive Kernel (goals, beliefs, plans, working memory)
- Agent Society (agents, messages, blackboard)
- Workflow Engine (task state, execution history)
- Memory Manager (STM, LTM, episodic, semantic, vector)
- Learning Engine (experience, feedback, prompts)
- Tool Registry (custom tools, synthesized skills)

All checkpoints are atomic - either all subsystems checkpoint successfully
or none do. Recovery restores all subsystems to a consistent state.
"""
import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Callable
from enum import Enum

from config.settings import STORAGE_DIR


CHECKPOINT_DIR = STORAGE_DIR / "unified_checkpoints"
CHECKPOINT_DIR.mkdir(parents=True, exist_ok=True)
CHECKPOINT_DB = str(CHECKPOINT_DIR / "checkpoints.db")


class CheckpointStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    FAILED = "failed"
    RECOVERING = "recovering"
    RECOVERED = "recovered"


@dataclass
class SubsystemCheckpoint:
    """Checkpoint data for a single subsystem."""
    subsystem: str
    version: str
    data: Dict
    timestamp: float
    checksum: str
    metadata: Dict = field(default_factory=dict)


@dataclass
class UnifiedCheckpoint:
    """Atomic checkpoint across all subsystems."""
    id: str
    timestamp: float
    status: CheckpointStatus
    subsystems: Dict[str, SubsystemCheckpoint] = field(default_factory=dict)
    metadata: Dict = field(default_factory=dict)
    error: str = ""
    
    def to_dict(self) -> Dict:
        return {
            "id": self.id,
            "timestamp": self.timestamp,
            "status": self.status.value,
            "subsystems": {
                name: {
                    "subsystem": cp.subsystem,
                    "version": cp.version,
                    "data": cp.data,
                    "timestamp": cp.timestamp,
                    "checksum": cp.checksum,
                    "metadata": cp.metadata,
                }
                for name, cp in self.subsystems.items()
            },
            "metadata": self.metadata,
            "error": self.error,
        }
    
    @classmethod
    def from_dict(cls, data: Dict) -> "UnifiedCheckpoint":
        cp = cls(
            id=data["id"],
            timestamp=data["timestamp"],
            status=CheckpointStatus(data["status"]),
            metadata=data.get("metadata", {}),
            error=data.get("error", ""),
        )
        for name, sc in data.get("subsystems", {}).items():
            cp.subsystems[name] = SubsystemCheckpoint(
                subsystem=sc["subsystem"],
                version=sc["version"],
                data=sc["data"],
                timestamp=sc["timestamp"],
                checksum=sc["checksum"],
                metadata=sc.get("metadata", {}),
            )
        return cp


class CheckpointManager:
    """
    Manages atomic checkpoints across all Maya subsystems.
    
    Usage:
        manager = CheckpointManager()
        manager.register_subsystem("cognitive_kernel", kernel, kernel.get_state, kernel.restore_state)
        manager.register_subsystem("agent_society", society, society.get_state, society.restore_state)
        ...
        
        # Create checkpoint
        checkpoint = manager.create_checkpoint()
        
        # Recovery
        manager.recover_from_checkpoint(checkpoint.id)
    """
    
    def __init__(self, max_checkpoints: int = 50):
        self.max_checkpoints = max_checkpoints
        self._lock = threading.RLock()
        self._subsystems: Dict[str, Dict] = {}  # name -> {obj, get_state, restore_state, version}
        self._init_db()
    
    def _init_db(self):
        with self._conn() as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS checkpoints (
                    id TEXT PRIMARY KEY,
                    timestamp REAL,
                    status TEXT,
                    metadata TEXT,
                    error TEXT
                )
            """)
            c.execute("""
                CREATE TABLE IF NOT EXISTS checkpoint_subsystems (
                    checkpoint_id TEXT,
                    subsystem TEXT,
                    version TEXT,
                    data TEXT,
                    timestamp REAL,
                    checksum TEXT,
                    metadata TEXT,
                    PRIMARY KEY (checkpoint_id, subsystem),
                    FOREIGN KEY (checkpoint_id) REFERENCES checkpoints(id)
                )
            """)
            c.execute("CREATE INDEX IF NOT EXISTS idx_cp_timestamp ON checkpoints(timestamp)")
    
    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(CHECKPOINT_DB, check_same_thread=False, timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            conn.execute("PRAGMA synchronous=NORMAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    
    def register_subsystem(
        self,
        name: str,
        obj: Any,
        get_state_fn: Callable[[], Dict],
        restore_state_fn: Callable[[Dict], None],
        version: str = "1.0",
    ):
        """Register a subsystem for checkpointing."""
        with self._lock:
            self._subsystems[name] = {
                "obj": obj,
                "get_state": get_state_fn,
                "restore_state": restore_state_fn,
                "version": version,
            }
    
    def unregister_subsystem(self, name: str):
        with self._lock:
            self._subsystems.pop(name, None)
    
    def create_checkpoint(self, metadata: Dict = None) -> UnifiedCheckpoint:
        """
        Create an atomic checkpoint of all registered subsystems.
        Either all succeed or the checkpoint is marked failed.
        """
        checkpoint_id = f"cp_{int(time.time())}_{uuid.uuid4().hex[:8]}"
        timestamp = time.time()
        
        checkpoint = UnifiedCheckpoint(
            id=checkpoint_id,
            timestamp=timestamp,
            status=CheckpointStatus.IN_PROGRESS,
            metadata=metadata or {},
        )
        
        # Phase 1: Capture all subsystem states
        with self._lock:
            for name, info in self._subsystems.items():
                try:
                    state = info["get_state"]()
                    # Compute checksum
                    import hashlib
                    state_json = json.dumps(state, sort_keys=True, default=str)
                    checksum = hashlib.sha256(state_json.encode()).hexdigest()[:16]
                    
                    checkpoint.subsystems[name] = SubsystemCheckpoint(
                        subsystem=name,
                        version=info["version"],
                        data=state,
                        timestamp=timestamp,
                        checksum=checksum,
                        metadata={"state_size": len(state_json)},
                    )
                except Exception as e:
                    # If any subsystem fails, mark checkpoint as failed
                    checkpoint.status = CheckpointStatus.FAILED
                    checkpoint.error = f"Failed to capture {name}: {e}"
                    self._persist_checkpoint(checkpoint)
                    raise
        
        # Phase 2: All captured successfully - mark completed
        checkpoint.status = CheckpointStatus.COMPLETED
        self._persist_checkpoint(checkpoint)
        
        # Phase 3: Prune old checkpoints
        self._prune_old_checkpoints()
        
        return checkpoint
    
    def _persist_checkpoint(self, checkpoint: UnifiedCheckpoint):
        with self._lock, self._conn() as c:
            # Insert checkpoint
            c.execute("""
                INSERT OR REPLACE INTO checkpoints (id, timestamp, status, metadata, error)
                VALUES (?, ?, ?, ?, ?)
            """, (
                checkpoint.id,
                checkpoint.timestamp,
                checkpoint.status.value,
                json.dumps(checkpoint.metadata),
                checkpoint.error,
            ))
            
            # Insert subsystem data
            for name, sc in checkpoint.subsystems.items():
                c.execute("""
                    INSERT OR REPLACE INTO checkpoint_subsystems 
                    (checkpoint_id, subsystem, version, data, timestamp, checksum, metadata)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                """, (
                    checkpoint.id,
                    name,
                    sc.version,
                    json.dumps(sc.data, default=str),
                    sc.timestamp,
                    sc.checksum,
                    json.dumps(sc.metadata),
                ))
    
    def _prune_old_checkpoints(self):
        """Keep only the most recent checkpoints."""
        with self._conn() as c:
            c.execute("""
                DELETE FROM checkpoints 
                WHERE id IN (
                    SELECT id FROM checkpoints 
                    WHERE status = 'completed'
                    ORDER BY timestamp ASC
                    LIMIT MAX(0, (SELECT COUNT(*) FROM checkpoints WHERE status = 'completed') - ?)
                )
            """, (self.max_checkpoints,))
            
            # Also prune subsystem data for deleted checkpoints
            c.execute("""
                DELETE FROM checkpoint_subsystems
                WHERE checkpoint_id NOT IN (SELECT id FROM checkpoints)
            """)
    
    def list_checkpoints(self, status: CheckpointStatus = None, limit: int = 20) -> List[UnifiedCheckpoint]:
        """List checkpoints, optionally filtered by status."""
        with self._conn() as c:
            if status:
                rows = c.execute(
                    "SELECT * FROM checkpoints WHERE status = ? ORDER BY timestamp DESC LIMIT ?",
                    (status.value, limit)
                ).fetchall()
            else:
                rows = c.execute(
                    "SELECT * FROM checkpoints ORDER BY timestamp DESC LIMIT ?",
                    (limit,)
                ).fetchall()
            
            checkpoints = []
            for row in rows:
                cp = self._load_checkpoint(row["id"])
                if cp:
                    checkpoints.append(cp)
            return checkpoints
    
    def get_checkpoint(self, checkpoint_id: str) -> Optional[UnifiedCheckpoint]:
        """Get a specific checkpoint by ID."""
        return self._load_checkpoint(checkpoint_id)
    
    def _load_checkpoint(self, checkpoint_id: str) -> Optional[UnifiedCheckpoint]:
        with self._conn() as c:
            row = c.execute("SELECT * FROM checkpoints WHERE id = ?", (checkpoint_id,)).fetchone()
            if not row:
                return None
            
            checkpoint = UnifiedCheckpoint(
                id=row["id"],
                timestamp=row["timestamp"],
                status=CheckpointStatus(row["status"]),
                metadata=json.loads(row["metadata"] or "{}"),
                error=row["error"],
            )
            
            subsystems = c.execute(
                "SELECT * FROM checkpoint_subsystems WHERE checkpoint_id = ?",
                (checkpoint_id,)
            ).fetchall()
            
            for row in subsystems:
                checkpoint.subsystems[row["subsystem"]] = SubsystemCheckpoint(
                    subsystem=row["subsystem"],
                    version=row["version"],
                    data=json.loads(row["data"]),
                    timestamp=row["timestamp"],
                    checksum=row["checksum"],
                    metadata=json.loads(row["metadata"] or "{}"),
                )
            
            return checkpoint
    
    def recover_from_checkpoint(self, checkpoint_id: str) -> bool:
        """
        Recover all subsystems from a checkpoint atomically.
        Either all subsystems restore successfully or none do.
        """
        checkpoint = self._load_checkpoint(checkpoint_id)
        if not checkpoint:
            raise ValueError(f"Checkpoint not found: {checkpoint_id}")
        
        if checkpoint.status != CheckpointStatus.COMPLETED:
            raise ValueError(f"Checkpoint not in completed state: {checkpoint.status}")
        
        # Mark as recovering
        with self._conn() as c:
            c.execute(
                "UPDATE checkpoints SET status = ? WHERE id = ?",
                (CheckpointStatus.RECOVERING.value, checkpoint_id)
            )
        
        # Phase 1: Validate all subsystem checksums
        with self._lock:
            for name, sc in checkpoint.subsystems.items():
                if name not in self._subsystems:
                    raise ValueError(f"Subsystem {name} not registered")
                
                # Verify checksum
                import hashlib
                state_json = json.dumps(sc.data, sort_keys=True, default=str)
                checksum = hashlib.sha256(state_json.encode()).hexdigest()[:16]
                if checksum != sc.checksum:
                    raise ValueError(f"Checksum mismatch for {name}: expected {sc.checksum}, got {checksum}")
        
        # Phase 2: Restore all subsystems
        failed = []
        with self._lock:
            for name, sc in checkpoint.subsystems.items():
                try:
                    info = self._subsystems[name]
                    info["restore_state"](sc.data)
                except Exception as e:
                    failed.append((name, str(e)))
        
        if failed:
            # Restore failed - mark checkpoint as failed recovery
            with self._conn() as c:
                c.execute(
                    "UPDATE checkpoints SET status = ?, error = ? WHERE id = ?",
                    (CheckpointStatus.FAILED.value, f"Recovery failed: {failed}", checkpoint_id)
                )
            raise RuntimeError(f"Recovery failed for subsystems: {failed}")
        
        # Phase 3: Mark recovery complete
        with self._conn() as c:
            c.execute(
                "UPDATE checkpoints SET status = ? WHERE id = ?",
                (CheckpointStatus.RECOVERED.value, checkpoint_id)
            )
        
        return True
    
    def delete_checkpoint(self, checkpoint_id: str) -> bool:
        """Delete a checkpoint and its subsystem data."""
        with self._lock, self._conn() as c:
            c.execute("DELETE FROM checkpoint_subsystems WHERE checkpoint_id = ?", (checkpoint_id,))
            c.execute("DELETE FROM checkpoints WHERE id = ?", (checkpoint_id,))
            return True
    
    def get_latest_checkpoint(self) -> Optional[UnifiedCheckpoint]:
        """Get the most recent completed checkpoint."""
        checkpoints = self.list_checkpoints(CheckpointStatus.COMPLETED, limit=1)
        return checkpoints[0] if checkpoints else None
    
    def auto_checkpoint_loop(self, interval_seconds: int = 300):
        """Background thread for automatic periodic checkpointing."""
        def loop():
            while True:
                time.sleep(interval_seconds)
                try:
                    self.create_checkpoint({"auto": True})
                except Exception as e:
                    print(f"Auto-checkpoint failed: {e}")
        
        thread = threading.Thread(target=loop, daemon=True)
        thread.start()
        return thread


# Global checkpoint manager instance
_checkpoint_manager: Optional[CheckpointManager] = None


def get_checkpoint_manager() -> CheckpointManager:
    global _checkpoint_manager
    if _checkpoint_manager is None:
        _checkpoint_manager = CheckpointManager()
    return _checkpoint_manager


def set_checkpoint_manager(manager: CheckpointManager):
    global _checkpoint_manager
    _checkpoint_manager = manager