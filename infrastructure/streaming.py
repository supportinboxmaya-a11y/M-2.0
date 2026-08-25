"""
Maya 2.0 — Real-time Streaming Architecture
=============================================
First-class streaming for WebSocket and SSE with:
- Structured event types for all cognitive stages
- Token-by-token LLM output
- Tool execution events
- Agent/thought/workflow status events
- Progress updates
- Errors/retries/recovery events
- Cancellation/interruption
- Reconnect/resume support
- Persistent session state
- Concurrent tasks without breaking state
"""

import asyncio
import json
import time
import uuid
from contextlib import asynccontextmanager
from dataclasses import dataclass, field, asdict
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, AsyncGenerator
from collections import defaultdict
import weakref


class StreamEventType(Enum):
    """All possible streaming event types."""
    # Connection lifecycle
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    RECONNECTED = "reconnected"
    HEARTBEAT = "heartbeat"
    
    # Task lifecycle
    TASK_STARTED = "task_started"
    TASK_COMPLETED = "task_completed"
    TASK_FAILED = "task_failed"
    TASK_CANCELLED = "task_cancelled"
    TASK_PAUSED = "task_paused"
    TASK_RESUMED = "task_resumed"
    
    # Planning
    PLANNING_STARTED = "planning_started"
    PLAN_CREATED = "plan_created"
    PLANNING_FAILED = "planning_failed"
    
    # Execution
    STEP_STARTED = "step_started"
    STEP_COMPLETED = "step_completed"
    STEP_FAILED = "step_failed"
    STEP_RETRYING = "step_retrying"
    STEP_SKIPPED = "step_skipped"
    
    # Tool execution
    TOOL_CALL_STARTED = "tool_call_started"
    TOOL_CALL_COMPLETED = "tool_call_completed"
    TOOL_CALL_FAILED = "tool_call_failed"
    TOOL_CALL_RETRYING = "tool_call_retrying"
    
    # LLM streaming
    LLM_TOKEN = "llm_token"
    LLM_STREAM_START = "llm_stream_start"
    LLM_STREAM_END = "llm_stream_end"
    LLM_STREAM_ERROR = "llm_stream_error"
    
    # Verification
    VERIFICATION_STARTED = "verification_started"
    VERIFICATION_COMPLETED = "verification_completed"
    VERIFICATION_FAILED = "verification_failed"
    
    # Metacognitive
    CONFIDENCE_UPDATE = "confidence_update"
    SURPRISE_DETECTED = "surprise_detected"
    UNCERTAINTY_SPIKE = "uncertainty_spike"
    REPLAN_TRIGGERED = "replan_triggered"
    RECOVERY_ACTION = "recovery_action"
    
    # Agent society
    AGENT_SPAWNED = "agent_spawned"
    AGENT_TASK_ASSIGNED = "agent_task_assigned"
    AGENT_TASK_COMPLETED = "agent_task_completed"
    AGENT_COMMUNICATION = "agent_communication"
    
    # Memory
    MEMORY_CONSOLIDATED = "memory_consolidated"
    SKILL_ACQUIRED = "skill_acquired"
    EPISODE_STORED = "episode_stored"
    
    # Approval
    APPROVAL_REQUESTED = "approval_requested"
    APPROVAL_GRANTED = "approval_granted"
    APPROVAL_DENIED = "approval_denied"
    
    # Errors
    ERROR = "error"
    WARNING = "warning"
    
    # Generic
    PROGRESS = "progress"
    LOG = "log"


@dataclass
class StreamEvent:
    """Structured streaming event."""
    event_type: StreamEventType
    task_id: str
    session_id: str
    timestamp: float = field(default_factory=time.time)
    data: Dict[str, Any] = field(default_factory=dict)
    sequence: int = 0
    
    def to_json(self) -> str:
        return json.dumps({
            "type": self.event_type.value,
            "task_id": self.task_id,
            "session_id": self.session_id,
            "timestamp": self.timestamp,
            "data": self.data,
            "sequence": self.sequence
        }, separators=(',', ':'))


