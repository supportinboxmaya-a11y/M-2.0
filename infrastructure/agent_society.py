"""
Maya 2.0 — Agent Society (Phase 18)
====================================
Dynamic agent spawning, coordination via blackboard, contract net protocol.
Agents can specialize, learn, and coordinate on complex tasks.
"""

import asyncio
import json
import threading
import time
import uuid
from collections import defaultdict
from contextlib import contextmanager
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Set
import sqlite3

from config.settings import STORAGE_DIR

from infrastructure.capability_registry import CapabilityType, get_capability_registry
from infrastructure.cognitive_kernel import CognitiveKernel, Goal, GoalStatus


SOCIETY_DIR = STORAGE_DIR / "agent_society"
SOCIETY_DIR.mkdir(parents=True, exist_ok=True)
SOCIETY_DB = str(SOCIETY_DIR / "society.db")


class AgentStatus(Enum):
    IDLE = "idle"
    BUSY = "busy"
    WAITING = "waiting"
    ERROR = "error"
    TERMINATED = "terminated"


class MessageType(Enum):
    TASK_REQUEST = "task_request"
    TASK_RESPONSE = "task_response"
    BID = "bid"
    AWARD = "award"
    RESULT = "result"
    INFO_SHARE = "info_share"
    COORDINATION = "coordination"
    HEARTBEAT = "heartbeat"


@dataclass
class AgentMessage:
    """Message between agents."""
    id: str
    sender_id: str
    recipient_id: Optional[str]  # None = broadcast
    message_type: MessageType
    content: Dict
    timestamp: float = field(default_factory=time.time)
    conversation_id: Optional[str] = None
    requires_response: bool = False


@dataclass
class BlackboardEntry:
    """Entry on the shared blackboard."""
    key: str
    value: Any
    author_id: str
    timestamp: float = field(default_factory=time.time)
    tags: List[str] = field(default_factory=list)
    expires_at: Optional[float] = None
    version: int = 1


@dataclass
class TaskBid:
    """Bid for a task in contract net protocol."""
    task_id: str
    agent_id: str
    estimated_cost: float
    estimated_duration: float
    confidence: float
    proposed_approach: str
    metadata: Dict = field(default_factory=dict)


@dataclass
class Agent:
    """An agent in the society."""
    id: str
    name: str
    role: str  # researcher, coder, planner, executor, critic, etc.
    capabilities: List[str] = field(default_factory=list)  # Capability IDs
    status: AgentStatus = AgentStatus.IDLE
    current_task: Optional[str] = None
    created_at: float = field(default_factory=time.time)
    last_heartbeat: float = field(default_factory=time.time)
    metadata: Dict = field(default_factory=dict)
    performance: Dict = field(default_factory=dict)  # success_rate, avg_duration, etc.
    memory_scope: str = ""  # Isolated memory scope


class ContractNetManager:
    """Manages contract net protocol for task allocation."""
    
    def __init__(self):
        self.active_tenders: Dict[str, Dict] = {}  # task_id -> {deadline, bids, awarded}
        self._lock = threading.Lock()
    
    def announce_task(self, task_id: str, task_spec: Dict, 
                      deadline: float = None, eligible_agents: List[str] = None) -> Dict:
        """Announce a task for bidding."""
        with self._lock:
            tender = {
                "task_id": task_id,
                "task_spec": task_spec,
                "announced_at": time.time(),
                "deadline": deadline or (time.time() + 60),  # 1 minute default
                "bids": {},
                "awarded_to": None,
                "eligible_agents": eligible_agents,
            }
            self.active_tenders[task_id] = tender
        return tender
    
    def submit_bid(self, task_id: str, bid: TaskBid) -> bool:
        """Submit a bid for a task."""
        with self._lock:
            tender = self.active_tenders.get(task_id)
            if not tender:
                return False
            if time.time() > tender["deadline"]:
                return False
            
            tender["bids"][bid.agent_id] = bid.__dict__
        return True
    
    def award_task(self, task_id: str, selector: Callable[[List[TaskBid]], Optional[TaskBid]] = None) -> Optional[str]:
        """Award task to best bidder."""
        with self._lock:
            tender = self.active_tenders.get(task_id)
            if not tender or not tender["bids"]:
                return None
            
            bids = [TaskBid(**b) for b in tender["bids"].values()]
            
            if selector:
                winner = selector(bids)
            else:
                # Default: highest confidence * (1/cost) * (1/duration)
                winner = max(bids, key=lambda b: b.confidence / max(0.01, b.estimated_cost * b.estimated_duration))
            
            tender["awarded_to"] = winner.agent_id
            tender["awarded_at"] = time.time()
            return winner.agent_id
    
    def get_tender(self, task_id: str) -> Optional[Dict]:
        with self._lock:
            return self.active_tenders.get(task_id)
    
    def cleanup_expired(self) -> int:
        """Remove expired tenders."""
        with self._lock:
            now = time.time()
            expired = [tid for tid, t in self.active_tenders.items() 
                      if t["deadline"] < now and not t["awarded_to"]]
            for tid in expired:
                del self.active_tenders[tid]
            return len(expired)


