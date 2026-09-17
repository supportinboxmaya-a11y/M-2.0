"""
Maya 2.0 — Capability Registry (Phase 18)
==========================================
Dynamic registry for tools, agents, skills, and workflows.
Supports versioning, provenance, verification history, and composability.
"""

import asyncio
import hashlib
import json
import os
import sqlite3
import threading
import time
import uuid
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from tools.registry import ToolRegistry

from config.settings import STORAGE_DIR


CAP_REGISTRY_DIR = STORAGE_DIR / "capability_registry"
CAP_REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
CAP_REGISTRY_DB = str(CAP_REGISTRY_DIR / "capabilities.db")
CAPABILITY_CODE_DIR = CAP_REGISTRY_DIR / "code"
CAPABILITY_CODE_DIR.mkdir(parents=True, exist_ok=True)


class CapabilityType(Enum):
    TOOL = "tool"
    AGENT = "agent"
    SKILL = "skill"
    WORKFLOW = "workflow"
    WORLD_MODEL = "world_model"


class CapabilityStatus(Enum):
    DRAFT = "draft"
    TESTING = "testing"
    VERIFIED = "verified"
    DEPRECATED = "deprecated"
    BLOCKED = "blocked"


@dataclass
class CapabilityInterface:
    """Type-safe interface definition for a capability."""
    name: str
    description: str
    input_schema: Dict  # JSON Schema
    output_schema: Dict  # JSON Schema
    parameters: Dict = field(default_factory=dict)  # Parameter definitions
    returns: Dict = field(default_factory=dict)
    examples: List[Dict] = field(default_factory=list)
    preconditions: List[str] = field(default_factory=list)
    postconditions: List[str] = field(default_factory=list)
    side_effects: List[str] = field(default_factory=list)


@dataclass
class CapabilityMetadata:
    """Metadata about a capability."""
    capability_type: CapabilityType
    domain_tags: List[str] = field(default_factory=list)
    version: str = "1.0.0"
    author: str = "maya"
    created_at: float = field(default_factory=time.time)
    updated_at: float = field(default_factory=time.time)
    verification_status: CapabilityStatus = CapabilityStatus.DRAFT
    verification_history: List[Dict] = field(default_factory=list)
    performance_metrics: Dict = field(default_factory=dict)
    reliability_score: float = 0.0  # 0.0 to 1.0
    avg_latency_ms: float = 0.0
    success_rate: float = 0.0
    cost_estimate: float = 0.0
    dependencies: List[str] = field(default_factory=list)  # Other capability IDs
    composes_with: List[str] = field(default_factory=list)  # Capability IDs that work well together
    conflicts_with: List[str] = field(default_factory=list)
    provenance: Dict = field(default_factory=dict)  # How this was created
    source_code_hash: str = ""
    test_cases: List[Dict] = field(default_factory=list)
    usage_count: int = 0
    last_used: Optional[float] = None


@dataclass
class Capability:
    """A registered capability with interface, implementation, and metadata."""
    id: str
    name: str
    interface: CapabilityInterface
    metadata: CapabilityMetadata
    implementation: str  # Python code as string
    entry_point: str  # Function/class name to call
    config: Dict = field(default_factory=dict)

    def to_dict(self) -> Dict:
        return {
            "id": self.id,
            "name": self.name,
            "interface": {
                "name": self.interface.name,
                "description": self.interface.description,
                "input_schema": self.interface.input_schema,
                "output_schema": self.interface.output_schema,
                "parameters": self.interface.parameters,
                "returns": self.interface.returns,
                "examples": self.interface.examples,
                "preconditions": self.interface.preconditions,
                "postconditions": self.interface.postconditions,
                "side_effects": self.interface.side_effects,
            },
            "metadata": {
                "capability_type": self.metadata.capability_type.value,
                "domain_tags": self.metadata.domain_tags,
                "version": self.metadata.version,
                "author": self.metadata.author,
                "created_at": self.metadata.created_at,
                "updated_at": self.metadata.updated_at,
                "verification_status": self.metadata.verification_status.value,
                "verification_history": self.metadata.verification_history,
                "performance_metrics": self.metadata.performance_metrics,
                "reliability_score": self.metadata.reliability_score,
                "avg_latency_ms": self.metadata.avg_latency_ms,
                "success_rate": self.metadata.success_rate,
                "cost_estimate": self.metadata.cost_estimate,
                "dependencies": self.metadata.dependencies,
                "composes_with": self.metadata.composes_with,
                "conflicts_with": self.metadata.conflicts_with,
                "provenance": self.metadata.provenance,
                "source_code_hash": self.metadata.source_code_hash,
                "test_cases": self.metadata.test_cases,
                "usage_count": self.metadata.usage_count,
                "last_used": self.metadata.last_used,
            },
            "implementation": self.implementation,
            "entry_point": self.entry_point,
            "config": self.config,
        }