@dataclass
class TaskSession:
    """Persistent task session state for reconnect/resume."""
    task_id: str
    session_id: str
    goal: str
    status: str  # pending, running, paused, completed, failed, cancelled
    created_at: float
    updated_at: float
    plan: Optional[Dict] = None
    current_step: int = 0
    completed_steps: List[Dict] = field(default_factory=list)
    results: List[Dict] = field(default_factory=list)
    tools_used: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)
    metadata: Dict = field(default_factory=dict)
    # For reconnect
    last_event_sequence: int = 0
    client_connected: bool = False


class StreamManager:
    """
    Central streaming manager for WebSocket and SSE.
    Handles event broadcasting, session persistence, and reconnect/resume.
    """
    
    def __init__(self):
        self._sessions: Dict[str, TaskSession] = {}  # task_id -> TaskSession
        self._session_by_client: Dict[str, str] = {}  # client_id -> session_id
        self._websockets: Dict[str, Set[asyncio.Queue]] = defaultdict(set)  # session_id -> queues
        self._sse_queues: Dict[str, asyncio.Queue] = {}  # session_id -> queue
        self._event_handlers: Dict[StreamEventType, List[Callable]] = defaultdict(list)
        self._sequence_counters: Dict[str, int] = defaultdict(int)
        self._lock = asyncio.Lock()
        
        # Persistence
        self._storage_path = None
    
    def set_storage_path(self, path: str):
        self._storage_path = path
    
    async def create_session(self, goal: str, client_id: str = None) -> TaskSession:
        """Create a new task session."""
        task_id = uuid.uuid4().hex[:12]
        session_id = uuid.uuid4().hex[:12]
        
        session = TaskSession(
            task_id=task_id,
            session_id=session_id,
            goal=goal,
            status="pending",
            created_at=time.time(),
            updated_at=time.time()
        )
        
        async with self._lock:
            self._sessions[task_id] = session
            if client_id:
                self._session_by_client[client_id] = task_id
        
        await self._persist_session(session)
        return session
    
    async def get_session(self, task_id: str) -> Optional[TaskSession]:
        async with self._lock:
            return self._sessions.get(task_id)
    
    async def update_session(self, task_id: str, **kwargs) -> Optional[TaskSession]:
        async with self._lock:
            session = self._sessions.get(task_id)
            if not session:
                return None
            for key, value in kwargs.items():
                if hasattr(session, key):
                    setattr(session, key, value)
            session.updated_at = time.time()
            await self._persist_session(session)
            return session
    
    async def register_websocket(self, session_id: str, queue: asyncio.Queue):
        """Register a WebSocket connection for a session."""
        async with self._lock:
            self._websockets[session_id].add(queue)
            # Update session
            for session in self._sessions.values():
                if session.session_id == session_id:
                    session.client_connected = True
                    session.updated_at = time.time()
                    break
    
    async def unregister_websocket(self, session_id: str, queue: asyncio.Queue):
        """Unregister a WebSocket connection."""
        async with self._lock:
            self._websockets[session_id].discard(queue)
            # Check if any connections remain
            if not self._websockets[session_id]:
                for session in self._sessions.values():
                    if session.session_id == session_id:
                        session.client_connected = False
                        session.updated_at = time.time()
                        break
    
    async def register_sse(self, session_id: str) -> asyncio.Queue:
        """Register an SSE connection for a session."""
        queue = asyncio.Queue(maxsize=1000)
        async with self._lock:
            self._sse_queues[session_id] = queue
        return queue
    
    async def unregister_sse(self, session_id: str):
        """Unregister an SSE connection."""
        async with self._lock:
            self._sse_queues.pop(session_id, None)
    
    async def emit(self, event: StreamEvent):
        """Emit an event to all connected clients for the session."""
        session_id = event.session_id
        event.sequence = self._sequence_counters[session_id]
        self._sequence_counters[session_id] += 1
        
        # Update session
        async with self._lock:
            for session in self._sessions.values():
                if session.session_id == session_id:
                    session.last_event_sequence = event.sequence
                    break
        
        event_json = event.to_json()
        
        # Send to WebSocket clients
        websockets = self._websockets.get(session_id, set())
        for queue in websockets:
            try:
                await queue.put(event_json)
            except asyncio.QueueFull:
                pass  # Drop if queue full
        
        # Send to SSE
        sse_queue = self._sse_queues.get(session_id)
        if sse_queue:
            try:
                await sse_queue.put(event_json)
            except asyncio.QueueFull:
                pass
    
    async def emit_event(self, event_type: StreamEventType, task_id: str, session_id: str, data: Dict):
        """Convenience method to emit an event."""
        event = StreamEvent(
            event_type=event_type,
            task_id=task_id,
            session_id=session_id,
            data=data
        )
        await self.emit(event)
    
    async def emit_progress(self, task_id: str, session_id: str, progress: float, message: str = ""):
        await self.emit_event(StreamEventType.PROGRESS, task_id, session_id, {
            "progress": progress,
            "message": message
        })
    
    async def emit_llm_token(self, task_id: str, session_id: str, token: str, is_complete: bool = False):
        await self.emit_event(StreamEventType.LLM_TOKEN, task_id, session_id, {
            "token": token,
            "is_complete": is_complete
        })
    
    async def emit_tool_call(self, task_id: str, session_id: str, tool_name: str, 
                             input_data: Dict, output: Any = None, success: bool = True, error: str = None):
        event_type = StreamEventType.TOOL_CALL_COMPLETED if success else StreamEventType.TOOL_CALL_FAILED
        await self.emit_event(event_type, task_id, session_id, {
            "tool": tool_name,
            "input": input_data,
            "output": output,
            "error": error
        })
    
    async def emit_step(self, task_id: str, session_id: str, step: Dict, status: str):
        event_map = {
            "started": StreamEventType.STEP_STARTED,
            "completed": StreamEventType.STEP_COMPLETED,
            "failed": StreamEventType.STEP_FAILED,
            "retrying": StreamEventType.STEP_RETRYING,
            "skipped": StreamEventType.STEP_SKIPPED,
        }
        await self.emit_event(event_map.get(status, StreamEventType.STEP_STARTED), task_id, session_id, step)
    
    async def _persist_session(self, session: TaskSession):
        """Persist session to storage for reconnect/resume."""
        if not self._storage_path:
            return
        try:
            import os
            os.makedirs(self._storage_path, exist_ok=True)
            file_path = os.path.join(self._storage_path, f"session_{session.task_id}.json")
            # Use thread pool for file I/O
            loop = asyncio.get_event_loop()
            await loop.run_in_executor(None, self._write_session_file, file_path, session)
        except Exception:
            pass  # Don't let persistence failures break streaming
    
    def _write_session_file(self, file_path: str, session: TaskSession):
        data = {
            "task_id": session.task_id,
            "session_id": session.session_id,
            "goal": session.goal,
            "status": session.status,
            "created_at": session.created_at,
            "updated_at": session.updated_at,
            "plan": session.plan,
            "current_step": session.current_step,
            "completed_steps": session.completed_steps,
            "results": session.results,
            "tools_used": session.tools_used,
            "errors": session.errors,
            "metadata": session.metadata,
            "last_event_sequence": session.last_event_sequence,
        }
        with open(file_path, 'w') as f:
            json.dump(data, f)
    
    async def load_session(self, task_id: str) -> Optional[TaskSession]:
        """Load session from storage for reconnect."""
        if not self._storage_path:
            return None
        try:
            file_path = os.path.join(self._storage_path, f"session_{task_id}.json")
            if not os.path.exists(file_path):
                return None
            
            loop = asyncio.get_event_loop()
            data = await loop.run_in_executor(None, self._read_session_file, file_path)
            
            if not data:
                return None
            
            session = TaskSession(**data)
            async with self._lock:
                self._sessions[task_id] = session
            return session
        except Exception:
            return None
    
    def _read_session_file(self, file_path: str) -> Optional[Dict]:
        try:
            with open(file_path, 'r') as f:
                return json.load(f)
        except Exception:
            return None
    
    async def resume_session(self, task_id: str, client_id: str = None) -> Optional[TaskSession]:
        """Resume a session after reconnect."""
        # Try to load from memory first
        session = await self.get_session(task_id)
        if not session:
            # Try to load from disk
            session = await self.load_session(task_id)
        
        if session:
            session.client_connected = True
            session.updated_at = time.time()
            if client_id:
                self._session_by_client[client_id] = task_id
            await self._persist_session(session)
            # Emit reconnect event
            await self.emit_event(StreamEventType.RECONNECTED, task_id, session.session_id, {
                "current_step": session.current_step,
                "status": session.status,
                "last_sequence": session.last_event_sequence
            })
        return session
    
    async def cancel_task(self, task_id: str) -> bool:
        """Cancel a running task."""
        session = await self.get_session(task_id)
        if not session:
            return False
        if session.status in ("completed", "failed", "cancelled"):
            return False
        
        session.status = "cancelled"
        session.updated_at = time.time()
        await self._persist_session(session)
        await self.emit_event(StreamEventType.TASK_CANCELLED, task_id, session.session_id, {
            "reason": "User cancelled"
        })
        return True
    
    async def pause_task(self, task_id: str) -> bool:
        session = await self.get_session(task_id)
        if not session or session.status != "running":
            return False
        session.status = "paused"
        session.updated_at = time.time()
        await self._persist_session(session)
        await self.emit_event(StreamEventType.TASK_PAUSED, task_id, session.session_id, {})
        return True
    
    async def resume_task(self, task_id: str) -> bool:
        session = await self.get_session(task_id)
        if not session or session.status != "paused":
            return False
        session.status = "running"
        session.updated_at = time.time()
        await self._persist_session(session)
        await self.emit_event(StreamEventType.TASK_RESUMED, task_id, session.session_id, {})
        return True
     
    def get_active_sessions(self) -> List[TaskSession]:
        return list(self._sessions.values())
    
    def get_session_for_client(self, client_id: str) -> Optional[TaskSession]:
        task_id = self._session_by_client.get(client_id)
        if task_id:
            return self._sessions.get(task_id)
        return None

    async def get_events(self, task_id: str, session_id: str, 
                         last_event_id: Optional[str] = None) -> List[StreamEvent]:
        """Get events for a session, optionally after a specific event ID."""
        # This is a simplified implementation - in production, events would be
        # stored in a persistent event log. For now, we return events from
        # the session's event history if available.
        session = await self.get_session(task_id)
        if not session or session.session_id != session_id:
            return []
        
        # Load events from session file if it exists
        events = []
        if self._storage_path:
            import os
            events_file = os.path.join(self._storage_path, f"events_{task_id}.json")
            if os.path.exists(events_file):
                try:
                    with open(events_file, 'r') as f:
                        events_data = json.load(f)
                        for ev_data in events_data:
                            events.append(StreamEvent(
                                event_type=StreamEventType(ev_data["type"]),
                                task_id=ev_data["task_id"],
                                session_id=ev_data["session_id"],
                                timestamp=ev_data["timestamp"],
                                data=ev_data["data"],
                                sequence=ev_data["sequence"],
                            ))
                except Exception:
                    pass
        
        # Filter by last_event_id if provided
        if last_event_id:
            events = [e for e in events if str(e.sequence) > last_event_id]
        
        return events

