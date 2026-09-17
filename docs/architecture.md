# Maya 2.0 ULTRA - Architecture

## Overview

Maya follows a Plan -> Execute -> Verify -> Learn workflow.

## Core Components

### 1. Planner (core/planner.py)
- Analyzes goal deeply
- Creates step-by-step execution plan
- Handles replanning on failure
- Uses past experiences for better plans

### 2. Reasoner (core/reasoner.py)
- Deep chain-of-thought reasoning
- Tool selection decisions
- Failure root cause analysis
- Provider selection

### 3. Executor (core/executor.py)
- Executes each step
- Tool calls with retry
- Context injection between steps
- Handles step dependencies

### 4. Verifier (core/verifier.py)
- Checks if goal is fully satisfied
- Quality scoring (0-10)
- Partial success detection
- Next action recommendation

### 5. Fallback Manager (core/fallback_manager.py)
- Error type classification
- Smart recovery strategies
- Tool alternatives
- Provider switching

### 6. Workflow Engine (core/workflow_engine.py)
- Orchestrates the full loop
- Max retry management
- Progress tracking

## Memory Architecture

```
ShortTermMemory  -> Current session (in-memory deque)
LongTermMemory   -> SQLite persistent storage
EpisodicMemory   -> Past task runs with outcomes
SemanticMemory   -> Facts and knowledge base
VectorMemory     -> Semantic similarity search (ChromaDB)
ContextManager   -> Current task context tracking
```

## LLM Router

Supports 6 providers with automatic fallback:
- Groq (fastest)
- Gemini (long context)
- OpenAI (most capable)
- Claude (best reasoning)
- DeepSeek (best coding)
- Local/Ollama (private)

## Tool System

Tools are registered in ToolRegistry and can be:
- Built-in (web, files, code, system)
- Plugins (loaded at runtime)
- Custom (added via maya.add_tool())

## Cloudflare Integration

- Workers: API endpoints
- D1: Persistent SQLite database
- R2: File and backup storage
- KV: Fast cache and short-term memory
