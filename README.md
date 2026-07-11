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

## Autonomous Recovery (Self-Correcting Loop)

The autonomous loop no longer retries every failure blindly. A new
recovery engine (`autonomous/recovery.py`) inspects each failure and picks a strategy:

- **RETRY** — transient errors (timeout, rate limit, connection) get exponential backoff and a fresh attempt.
- **ALTERNATE** — a failed/unavailable tool triggers a different approach (drops to an LLM step, without that tool). Repeating the same error twice auto-escalates here.
- **REPLAN** — a wrong premise (missing dependency, impossible step) re-plans the remaining goal, preserving completed work (capped to avoid loops).
- **ABORT** — hard blocks (security, workspace escape) or an exhausted attempt budget stop wasting tries immediately.

Every failure also produces a short **reflection note** fed back into the next attempt's prompt, so Maya adapts within a single run. The autonomous result now includes a `recovery_log` (every decision made) and `replans_used`. Recovery is deterministic and fully offline; an optional `llm_fn` deepens the reflection when available.

---

## Streaming Responses (Live Token Output)

Replies now stream token-by-token instead of arriving all at once.

- **Providers**: Groq and Gemini gained native `stream_chat()` (server-side streaming). Providers without it degrade gracefully — their full reply is emitted as a single chunk.
- **Router**: `LLMRouter.stream_chat()` yields chunks with the same provider-selection and health-based fallback as `chat()`; if one provider fails mid-stream it transparently falls back to the next.
- **API**: `POST /api/v1/agent/chat/stream` emits Server-Sent Events (`data: {"delta": "..."}` … `data: {"done": true}`), preserving the same history/budget handling as `/agent/chat`.
- **Frontend**: a new **Live Chat** page renders the reply as it arrives, with a typing cursor and a Stop button; it falls back to the non-streaming endpoint automatically on older backends.

---

## Persistent Task Queue (Restart-Proof Background Jobs)

Background work now survives a server restart or crash.

- **Persistence**: task status, history, and *pending work* are stored in SQLite (`storage/queue/tasks.db`, WAL mode) — the old queue was purely in-memory and lost everything on restart.
- **Job registry**: since coroutines can't be serialized, callers register named async handlers once (e.g. `agent_goal`); only the job name + JSON-safe args are persisted. On restart, unfinished jobs are re-enqueued and resumed by name (the Celery/RQ pattern). Orphans with no matching handler are marked failed, never left hanging.
- **Backward compatible**: `submit(coro_fn, …)` still works for fire-and-forget in-process tasks; `submit_job(name, …)` is the new durable path.
- **API**: `POST /api/v1/queue/submit` (durable job), `POST /api/v1/queue/cancel/{id}`, `GET /api/v1/queue/stats`, `GET /api/v1/queue/task/{id}`, plus the existing `GET /api/v1/queue/status`. Persistence is on by default; set `QUEUE_PERSIST=false` to disable.

---

## Scheduled Tasks (Cron)

Maya can now run jobs automatically on a schedule.

- **Cron engine** (`infrastructure/cron.py`): full 5-field cron parser and matcher (ranges, lists, `*/step`, `1-10/2`) plus aliases `@hourly` `@daily` `@weekly` `@monthly` `@yearly`. Stdlib-only, cron's day-of-month/day-of-week OR semantics respected.
- **Scheduler** (`infrastructure/scheduler.py`): schedules are stored in SQLite (`storage/scheduler/schedules.db`) so they survive restarts, and each firing is dispatched through the persistent task queue — so a scheduled run is itself restart-proof. A 30s ticker fires due schedules; missed slots during downtime are skipped (no catch-up burst) and `next_run` advances.
- **API**: `GET/POST /api/v1/schedules`, `DELETE /api/v1/schedules/{id}`, `POST /api/v1/schedules/{id}/enabled`. A schedule references a registered queue job (e.g. `agent_goal`). Disable the whole scheduler with `SCHEDULER_ENABLED=false`.

Example: run a daily briefing at 9am → `{"name":"briefing","cron":"0 9 * * *","job":"agent_goal","args":["Summarize my day"]}`.