# Global stream manager instance
_stream_manager: Optional[StreamManager] = None


def get_stream_manager() -> StreamManager:
    global _stream_manager
    if _stream_manager is None:
        _stream_manager = StreamManager()
    return _stream_manager


def set_stream_manager(manager: StreamManager):
    global _stream_manager
    _stream_manager = manager


# SSE Generator helper
async def sse_generator(queue: asyncio.Queue, session_id: str) -> AsyncGenerator[str, None]:
    """Generate SSE events from queue."""
    try:
        # Send initial connection event
        yield f"data: {json.dumps({'type': 'connected', 'session_id': session_id})}\n\n"
        
        while True:
            try:
                event_json = await asyncio.wait_for(queue.get(), timeout=30.0)
                yield f"data: {event_json}\n\n"
            except asyncio.TimeoutError:
                # Send heartbeat
                yield f"data: {json.dumps({'type': 'heartbeat', 'timestamp': time.time()})}\n\n"
    except asyncio.CancelledError:
        pass
    except Exception:
        pass


# WebSocket handler helper
async def websocket_handler(ws, session_id: str, stream_manager: StreamManager):
    """Handle WebSocket connection for a session."""
    queue = asyncio.Queue(maxsize=1000)
    await stream_manager.register_websocket(session_id, queue)
    
    try:
        # Send connection confirmation
        await ws.send_json({"type": "connected", "session_id": session_id})
        
        # Send missed events if reconnecting
        session = None
        for s in stream_manager._sessions.values():
            if s.session_id == session_id:
                session = s
                break
        
        if session and session.last_event_sequence > 0:
            await ws.send_json({
                "type": "reconnect",
                "last_sequence": session.last_event_sequence,
                "status": session.status,
                "current_step": session.current_step
            })
        
        # Handle incoming messages and outgoing events
        send_task = asyncio.create_task(_websocket_sender(ws, queue))
        receive_task = asyncio.create_task(_websocket_receiver(ws, session_id, stream_manager))
        
        done, pending = await asyncio.wait(
            [send_task, receive_task],
            return_when=asyncio.FIRST_COMPLETED
        )
        
        for task in pending:
            task.cancel()
            try:
                await task
            except asyncio.CancelledError:
                pass
                
    except Exception:
        pass
    finally:
        await stream_manager.unregister_websocket(session_id, queue)


