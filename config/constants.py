# Maya 2.0 - Constants

# Agent States
STATE_IDLE = "idle"
STATE_PLANNING = "planning"
STATE_EXECUTING = "executing"
STATE_VERIFYING = "verifying"
STATE_LEARNING = "learning"
STATE_FAILED = "failed"
STATE_SUCCESS = "success"

# Task Status
TASK_PENDING = "pending"
TASK_RUNNING = "running"
TASK_DONE = "done"
TASK_FAILED = "failed"
TASK_RETRYING = "retrying"

# Memory Types
MEMORY_SHORT = "short_term"
MEMORY_LONG = "long_term"
MEMORY_EPISODIC = "episodic"
MEMORY_SEMANTIC = "semantic"
MEMORY_VECTOR = "vector"

# Tool Categories
TOOL_WEB = "web"
TOOL_FILE = "file"
TOOL_CODE = "code"
TOOL_SYSTEM = "system"
TOOL_MEDIA = "media"

# LLM Providers
PROVIDER_GROQ = "groq"
PROVIDER_GEMINI = "gemini"
PROVIDER_OPENAI = "openai"
PROVIDER_CLAUDE = "claude"
PROVIDER_DEEPSEEK = "deepseek"
PROVIDER_LOCAL = "local"

# Risk Levels
RISK_LOW = "low"
RISK_MEDIUM = "medium"
RISK_HIGH = "high"
RISK_CRITICAL = "critical"

# Retry
MAX_RETRIES = 3
RETRY_DELAY = 2

# Approval
APPROVAL_AUTO = "auto"
APPROVAL_HUMAN = "human"
APPROVAL_SKIP = "skip"