class Blackboard:
    """Shared blackboard for agent coordination."""
    
    def __init__(self):
        self._entries: Dict[str, BlackboardEntry] = {}
        self._lock = threading.RLock()
        self._subscribers: Dict[str, List[Callable]] = defaultdict(list)  # key pattern -> callbacks
    
    def write(self, key: str, value: Any, author_id: str, 
              tags: List[str] = None, ttl: float = None) -> BlackboardEntry:
        """Write to blackboard."""
        with self._lock:
            entry = BlackboardEntry(
                key=key,
                value=value,
                author_id=author_id,
                tags=tags or [],
                expires_at=time.time() + ttl if ttl else None,
            )
            self._entries[key] = entry
            
            # Notify subscribers
            for pattern, callbacks in self._subscribers.items():
                if self._match_pattern(key, pattern):
                    for cb in callbacks:
                        try:
                            cb(key, value)
                        except Exception:
                            pass
        return entry
    
    def read(self, key: str) -> Optional[BlackboardEntry]:
        """Read from blackboard."""
        with self._lock:
            entry = self._entries.get(key)
            if entry and entry.expires_at and entry.expires_at < time.time():
                del self._entries[key]
                return None
            return entry
    
    def read_value(self, key: str, default: Any = None) -> Any:
        entry = self.read(key)
        return entry.value if entry else default
    
    def delete(self, key: str) -> bool:
        with self._lock:
            if key in self._entries:
                del self._entries[key]
                return True
        return False
    
    def query(self, tags: List[str] = None, author: str = None, 
              pattern: str = None) -> List[BlackboardEntry]:
        """Query blackboard entries."""
        with self._lock:
            results = []
            for entry in self._entries.values():
                if entry.expires_at and entry.expires_at < time.time():
                    continue
                if tags and not any(t in entry.tags for t in tags):
                    continue
                if author and entry.author_id != author:
                    continue
                if pattern and not self._match_pattern(entry.key, pattern):
                    continue
                results.append(entry)
            return results
    
    def subscribe(self, pattern: str, callback: Callable[[str, Any], None]) -> None:
        """Subscribe to key pattern changes."""
        with self._lock:
            self._subscribers[pattern].append(callback)
    
    def unsubscribe(self, pattern: str, callback: Callable) -> bool:
        with self._lock:
            if pattern in self._subscribers:
                try:
                    self._subscribers[pattern].remove(callback)
                    return True
                except ValueError:
                    pass
        return False
    
    def _match_pattern(self, key: str, pattern: str) -> bool:
        """Simple pattern matching with * wildcard."""
        import fnmatch
        return fnmatch.fnmatch(key, pattern)
    
    def cleanup_expired(self) -> int:
        with self._lock:
            now = time.time()
            expired = [k for k, v in self._entries.items() 
                      if v.expires_at and v.expires_at < now]
            for k in expired:
                del self._entries[k]
            return len(expired)