async def _websocket_sender(ws, queue: asyncio.Queue):
    """Send events from queue to WebSocket."""
    try:
        while True:
            event_json = await queue.get()
            await ws.send_text(event_json)
    except asyncio.CancelledError:
        pass
    except Exception:
        pass


async def _websocket_receiver(ws, session_id: str, stream_manager: StreamManager):
    """Handle incoming WebSocket messages."""
    try:
        async for message in ws.iter_text():
            try:
                data = json.loads(message)
                msg_type = data.get("type")
                
                if msg_type == "ping":
                    await ws.send_json({"type": "pong"})
                elif msg_type == "cancel":
                    task_id = data.get("task_id")
                    if task_id:
                        await stream_manager.cancel_task(task_id)
                elif msg_type == "pause":
                    task_id = data.get("task_id")
                    if task_id:
                        await stream_manager.pause_task(task_id)
                elif msg_type == "resume":
                    task_id = data.get("task_id")
                    if task_id:
                        await stream_manager.resume_task(task_id)
                elif msg_type == "get_status":
                    task_id = data.get("task_id")
                    if task_id:
                        session = await stream_manager.get_session(task_id)
                        if session:
                            await ws.send_json({"type": "status", "data": {
                                "task_id": session.task_id,
                                "status": session.status,
                                "current_step": session.current_step,
                                "goal": session.goal
                            }})
            except Exception:
                pass
    except asyncio.CancelledError:
        pass
    except Exception:
        pass


