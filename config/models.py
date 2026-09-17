from dataclasses import dataclass, field
from typing import List, Optional, Dict, Any

@dataclass
class TaskModel:
    id: str
    goal: str
    steps: List[str] = field(default_factory=list)
    status: str = "pending"
    result: Optional[str] = None
    error: Optional[str] = None
    retries: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class StepModel:
    id: str
    task_id: str
    description: str
    tool: Optional[str] = None
    tool_input: Optional[Dict] = None
    output: Optional[str] = None
    status: str = "pending"
    error: Optional[str] = None

@dataclass
class MemoryModel:
    id: str
    content: str
    memory_type: str
    embedding: Optional[List[float]] = None
    metadata: Dict[str, Any] = field(default_factory=dict)
    timestamp: Optional[str] = None

@dataclass
class ToolResult:
    success: bool
    output: Any
    error: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

@dataclass
class PlanModel:
    goal: str
    steps: List[Dict[str, Any]] = field(default_factory=list)
    reasoning: Optional[str] = None
    estimated_complexity: str = "medium"

@dataclass
class LLMResponse:
    content: str
    model: str
    provider: str
    tokens_used: int = 0
    success: bool = True
    error: Optional[str] = None
