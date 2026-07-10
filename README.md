# Maya 2.0 ULTRA - Autonomous AI Agent

Maya is an autonomous, modular AI agent that understands goals, plans tasks, executes them using tools, verifies results, recovers from failures, and continuously improves over time.

---

## Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/supportinboxmaya-a11y/M-2.0.git
cd M-2.0
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```

### 3. Set up API keys
Edit the `.env` file and add your keys.

### 4. Run Maya
```bash
python main.py
```

---

## API Keys Setup

Edit `.env` file:

```env
# Required (at least one)
GROQ_KEY=your_groq_key          # Free at console.groq.com
GEMINI_KEY=your_gemini_key      # Free at aistudio.google.com

# Optional
OPENAI_KEY=your_openai_key
ANTHROPIC_KEY=your_anthropic_key
DEEPSEEK_KEY=your_deepseek_key

# For web search
GOOGLE_API_KEY=your_google_key
GOOGLE_CSE_ID=your_cse_id
```

Minimum requirement: At least one of `GROQ_KEY` or `GEMINI_KEY`

---

## Usage

```
You: run Search the web for latest AI news and summarize
You: run Write a Python script to sort a list and save it to file
You: run Find top 5 Python libraries for data science
You: chat What can you do?
You: quit
```

---

## Knowledge Base (RAG)

Maya includes an enterprise RAG layer (`rag/` package):

- Hybrid retrieval: SQLite FTS5 BM25 keyword search + vector search, fused with Reciprocal Rank Fusion
- Vector engine: ChromaDB (persistent) when installed, pure-Python TF-IDF fallback otherwise — works with zero extra dependencies
- Ingestion: PDF, Markdown, code, and plain text with type-aware chunking
- Dedup + versioning: identical content is never indexed twice; re-ingesting a source bumps its version
- Source attribution: every answer context carries numbered [n] citations with document, section, and character offsets

API endpoints: `POST /api/v1/rag/ingest`, `GET /api/v1/rag/search`, `GET /api/v1/rag/context`, `GET /api/v1/rag/documents`, `DELETE /api/v1/rag/documents/{id}`, `GET /api/v1/rag/stats`

Agent tools: `knowledge_search`, `knowledge_ingest` (category: memory)

```python
from rag import RAGRetriever
rag = RAGRetriever.shared()
rag.ingest_file("workspace/guide.pdf")
ctx = rag.get_context("how do I configure providers?")
```

---

## Multimodal (Vision, OCR, TTS)

- **Vision** (`tools/media/vision_tool.py`): `/api/v1/vision/analyze` now sends the actual image to a multimodal provider — Gemini → OpenAI → Claude fallback. Accepts base64, data URLs, or workspace paths.
- **OCR**: `/api/v1/vision/ocr` — local pytesseract when installed, vision LLM otherwise.
- **Text-to-Speech** (`tools/media/tts_tool.py`): `/api/v1/voice/speak` — OpenAI tts-1 → Groq playai-tts; audio saved under `workspace/audio/` and returned as base64.
- **Image generation**: generated PNGs are now saved to `workspace/images/` and the path is returned.

Agent tools: `vision_analyze`, `ocr_image`, `text_to_speech` (category: media)

---

## Vector Memory (Persistent + Synced)

- **Persistent vectors**: ChromaDB now uses `PersistentClient` under `storage/vectors/` — previously the in-memory client silently wiped all vector memory on every restart.
- **Semantic fallback**: without chromadb installed, a pure-Python TF-IDF cosine engine (rebuilt from long-term memory) replaces the old substring match.
- **Full sync**: delete, update, compress, and TTL cleanup now keep vectors in step with long-term memory — deleted/expired memories can no longer surface as "ghost" vector search results, and edited memories are re-embedded.
- `MemoryManager.cleanup()` prunes orphaned vectors; `/api/v1/memory/cleanup` routes through it. `get_stats()` reports `vector_engine` and `vector_count`.

---

## Developer Tools (Git + GraphQL)

- **Local Git** (`tools/code/git_tool.py`): agents can `git_init`, `git_status`, `git_log`, `git_diff`, `git_add`, `git_commit`, `git_branch`, `git_checkout`, and `git_merge` inside workspace repositories. Argument-list execution (no shell), workspace-confined paths, option-injection blocked, merge conflicts auto-abort safely. Local-only — no push/pull, so no credentials involved.
- **GraphQL** (`tools/web/graphql_tool.py`): `graphql_query` tool queries any GraphQL endpoint with variables and headers, returning data or GraphQL errors in LLM-friendly form.

---

## Sandbox Hardening

- **No more secret leaks**: executed code used to inherit the full parent environment — one `os.environ` read exposed every API key. Children now get a scrubbed env (PATH/HOME/LANG only), and Python runs in isolated mode (`-I`).
- **Kernel resource limits** on every code/shell run: memory (default 512MB), CPU seconds, process count (fork-bomb proof), and max file size (50MB) — a runaway snippet can no longer take the server down. Configurable via `SANDBOX_MEMORY_MB`, `SANDBOX_MAX_PROCS`, `SANDBOX_FSIZE_MB`.
- **Path boundary fix**: `Sandbox.safe_path` used a raw `startswith()`, so a sibling directory like `workspace_evil` passed the check for `workspace` — now boundary-aware.

---

## How Maya Works

```
User Goal
    |