# Event emission helpers for integration with Maya core
class StreamEmitter:
    """Helper to emit events from Maya core components."""
    
    def __init__(self, stream_manager: StreamManager, task_id: str, session_id: str):
        self.stream_manager = stream_manager
        self.task_id = task_id
        self.session_id = session_id
    
    async def planning_started(self):
        await self.stream_manager.emit_event(
            StreamEventType.PLANNING_STARTED, self.task_id, self.session_id, {}
        )
    
    async def plan_created(self, plan: Dict):
        await self.stream_manager.emit_event(
            StreamEventType.PLAN_CREATED, self.task_id, self.session_id, {"plan": plan}
        )
    
    async def step_started(self, step: Dict):
        await self.stream_manager.emit_step(self.task_id, self.session_id, step, "started")
    
    async def step_completed(self, step: Dict, result: Dict):
        await self.stream_manager.emit_step(self.task_id, self.session_id, {**step, "result": result}, "completed")
    
    async def step_failed(self, step: Dict, error: str):
        await self.stream_manager.emit_step(self.task_id, self.session_id, {**step, "error": error}, "failed")
    
    async def step_retrying(self, step: Dict, attempt: int):
        await self.stream_manager.emit_step(self.task_id, self.session_id, {**step, "attempt": attempt}, "retrying")
    
    async def tool_started(self, tool_name: str, input_data: Dict):
        await self.stream_manager.emit_event(
            StreamEventType.TOOL_CALL_STARTED, self.task_id, self.session_id,
            {"tool": tool_name, "input": input_data}
        )
    
    async def tool_completed(self, tool_name: str, input_data: Dict, output: Any):
        await self.stream_manager.emit_tool_call(
            self.task_id, self.session_id, tool_name, input_data, output, True
        )
    
    async def tool_failed(self, tool_name: str, input_data: Dict, error: str):
        await self.stream_manager.emit_tool_call(
            self.task_id, self.session_id, tool_name, input_data, None, False, error
        )
    
    async def llm_token(self, token: str, is_complete: bool = False):
        await self.stream_manager.emit_llm_token(self.task_id, self.session_id, token, is_complete)
    
    async def llm_stream_start(self):
        await self.stream_manager.emit_event(
            StreamEventType.LLM_STREAM_START, self.task_id, self.session_id, {}
        )
    
    async def llm_stream_end(self):
        await self.stream_manager.emit_event(
            StreamEventType.LLM_STREAM_END, self.task_id, self.session_id, {}
        )
    
    async def verification_started(self):
        await self.stream_manager.emit_event(
            StreamEventType.VERIFICATION_STARTED, self.task_id, self.session_id, {}
        )
    
    async def verification_completed(self, verdict: Dict):
        await self.stream_manager.emit_event(
            StreamEventType.VERIFICATION_COMPLETED, self.task_id, self.session_id, verdict
        )
    
    async def confidence_update(self, confidence: float, factors: Dict):
        await self.stream_manager.emit_event(
            StreamEventType.CONFIDENCE_UPDATE, self.task_id, self.session_id,
            {"confidence": confidence, "factors": factors}
        )
    
    async def surprise_detected(self, magnitude: float, expected: Any, actual: Any):
        await self.stream_manager.emit_event(
            StreamEventType.SURPRISE_DETECTED, self.task_id, self.session_id,
            {"magnitude": magnitude, "expected": str(expected)[:200], "actual": str(actual)[:200]}
        )
    
    async def replan_triggered(self, reason: str, from_step: int):
        await self.stream_manager.emit_event(
            StreamEventType.REPLAN_TRIGGERED, self.task_id, self.session_id,
            {"reason": reason, "from_step": from_step}
        )
    
    async def recovery_action(self, action: str, details: Dict):
        await self.stream_manager.emit_event(
            StreamEventType.RECOVERY_ACTION, self.task_id, self.session_id,
            {"action": action, "details": details}
        )
    
    async def approval_requested(self, action: str, reason: str, risk_level: str):
        await self.stream_manager.emit_event(
            StreamEventType.APPROVAL_REQUESTED, self.task_id, self.session_id,
            {"action": action, "reason": reason, "risk_level": risk_level}
        )
    
    async def approval_result(self, granted: bool):
        event_type = StreamEventType.APPROVAL_GRANTED if granted else StreamEventType.APPROVAL_DENIED
        await self.stream_manager.emit_event(
            event_type, self.task_id, self.session_id, {"granted": granted}
        )
    
    async def skill_acquired(self, skill_name: str, capability_id: str):
        await self.stream_manager.emit_event(
            StreamEventType.SKILL_ACQUIRED, self.task_id, self.session_id,
            {"skill": skill_name, "capability_id": capability_id}
        )
    
    async def memory_consolidated(self, count: int, summary: str):
        await self.stream_manager.emit_event(
            StreamEventType.MEMORY_CONSOLIDATED, self.task_id, self.session_id,
            {"count": count, "summary": summary}
        )
    
    async def task_completed(self, result: str, quality: float):
        await self.stream_manager.emit_event(
            StreamEventType.TASK_COMPLETED, self.task_id, self.session_id,
            {"result": result, "quality": quality}
        )
    
    async def task_failed(self, error: str):
        await self.stream_manager.emit_event(
            StreamEventType.TASK_FAILED, self.task_id, self.session_id,
            {"error": error}
        )
    
    async def progress(self, progress: float, message: str = ""):
        await self.stream_manager.emit_progress(self.task_id, self.session_id, progress, message)
    
    async def log(self, level: str, message: str):
        await self.stream_manager.emit_event(
            StreamEventType.LOG, self.task_id, self.session_id,
            {"level": level, "message": message}
        )