class CapabilityRegistry:
    """
    Dynamic capability registry with versioning, verification, and composability.
    """

    def __init__(self, tool_registry: Optional["ToolRegistry"] = None):
        self.tool_registry = tool_registry
        self._lock = threading.RLock()
        self._capabilities: Dict[str, Capability] = {}  # id -> Capability
        self._name_index: Dict[str, str] = {}  # name -> id (latest version)
        self._tag_index: Dict[str, Set[str]] = {}  # tag -> set of ids
        self._type_index: Dict[CapabilityType, Set[str]] = {t: set() for t in CapabilityType}
        self._init_db()
        self._load_from_db()

    def _init_db(self) -> None:
        with self._conn() as c:
            c.executescript("""
            CREATE TABLE IF NOT EXISTS capabilities (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                interface TEXT NOT NULL,
                metadata TEXT NOT NULL,
                implementation TEXT NOT NULL,
                entry_point TEXT NOT NULL,
                config TEXT DEFAULT '{}'
            );

            CREATE TABLE IF NOT EXISTS capability_versions (
                id TEXT PRIMARY KEY,
                capability_id TEXT NOT NULL,
                version TEXT NOT NULL,
                interface TEXT NOT NULL,
                metadata TEXT NOT NULL,
                implementation TEXT NOT NULL,
                entry_point TEXT NOT NULL,
                config TEXT DEFAULT '{}',
                created_at REAL,
                FOREIGN KEY (capability_id) REFERENCES capabilities(id)
            );

            CREATE TABLE IF NOT EXISTS capability_relations (
                source_id TEXT NOT NULL,
                target_id TEXT NOT NULL,
                relation_type TEXT NOT NULL,  -- composes_with, depends_on, conflicts_with
                created_at REAL,
                PRIMARY KEY (source_id, target_id, relation_type)
            );

            CREATE TABLE IF NOT EXISTS verification_log (
                id TEXT PRIMARY KEY,
                capability_id TEXT NOT NULL,
                test_suite TEXT,
                results TEXT,
                passed BOOLEAN,
                score REAL,
                timestamp REAL,
                details TEXT
            );

            CREATE TABLE IF NOT EXISTS usage_log (
                id TEXT PRIMARY KEY,
                capability_id TEXT NOT NULL,
                success BOOLEAN,
                latency_ms REAL,
                error TEXT,
                timestamp REAL,
                context TEXT
            );

            CREATE INDEX IF NOT EXISTS idx_cap_name ON capabilities(name);
            CREATE INDEX IF NOT EXISTS idx_cap_type ON capabilities(id);  -- via metadata
            CREATE INDEX IF NOT EXISTS idx_ver_cap ON verification_log(capability_id);
            CREATE INDEX IF NOT EXISTS idx_usage_cap ON usage_log(capability_id);
            """)

    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(CAP_REGISTRY_DB, check_same_thread=False, timeout=30)
        conn.row_factory = sqlite3.Row
        try:
            conn.execute("PRAGMA journal_mode=WAL")
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def _load_from_db(self) -> None:
        with self._lock, self._conn() as c:
            rows = c.execute("SELECT * FROM capabilities").fetchall()
            for row in rows:
                cap = self._row_to_capability(row)
                self._capabilities[cap.id] = cap
                self._update_indices(cap)

    def _row_to_capability(self, row) -> Capability:
        interface_data = json.loads(row["interface"])
        metadata_data = json.loads(row["metadata"])
        
        interface = CapabilityInterface(**interface_data)
        metadata = CapabilityMetadata(
            capability_type=CapabilityType(metadata_data["capability_type"]),
            domain_tags=metadata_data.get("domain_tags", []),
            version=metadata_data.get("version", "1.0.0"),
            author=metadata_data.get("author", "maya"),
            created_at=metadata_data.get("created_at", time.time()),
            updated_at=metadata_data.get("updated_at", time.time()),
            verification_status=CapabilityStatus(metadata_data.get("verification_status", "draft")),
            verification_history=metadata_data.get("verification_history", []),
            performance_metrics=metadata_data.get("performance_metrics", {}),
            reliability_score=metadata_data.get("reliability_score", 0.0),
            avg_latency_ms=metadata_data.get("avg_latency_ms", 0.0),
            success_rate=metadata_data.get("success_rate", 0.0),
            cost_estimate=metadata_data.get("cost_estimate", 0.0),
            dependencies=metadata_data.get("dependencies", []),
            composes_with=metadata_data.get("composes_with", []),
            conflicts_with=metadata_data.get("conflicts_with", []),
            provenance=metadata_data.get("provenance", {}),
            source_code_hash=metadata_data.get("source_code_hash", ""),
            test_cases=metadata_data.get("test_cases", []),
            usage_count=metadata_data.get("usage_count", 0),
            last_used=metadata_data.get("last_used"),
        )
        
        return Capability(
            id=row["id"],
            name=row["name"],
            interface=interface,
            metadata=metadata,
            implementation=row["implementation"],
            entry_point=row["entry_point"],
            config=json.loads(row["config"]),
        )

    def _save_capability(self, cap: Capability) -> None:
        with self._lock, self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO capabilities
                (id, name, interface, metadata, implementation, entry_point, config)
                VALUES (?,?,?,?,?,?,?)
            """, (
                cap.id, cap.name, json.dumps(cap.interface.__dict__),
                json.dumps(cap.metadata.__dict__), cap.implementation,
                cap.entry_point, json.dumps(cap.config)
            ))
            # Also save as version
            c.execute("""
                INSERT INTO capability_versions
                (id, capability_id, version, interface, metadata, implementation, entry_point, config, created_at)
                VALUES (?,?,?,?,?,?,?,?,?)
            """, (
                f"{cap.id}_v{cap.metadata.version}", cap.id, cap.metadata.version,
                json.dumps(cap.interface.__dict__), json.dumps(cap.metadata.__dict__),
                cap.implementation, cap.entry_point, json.dumps(cap.config), time.time()
            ))

    def _update_indices(self, cap: Capability) -> None:
        self._name_index[cap.name] = cap.id
        for tag in cap.metadata.domain_tags:
            self._tag_index.setdefault(tag, set()).add(cap.id)
        self._type_index[cap.metadata.capability_type].add(cap.id)

    def _remove_from_indices(self, cap: Capability) -> None:
        if self._name_index.get(cap.name) == cap.id:
            del self._name_index[cap.name]
        for tag in cap.metadata.domain_tags:
            if tag in self._tag_index:
                self._tag_index[tag].discard(cap.id)
        self._type_index[cap.metadata.capability_type].discard(cap.id)

    def register(self, capability: Capability) -> str:
        """Register a new capability or update existing."""
        with self._lock:
            # Compute code hash
            code_hash = hashlib.sha256(capability.implementation.encode()).hexdigest()[:16]
            capability.metadata.source_code_hash = code_hash
            capability.metadata.updated_at = time.time()
            
            # Save implementation to file
            code_path = CAPABILITY_CODE_DIR / f"{capability.id}.py"
            code_path.write_text(capability.implementation)
            
            # If updating, archive old version
            if capability.id in self._capabilities:
                self._save_capability(capability)  # This saves as new version too
            else:
                self._save_capability(capability)
            
            self._remove_from_indices(self._capabilities.get(capability.id, capability))
            self._capabilities[capability.id] = capability
            self._update_indices(capability)
            
            # Register with tool registry if it's a tool
            if (capability.metadata.capability_type == CapabilityType.TOOL 
                and self.tool_registry):
                self._register_tool(capability)
            
            return capability.id

    def _register_tool(self, capability: Capability) -> None:
        """Register capability as a tool in the tool registry."""
        try:
            # Execute the implementation to get the function
            namespace = {}
            exec(capability.implementation, namespace)
            func = namespace.get(capability.entry_point)
            if func and callable(func):
                self.tool_registry.register(
                    name=capability.name,
                    func=func,
                    description=capability.interface.description,
                    category=capability.metadata.domain_tags[0] if capability.metadata.domain_tags else "dynamic",
                )
        except Exception as e:
            print(f"WARNING: Failed to register tool {capability.name}: {e}")

    def unregister(self, capability_id: str) -> bool:
        """Unregister a capability."""
        with self._lock:
            cap = self._capabilities.get(capability_id)
            if not cap:
                return False
            
            # Unregister from tool registry
            if (cap.metadata.capability_type == CapabilityType.TOOL 
                and self.tool_registry):
                try:
                    self.tool_registry.unregister(cap.name)
                except Exception:
                    pass
            
            self._remove_from_indices(cap)
            del self._capabilities[capability_id]
            
            with self._conn() as c:
                c.execute("DELETE FROM capabilities WHERE id = ?", (capability_id,))
            
            # Remove code file
            code_path = CAPABILITY_CODE_DIR / f"{capability_id}.py"
            code_path.unlink(missing_ok=True)
            
            return True

    def get(self, capability_id: str) -> Optional[Capability]:
        with self._lock:
            return self._capabilities.get(capability_id)

    def get_by_name(self, name: str) -> Optional[Capability]:
        with self._lock:
            cap_id = self._name_index.get(name)
            if cap_id:
                return self._capabilities.get(cap_id)
        return None

    def list_capabilities(
        self, 
        capability_type: CapabilityType = None,
        domain_tag: str = None,
        status: CapabilityStatus = None,
        limit: int = 100
    ) -> List[Capability]:
        with self._lock:
            candidates = set(self._capabilities.keys())
            
            if capability_type:
                candidates &= self._type_index.get(capability_type, set())
            if domain_tag:
                candidates &= self._tag_index.get(domain_tag, set())
            if status:
                candidates = {cid for cid in candidates 
                            if self._capabilities[cid].metadata.verification_status == status}
            
            results = [self._capabilities[cid] for cid in candidates]
            results.sort(key=lambda c: c.metadata.updated_at, reverse=True)
            return results[:limit]

    def search(self, query: str, limit: int = 20) -> List[Capability]:
        """Search capabilities by name, description, or tags."""
        query_lower = query.lower()
        results = []
        with self._lock:
            for cap in self._capabilities.values():
                score = 0
                if query_lower in cap.name.lower():
                    score += 10
                if query_lower in cap.interface.description.lower():
                    score += 5
                if any(query_lower in tag.lower() for tag in cap.metadata.domain_tags):
                    score += 3
                if query_lower in cap.interface.name.lower():
                    score += 2
                if score > 0:
                    results.append((score, cap))
        
        results.sort(key=lambda x: x[0], reverse=True)
        return [r[1] for r in results[:limit]]

    def find_composable(self, capability_id: str, limit: int = 10) -> List[Capability]:
        """Find capabilities that compose well with the given one."""
        cap = self.get(capability_id)
        if not cap:
            return []
        
        results = []
        for target_id in cap.metadata.composes_with:
            target = self.get(target_id)
            if target:
                results.append(target)
        
        # Also find by domain tag overlap
        for tag in cap.metadata.domain_tags:
            for other_id in self._tag_index.get(tag, set()):
                if other_id != capability_id and other_id not in [r.id for r in results]:
                    other = self.get(other_id)
                    if other:
                        results.append(other)
                        if len(results) >= limit:
                            break
            if len(results) >= limit:
                break
        
        return results[:limit]

    def record_usage(self, capability_id: str, success: bool, 
                     latency_ms: float, error: str = "", context: Dict = None) -> None:
        """Record usage for performance tracking."""
        with self._lock, self._conn() as c:
            cap = self._capabilities.get(capability_id)
            if cap:
                cap.metadata.usage_count += 1
                cap.metadata.last_used = time.time()
                # Update running averages
                n = cap.metadata.usage_count
                cap.metadata.success_rate = ((n - 1) * cap.metadata.success_rate + (1 if success else 0)) / n
                cap.metadata.avg_latency_ms = ((n - 1) * cap.metadata.avg_latency_ms + latency_ms) / n
                self._save_capability(cap)
            
            c.execute("""
                INSERT INTO usage_log (id, capability_id, success, latency_ms, error, timestamp, context)
                VALUES (?,?,?,?,?,?,?)
            """, (uuid.uuid4().hex[:12], capability_id, success, latency_ms, error, time.time(), json.dumps(context or {})))

    def verify(self, capability_id: str, test_cases: List[Dict] = None) -> Dict:
        """Run verification tests on a capability."""
        cap = self.get(capability_id)
        if not cap:
            return {"error": "Capability not found", "passed": False}
        
        test_cases = test_cases or cap.metadata.test_cases
        if not test_cases:
            return {"error": "No test cases provided", "passed": False}
        
        # Execute implementation in sandbox
        namespace = {}
        try:
            exec(cap.implementation, namespace)
            func = namespace.get(cap.entry_point)
            if not func:
                return {"error": f"Entry point {cap.entry_point} not found", "passed": False}
        except Exception as e:
            return {"error": f"Implementation error: {e}", "passed": False}
        
        results = []
        passed = 0
        for i, test in enumerate(test_cases):
            test_input = test.get("input", {})
            expected = test.get("expected")
            try:
                start = time.time()
                result = func(**test_input) if isinstance(test_input, dict) else func(test_input)
                latency = (time.time() - start) * 1000
                
                # Compare result to expected
                test_passed = self._compare_results(result, expected)
                if test_passed:
                    passed += 1
                
                results.append({
                    "test_index": i,
                    "input": test_input,
                    "expected": expected,
                    "actual": result,
                    "passed": test_passed,
                    "latency_ms": latency
                })
            except Exception as e:
                results.append({
                    "test_index": i,
                    "input": test_input,
                    "expected": expected,
                    "error": str(e),
                    "passed": False
                })
        
        score = passed / len(test_cases) if test_cases else 0
        overall_passed = score >= 0.8  # 80% pass threshold
        
        # Update metadata
        with self._lock:
            cap.metadata.verification_history.append({
                "timestamp": time.time(),
                "score": score,
                "passed": overall_passed,
                "test_count": len(test_cases)
            })
            cap.metadata.performance_metrics = {
                "last_test_score": score,
                "avg_latency_ms": sum(r.get("latency_ms", 0) for r in results if "latency_ms" in r) / max(1, len([r for r in results if "latency_ms" in r])),
            }
            cap.metadata.reliability_score = score
            cap.metadata.success_rate = score
            cap.metadata.verification_status = CapabilityStatus.VERIFIED if overall_passed else CapabilityStatus.TESTING
            cap.metadata.test_cases = test_cases
            self._save_capability(cap)
        
        # Log verification
        with self._conn() as c:
            c.execute("""
                INSERT INTO verification_log (id, capability_id, test_suite, results, passed, score, timestamp, details)
                VALUES (?,?,?,?,?,?,?,?)
            """, (uuid.uuid4().hex[:12], capability_id, "default", json.dumps(results), overall_passed, score, time.time(), ""))
        
        return {
            "capability_id": capability_id,
            "passed": overall_passed,
            "score": score,
            "tests_passed": passed,
            "tests_total": len(test_cases),
            "results": results
        }

    def _compare_results(self, actual: Any, expected: Any) -> bool:
        """Compare actual result to expected (flexible matching)."""
        if expected is None:
            return True
        if isinstance(expected, dict) and isinstance(actual, dict):
            return all(self._compare_results(actual.get(k), v) for k, v in expected.items())
        if isinstance(expected, list) and isinstance(actual, list):
            if len(expected) != len(actual):
                return False
            return all(self._compare_results(a, e) for a, e in zip(actual, expected))
        return actual == expected

    def add_relation(self, source_id: str, target_id: str, relation_type: str) -> bool:
        """Add a composability/dependency/conflict relation."""
        if source_id not in self._capabilities or target_id not in self._capabilities:
            return False
        if relation_type not in ("composes_with", "depends_on", "conflicts_with"):
            return False
        
        with self._lock, self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO capability_relations
                (source_id, target_id, relation_type, created_at)
                VALUES (?,?,?,?)
            """, (source_id, target_id, relation_type, time.time()))
        
        # Update in-memory metadata
        source = self._capabilities[source_id]
        if relation_type == "composes_with":
            source.metadata.composes_with.append(target_id)
        elif relation_type == "depends_on":
            source.metadata.dependencies.append(target_id)
        elif relation_type == "conflicts_with":
            source.metadata.conflicts_with.append(target_id)
        self._save_capability(source)
        return True

    def get_relations(self, capability_id: str) -> Dict:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM capability_relations WHERE source_id = ? OR target_id = ?",
                (capability_id, capability_id)
            ).fetchall()
        
        relations = {"composes_with": [], "depends_on": [], "conflicts_with": [], "reverse": []}
        for row in rows:
            if row["source_id"] == capability_id:
                relations[row["relation_type"]].append(row["target_id"])
            else:
                relations["reverse"].append({
                    "source": row["source_id"],
                    "type": row["relation_type"]
                })
        return relations

    def get_versions(self, capability_id: str) -> List[Dict]:
        with self._conn() as c:
            rows = c.execute(
                "SELECT * FROM capability_versions WHERE capability_id = ? ORDER BY created_at DESC",
                (capability_id,)
            ).fetchall()
        return [dict(r) for r in rows]

    def rollback(self, capability_id: str, version: str) -> bool:
        """Rollback to a previous version."""
        with self._conn() as c:
            row = c.execute(
                "SELECT * FROM capability_versions WHERE capability_id = ? AND version = ?",
                (capability_id, version)
            ).fetchone()
        if not row:
            return False
        
        cap = self._row_to_capability(row)
        cap.metadata.updated_at = time.time()
        cap.metadata.verification_status = CapabilityStatus.DRAFT
        self.register(cap)
        return True

    def stats(self) -> Dict:
        with self._lock:
            by_type = {}
            by_status = {}
            for cap in self._capabilities.values():
                t = cap.metadata.capability_type.value
                by_type[t] = by_type.get(t, 0) + 1
                s = cap.metadata.verification_status.value
                by_status[s] = by_status.get(s, 0) + 1
            
            total_usage = sum(c.metadata.usage_count for c in self._capabilities.values())
            avg_reliability = sum(c.metadata.reliability_score for c in self._capabilities.values()) / max(1, len(self._capabilities))
            
            return {
                "total_capabilities": len(self._capabilities),
                "by_type": by_type,
                "by_status": by_status,
                "total_usage": total_usage,
                "avg_reliability": avg_reliability,
            }


# Module singleton
_capability_registry: Optional[CapabilityRegistry] = None


def get_capability_registry(tool_registry=None) -> CapabilityRegistry:
    global _capability_registry
    if _capability_registry is None:
        _capability_registry = CapabilityRegistry(tool_registry)
    return _capability_registry


def set_capability_registry(registry: CapabilityRegistry) -> None:
    global _capability_registry
    _capability_registry = registry