Planner  --> Creates step-by-step plan
    |
Executor --> Runs each step (tools or LLM)
    |
Verifier --> Checks if goal is achieved
    |
Learner  --> Extracts lessons for next time
    |
If failed --> Fallback Manager --> Replan & Retry
```

---

## Folder Structure

```
M-2.0/
|-- main.py                  # Entry point
|-- .env                     # API keys (never commit!)
|-- requirements.txt         # Dependencies
|-- backup_restore.py        # Backup system
|
|-- core/
|   |-- maya.py              # Main agent brain
|   |-- planner.py           # Goal to step-by-step plan
|   |-- reasoner.py          # Deep thinking and decisions
|   |-- executor.py          # Execute steps with tools
|   |-- verifier.py          # Check if goal is achieved
|   |-- workflow_engine.py   # Plan-Execute-Verify-Learn loop
|   |-- fallback_manager.py  # Failure recovery
|   `-- task_manager.py      # Task lifecycle
|
|-- llm/
|   |-- router.py            # Smart LLM routing
|   |-- prompt_builder.py    # Prompt templates
|   `-- providers/           # Groq, Gemini, OpenAI, Claude, DeepSeek
|
|-- memory/
|   |-- memory_manager.py    # Unified memory interface
|   |-- short_term.py        # Current session memory
|   |-- long_term.py         # SQLite persistent memory
|   |-- episodic_memory.py   # Past task episodes
|   |-- semantic_memory.py   # Facts and knowledge
|   |-- vector_memory.py     # Semantic search (ChromaDB)
|   `-- context_manager.py   # Context tracking
|
|-- tools/
|   |-- registry.py          # Tool management
|   |-- web/                 # Web search and scraping
|   |-- files/               # File read/write
|   |-- code/                # Python code execution
|   `-- system/              # Shell and terminal
|
|-- learning/
|   |-- improvement_engine.py  # Learn from every task
|   `-- experience_store.py    # Store lessons
|
|-- security/
|   |-- risk_checker.py      # Risk assessment
|   |-- permissions.py       # Tool permissions
|   `-- sandbox.py           # File system sandbox
|
|-- human/
|   |-- approval.py          # Human approval for risky actions
|   |-- feedback.py          # Collect user feedback
|   `-- intervention.py      # Manual intervention
|
`-- storage/                 # Auto-created at runtime
    |-- memory/              # Database files
    |-- logs/                # Log files
    `-- backups/             # Code backups
```

---

## Available Tools

| Tool | Description |
|------|-------------|
| web_search | Search the internet |
| web_scrape | Read any webpage |
| read_file | Read files from disk |
| write_file | Write files to disk |
| list_files | List directory contents |
| run_code | Execute Python code |
| run_shell | Run shell commands |
| run_terminal | Execute terminal commands |
| list_processes | List running processes |

---

## Supported LLM Providers

| Provider | Models | Speed | Best For |
|----------|--------|-------|----------|
| Groq | LLaMA 3, Mixtral | Fastest | General tasks |
| Gemini | 1.5 Flash, Pro | Fast | Research, long context |
| OpenAI | GPT-4o, GPT-4 | Smart | Complex reasoning |
| Claude | Haiku, Sonnet | Best | Writing, analysis |
| DeepSeek | Chat, Coder | Best | Coding, math |
| Local | Ollama | Private | Offline use |

---

## Backup and Restore

```bash
# Backup before any update
python backup_restore.py backup

# List all backups
python backup_restore.py list

# Restore last backup
python backup_restore.py restore

# Restore specific backup
python backup_restore.py restore 2
```

---

## Adding New Tools

```python
# In tools/tool_manager.py
from tools.my_tool import MyTool

my_tool = MyTool()
self.registry.register(
    name="my_tool",
    func=my_tool.run,
    description="What this tool does",
    category="custom"
)
```

---

## Safety Features

- Risk Checker: Blocks dangerous commands automatically
- Sandbox: File operations limited to workspace/
- Human Approval: Asks before high-risk actions
- Intervention: User can pause/stop at any time

---

## Troubleshooting

**No provider available error:**
- Make sure at least one API key is set in `.env`
- Get a free Groq key at console.groq.com

**Tool not found error:**
- Check tools/tool_manager.py to see registered tools
- Make sure required packages are installed

**Memory/DB error:**
- Delete the storage/ folder and restart
- Maya will recreate it automatically

**Import error:**
- Run `pip install -r requirements.txt` again
- Make sure you are in the M-2.0/ directory

---

## License

MIT License - Free to use, modify, and distribute.

---

Built with love - Maya 2.0 ULTRA