---

## Multi-user Workspaces (Personal + Team Memory)

Maya now supports isolated per-user memory and shared team spaces.

- **Workspace scopes**: `default` (the legacy single-user space, unchanged), `user:<uid>` (a user's private space), and `team:<team_id>` (a shared team space). `WorkspaceContext` (`enterprise/workspace.py`) resolves and authorizes them, reusing the enterprise OrgStore for team membership — no new source of truth.
- **Isolation**: `ScopedMemory` (`enterprise/scoped_memory.py`) partitions memory by scope in SQLite. One user's search never returns another user's memory; team members share a genuinely common space. Membership is enforced on every team-workspace access.
- **Backward compatible**: single-user deployments are untouched — with no workspace specified, everything resolves to `default`, exactly as before.
- **API**: `GET /api/v1/workspaces` (list yours), `GET/POST /api/v1/workspace/memory`, `DELETE /api/v1/workspace/memory/{id}`, `GET /api/v1/workspace/stats` — all take a `workspace` parameter (`default` | `personal` | `team:<id>`).

---

## RAG Auto-Connect (Grounded Answers)

Maya now consults the knowledge base automatically before answering — no explicit tool call needed.

- **Automatic grounding** (`rag/augmenter.py`): `maya.chat()` retrieves relevant indexed context and injects it into the system prompt, instructing the model to cite sources inline with `[n]` markers. Retrieved sources are appended to the reply as a "Sources:" footer.
- **Smart gating**: trivial messages ("hi", "thanks") and empty/irrelevant retrievals are skipped, so prompts never get bloated. An optional `min_score` floor drops weak hits.
- **Safe + optional**: if the RAG index is empty or unavailable, `chat()` behaves exactly as before. Disable entirely with `RAG_AUTOCONNECT=false`.

Together with the existing `knowledge_search` tool, agents can now both search the knowledge base explicitly and have it consulted transparently on every chat turn.

---

## Inbound Webhook Triggers (External → Maya)

External services can now trigger Maya. This complements the existing outbound webhooks (Maya notifying others when tasks finish).

- **Signed triggers** (`infrastructure/webhook_triggers.py`): create a trigger with a job + goal template; Maya returns a secret (shown once). External services POST to `/api/v1/hooks/{id}` with an `X-Maya-Signature` (or GitHub-style `X-Hub-Signature-256`) HMAC-SHA256 header, verified in constant time. Unsigned triggers are supported for trusted internal use.
- **Template rendering**: the goal is built from a `{{path.to.field}}` template filled from the incoming JSON payload (supports nested paths and list indices; missing paths render empty, never crash).
- **Queued execution**: each firing enqueues the job on the persistent task queue, so a triggered run is restart-proof and shows up in `/api/v1/queue/status`.
- **API**: `GET/POST /api/v1/hooks`, `DELETE /api/v1/hooks/{id}`, `POST /api/v1/hooks/{id}/enabled`, and the public `POST /api/v1/hooks/{id}` fire endpoint.

Example (GitHub PR → review): `{"name":"pr-review","job":"agent_goal","template":"Review PR: {{pull_request.title}}"}`.

---

## Notifications (Multi-channel Alerts)

Maya can now alert you when things happen — task done, task failed, scheduled run, webhook fired.

- **Channels** (`infrastructure/notifications.py`): `in_app` (persisted, read via the API bell), `email` (SMTP — configured via `SMTP_HOST/PORT/USER/PASS/FROM`; skipped cleanly when unconfigured), and `webhook` (POST to a URL). Delivery never raises — a broken channel degrades to a recorded failure.
- **In-app center**: per-recipient notifications with read/unread state and an unread badge count, so the UI can show a notification bell.
- **Auto-notify on jobs**: every persistent-queue job now raises an in-app notification when it completes or fails, wired transparently around the registered handlers.
- **API**: `GET /api/v1/notifications` (list + unread count), `GET /api/v1/notifications/unread`, `POST /api/v1/notifications/{id}/read`, `POST /api/v1/notifications/read-all`, `POST /api/v1/notifications/send` (fan out to chosen channels).

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