class AgentSociety:
    """
    Manages a society of agents with dynamic spawning, coordination, and learning.
    """
    
    def __init__(
        self,
        kernel: CognitiveKernel,
        capability_registry=None,
        llm_fn: Callable = None,
        approval_manager=None,
    ):
        self.kernel = kernel
        self.capability_registry = capability_registry or get_capability_registry()
        self.llm_fn = llm_fn
        self.approval = approval_manager
        
        self.agents: Dict[str, Agent] = {}
        self.blackboard = Blackboard()
        self.contract_net = ContractNetManager()
        self.message_bus: List[AgentMessage] = []
        self.message_queues: Dict[str, List[AgentMessage]] = defaultdict(list)
        
        self._lock = threading.RLock()
        self._agent_factories: Dict[str, Callable] = {}
        self._register_default_factories()
        
        # Persistence
        self._init_db()
        self._load_agents()
        
        # Background tasks
        self._running = False
        self._bg_thread: Optional[threading.Thread] = None
    
    def _init_db(self) -> None:
        with self._conn() as c:
            c.execute("""
                CREATE TABLE IF NOT EXISTS agents (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    role TEXT NOT NULL,
                    capabilities TEXT DEFAULT '[]',
                    status TEXT DEFAULT 'idle',
                    current_task TEXT,
                    created_at REAL,
                    last_heartbeat REAL,
                    metadata TEXT DEFAULT '{}',
                    performance TEXT DEFAULT '{}',
                    memory_scope TEXT DEFAULT ''
                )
            """)
            c.execute("""
                CREATE TABLE IF NOT EXISTS agent_messages (
                    id TEXT PRIMARY KEY,
                    sender_id TEXT,
                    recipient_id TEXT,
                    message_type TEXT,
                    content TEXT,
                    timestamp REAL,
                    conversation_id TEXT,
                    requires_response INTEGER
                )
            """)
            c.execute("""
                CREATE TABLE IF NOT EXISTS blackboard_entries (
                    key TEXT PRIMARY KEY,
                    value TEXT,
                    author_id TEXT,
                    timestamp REAL,
                    tags TEXT DEFAULT '[]',
                    expires_at REAL,
                    version INTEGER DEFAULT 1
                )
            """)
    
    @contextmanager
    def _conn(self):
        conn = sqlite3.connect(SOCIETY_DB, check_same_thread=False, timeout=30)
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
    
    def _register_default_factories(self) -> None:
        """Register default agent factories."""
        self._agent_factories["researcher"] = lambda spec: self._create_researcher_agent(spec)
        self._agent_factories["coder"] = lambda spec: self._create_coder_agent(spec)
        self._agent_factories["planner"] = lambda spec: self._create_planner_agent(spec)
        self._agent_factories["executor"] = lambda spec: self._create_executor_agent(spec)
        self._agent_factories["critic"] = lambda spec: self._create_critic_agent(spec)
        self._agent_factories["specialist"] = lambda spec: self._create_specialist_agent(spec)
    
    def _create_researcher_agent(self, spec: Dict) -> Agent:
        return Agent(
            id=uuid.uuid4().hex[:12],
            name=spec.get("name", f"researcher_{uuid.uuid4().hex[:6]}"),
            role="researcher",
            capabilities=spec.get("capabilities", ["web_search", "knowledge_search", "summarize"]),
            metadata={"focus": spec.get("focus", "general")},
        )
    
    def _create_coder_agent(self, spec: Dict) -> Agent:
        return Agent(
            id=uuid.uuid4().hex[:12],
            name=spec.get("name", f"coder_{uuid.uuid4().hex[:6]}"),
            role="coder",
            capabilities=spec.get("capabilities", ["code_generation", "code_review", "refactor", "test_generation"]),
            metadata={"languages": spec.get("languages", ["python"]), "style": spec.get("style", "clean")},
        )
    
    def _create_planner_agent(self, spec: Dict) -> Agent:
        return Agent(
            id=uuid.uuid4().hex[:12],
            name=spec.get("name", f"planner_{uuid.uuid4().hex[:6]}"),
            role="planner",
            capabilities=spec.get("capabilities", ["task_decomposition", "resource_planning", "risk_assessment"]),
            metadata={"methodology": spec.get("methodology", "htn")},
        )
    
    def _create_executor_agent(self, spec: Dict) -> Agent:
        return Agent(
            id=uuid.uuid4().hex[:12],
            name=spec.get("name", f"executor_{uuid.uuid4().hex[:6]}"),
            role="executor",
            capabilities=spec.get("capabilities", ["tool_execution", "command_run", "file_ops", "docker_ops"]),
            metadata={"environments": spec.get("environments", ["local"])},
        )
    
    def _create_critic_agent(self, spec: Dict) -> Agent:
        return Agent(
            id=uuid.uuid4().hex[:12],
            name=spec.get("name", f"critic_{uuid.uuid4().hex[:6]}"),
            role="critic",
            capabilities=spec.get("capabilities", ["code_review", "security_audit", "quality_check", "reflection"]),
            metadata={"strictness": spec.get("strictness", "high")},
        )
    
    def _create_specialist_agent(self, spec: Dict) -> Agent:
        return Agent(
            id=uuid.uuid4().hex[:12],
            name=spec.get("name", f"specialist_{spec.get('domain', 'custom')}_{uuid.uuid4().hex[:6]}"),
            role="specialist",
            capabilities=spec.get("capabilities", []),
            metadata={"domain": spec.get("domain", "custom"), "expertise": spec.get("expertise", [])},
        )
    
    def spawn_agent(self, role: str, spec: Dict = None) -> Agent:
        """Spawn a new agent of the given role."""
        spec = spec or {}
        
        # Check approval for agent creation
        if self.approval and self.approval.needs_approval(
            f"spawn_agent:{role}", risk_level="medium"
        ):
            approved = self.approval.request_approval(
                action=f"Spawn {role} agent",
                reason=f"Dynamic agent creation for role: {role}",
                risk_level="medium",
            )
            if not approved:
                raise PermissionError("Agent spawn denied by human approval")
        
        factory = self._agent_factories.get(role)
        if not factory:
            raise ValueError(f"Unknown agent role: {role}")
        
        agent = factory(spec)
        
        # Assign memory scope
        agent.memory_scope = f"agent_{agent.id}"
        
        with self._lock:
            self.agents[agent.id] = agent
            self._save_agent(agent)
        
        self.kernel._audit("agent_spawned", f"Spawned {role} agent {agent.id}: {agent.name}")
        return agent
    
    def terminate_agent(self, agent_id: str) -> bool:
        """Terminate an agent."""
        with self._lock:
            agent = self.agents.get(agent_id)
            if not agent:
                return False
            
            agent.status = AgentStatus.TERMINATED
            self._save_agent(agent)
            del self.agents[agent_id]
        
        self.kernel._audit("agent_terminated", f"Terminated agent {agent_id}")
        return True
    
    def get_agent(self, agent_id: str) -> Optional[Agent]:
        with self._lock:
            return self.agents.get(agent_id)
    
    def list_agents(self, role: str = None, status: AgentStatus = None) -> List[Agent]:
        with self._lock:
            agents = list(self.agents.values())
            if role:
                agents = [a for a in agents if a.role == role]
            if status:
                agents = [a for a in agents if a.status == status]
            return agents
    
    def assign_task(self, agent_id: str, task_spec: Dict) -> bool:
        """Assign a task directly to an agent."""
        with self._lock:
            agent = self.agents.get(agent_id)
            if not agent:
                return False
            if agent.status != AgentStatus.IDLE:
                return False
            
            agent.status = AgentStatus.BUSY
            agent.current_task = task_spec.get("task_id", uuid.uuid4().hex[:12])
            self._save_agent(agent)
        
        # Send task message
        self.send_message(
            sender_id="society_manager",
            recipient_id=agent_id,
            message_type=MessageType.TASK_REQUEST,
            content=task_spec,
        )
        return True
    
    def request_bids(self, task_spec: Dict, deadline: float = None,
                     eligible_roles: List[str] = None) -> str:
        """Request bids for a task using contract net protocol."""
        task_id = task_spec.get("task_id", uuid.uuid4().hex[:12])
        
        # Determine eligible agents
        eligible_agents = None
        if eligible_roles:
            with self._lock:
                eligible_agents = [a.id for a in self.agents.values() 
                                 if a.role in eligible_roles and a.status == AgentStatus.IDLE]
        
        tender = self.contract_net.announce_task(task_id, task_spec, deadline, eligible_agents)
        
        # Notify eligible agents
        for agent_id in tender.get("eligible_agents") or [a.id for a in self.agents.values()]:
            self.send_message(
                sender_id="contract_net",
                recipient_id=agent_id,
                message_type=MessageType.TASK_REQUEST,
                content={"task_id": task_id, "task_spec": task_spec, "deadline": tender["deadline"]},
                requires_response=True,
            )
        
        return task_id
    
    def submit_bid(self, agent_id: str, task_id: str, bid: TaskBid) -> bool:
        """Agent submits a bid."""
        with self._lock:
            agent = self.agents.get(agent_id)
            if not agent:
                return False
        
        return self.contract_net.submit_bid(task_id, bid)
    
    def award_task(self, task_id: str, selector=None) -> Optional[str]:
        """Award task to best bidder."""
        winner_id = self.contract_net.award_task(task_id, selector)
        
        if winner_id:
            tender = self.contract_net.get_tender(task_id)
            if tender:
                # Notify winner
                self.send_message(
                    sender_id="contract_net",
                    recipient_id=winner_id,
                    message_type=MessageType.AWARD,
                    content={"task_id": task_id, "task_spec": tender["task_spec"]},
                )
                
                # Notify losers
                for bidder_id in tender["bids"]:
                    if bidder_id != winner_id:
                        self.send_message(
                            sender_id="contract_net",
                            recipient_id=bidder_id,
                            message_type=MessageType.TASK_RESPONSE,
                            content={"task_id": task_id, "awarded": False},
                        )
                
                # Update winner status
                with self._lock:
                    winner = self.agents.get(winner_id)
                    if winner:
                        winner.status = AgentStatus.BUSY
                        winner.current_task = task_id
                        self._save_agent(winner)
        
        return winner_id
    
    def send_message(self, sender_id: str, recipient_id: str = None,
                     message_type: MessageType = MessageType.INFO_SHARE,
                     content: Dict = None, conversation_id: str = None,
                     requires_response: bool = False) -> AgentMessage:
        """Send a message between agents."""
        msg = AgentMessage(
            id=uuid.uuid4().hex[:12],
            sender_id=sender_id,
            recipient_id=recipient_id,
            message_type=message_type,
            content=content or {},
            conversation_id=conversation_id,
            requires_response=requires_response,
        )
        
        with self._lock:
            self.message_bus.append(msg)
            if recipient_id:
                self.message_queues[recipient_id].append(msg)
            else:
                # Broadcast - add to all agent queues
                for agent_id in self.agents:
                    if agent_id != sender_id:
                        self.message_queues[agent_id].append(msg)
        
        return msg
    
    def receive_messages(self, agent_id: str, limit: int = 50) -> List[AgentMessage]:
        """Get messages for an agent."""
        with self._lock:
            messages = self.message_queues[agent_id][:limit]
            self.message_queues[agent_id] = self.message_queues[agent_id][limit:]
            return messages
    
    def share_info(self, agent_id: str, key: str, value: Any, 
                   tags: List[str] = None, ttl: float = 3600) -> BlackboardEntry:
        """Agent shares information on blackboard."""
        return self.blackboard.write(key, value, agent_id, tags, ttl)
    
    def get_info(self, agent_id: str, key: str) -> Any:
        """Agent reads information from blackboard."""
        return self.blackboard.read_value(key)
    
    def start(self) -> None:
        """Start background society management."""
        if self._running:
            return
        self._running = True
        self._bg_thread = threading.Thread(target=self._background_loop, daemon=True)
        self._bg_thread.start()
    
    def stop(self) -> None:
        self._running = False
        if self._bg_thread:
            self._bg_thread.join(timeout=5)
    
    def _background_loop(self) -> None:
        """Background loop for society maintenance."""
        while self._running:
            try:
                self._maintain_society()
            except Exception as e:
                self.kernel._audit("society_error", str(e))
            time.sleep(30)  # Run every 30 seconds
    
    def _maintain_society(self) -> None:
        """Maintain society health."""
        # Cleanup expired tenders
        self.contract_net.cleanup_expired()
        
        # Cleanup expired blackboard entries
        self.blackboard.cleanup_expired()
        
        # Check agent heartbeats
        with self._lock:
            now = time.time()
            for agent in self.agents.values():
                if agent.status == AgentStatus.BUSY:
                    if now - agent.last_heartbeat > 300:  # 5 min timeout
                        agent.status = AgentStatus.ERROR
                        self._save_agent(agent)
                        self.kernel._audit("agent_timeout", f"Agent {agent.id} timed out")
        
        # Auto-spawn agents for pending tasks (if kernel has pending goals)
        if self.kernel:
            pending_goals = self.kernel.get_active_goals()
            for goal in pending_goals:
                if not goal.assigned_agent and goal.required_capabilities:
                    # Could spawn specialist agent
                    pass
    
    def _save_agent(self, agent: Agent) -> None:
        with self._conn() as c:
            c.execute("""
                INSERT OR REPLACE INTO agents
                (id, name, role, capabilities, status, current_task, created_at,
                 last_heartbeat, metadata, performance, memory_scope)
                VALUES (?,?,?,?,?,?,?,?,?,?,?)
            """, (
                agent.id, agent.name, agent.role, json.dumps(agent.capabilities),
                agent.status.value, agent.current_task, agent.created_at,
                agent.last_heartbeat, json.dumps(agent.metadata),
                json.dumps(agent.performance), agent.memory_scope
            ))
    
    def _load_agents(self) -> None:
        with self._conn() as c:
            rows = c.execute("SELECT * FROM agents WHERE status != 'terminated'").fetchall()
            for row in rows:
                agent = Agent(
                    id=row["id"],
                    name=row["name"],
                    role=row["role"],
                    capabilities=json.loads(row["capabilities"]),
                    status=AgentStatus(row["status"]),
                    current_task=row["current_task"],
                    created_at=row["created_at"],
                    last_heartbeat=row["last_heartbeat"],
                    metadata=json.loads(row["metadata"]),
                    performance=json.loads(row["performance"]),
                    memory_scope=row["memory_scope"],
                )
                self.agents[agent.id] = agent
    
    def get_society_status(self) -> Dict:
        with self._lock:
            by_role = defaultdict(int)
            by_status = defaultdict(int)
            for agent in self.agents.values():
                by_role[agent.role] += 1
                by_status[agent.status.value] += 1
            
            return {
                "total_agents": len(self.agents),
                "by_role": dict(by_role),
                "by_status": dict(by_status),
                "active_tenders": len(self.contract_net.active_tenders),
                "blackboard_entries": len(self.blackboard._entries),
                "message_queue_sizes": {aid: len(q) for aid, q in self.message_queues.items()},
            }
    
    def register_agent_factory(self, role: str, factory: Callable[[Dict], Agent]) -> None:
        """Register a custom agent factory."""
        self._agent_factories[role] = factory


# Module singleton
_agent_society: Optional[AgentSociety] = None


def get_agent_society(kernel=None, **kwargs) -> AgentSociety:
    global _agent_society
    if _agent_society is None and kernel:
        _agent_society = AgentSociety(kernel, **kwargs)
    return _agent_society


def set_agent_society(society: AgentSociety) -> None:
    global _agent_society
    _agent_society = society