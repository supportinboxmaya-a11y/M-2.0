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

Edit `.env` file (see `.env.example` for the full list):

```env
# Required (at least one)
NVIDIA_NIM_KEY=nvapi-...        # Primary — free at build.nvidia.com (phone verify)
GROQ_KEY=your_groq_key          # Free at console.groq.com
GEMINI_KEY=your_gemini_key      # Free at aistudio.google.com

# Optional but recommended (fallbacks)
OPENROUTER_KEY=your_openrouter_key  # Free one-key access to 35+ models
CEREBRAS_KEY=your_cerebras_key      # Fastest LLM inference
OPENAI_KEY=your_openai_key
ANTHROPIC_KEY=your_anthropic_key
DEEPSEEK_KEY=your_deepseek_key

# Web search (optional — falls back to DuckDuckGo)
GOOGLE_API_KEY=your_google_key
GOOGLE_CSE_ID=your_cse_id

# Communication (optional)
SMTP_HOST=smtp.gmail.com
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

Minimum requirement: At least one LLM provider key from the table below.

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

## Prompt Library (Reusable Templates)

Save common prompts once and reuse them with variables.

- **Templates with variables** (`infrastructure/prompt_library.py`): a prompt body uses `{{variable}}` placeholders that are auto-derived on save. Variables can carry a description and a default (defaulted variables are optional; the rest are required).
- **Organization**: categories, tags, and search over name/body/description; a category breakdown for the sidebar. Popular prompts surface first via a usage counter.
- **Versioning**: editing a prompt's body archives the previous version and re-derives its variables — full history is retrievable.
- **Rendering**: `render(id, values)` fills the template; missing required variables raise, optional ones fall back to defaults. The API can optionally run the rendered prompt straight through Maya.
- **API**: `GET/POST /api/v1/prompts`, `GET/PUT/DELETE /api/v1/prompts/{id}`, `GET /api/v1/prompts/{id}/history`, `POST /api/v1/prompts/{id}/render`.

---

## Plugin System (Extensible Tools)

Third parties can add their own tools to Maya — and now those tools can be cleanly retracted.

- **Real tool retraction**: `ToolRegistry` gained `unregister()`, so disabling or uninstalling a plugin actually removes its tools from the registry (they stop being callable immediately). Previously a "disabled" plugin's tools stayed live until the next restart.
- **Tool tracking**: the plugin loader records exactly which tools each plugin registers, so disable/re-enable/uninstall operate precisely on that plugin's tools.
- **Install from code**: `install_from_code(name, code)` validates the source parses and defines `register_tools(registry)`, writes it to the plugins dir, and loads it — giving a real install path (the old `install()` had nothing to install from). Exposed at `POST /api/v1/plugins/install-code`.
- **API**: existing `GET /api/v1/plugins`, `PUT /api/v1/plugins/{id}` (enable/disable), `DELETE /api/v1/plugins/{id}`, plus new `POST /api/v1/plugins/install-code` and `GET /api/v1/plugins/{id}/tools`.

Plugins define `DESCRIPTION`, `VERSION`, `TOOLS`, and a `register_tools(registry)` function (see `skills/plugin_loader.py` PluginTemplate).

---

## Workflow Builder (Declarative Multi-step Automation)

Build multi-step workflows as data — no code required — with conditions and parallel steps.

- **Declarative workflows** (`workflows/builder.py`): a workflow is a list of steps, each with an `action` (`prompt` → run text through Maya, or `tool` → call a tool), an `input`, `depends_on` dependencies, and an optional `condition`. Definitions are stored in SQLite and validated on save (unique ids, no missing/cyclic dependencies, known actions/ops).
- **Data flow**: each step's output is captured and available to later steps via `{{step_id.output}}` templating; workflow inputs are available as `{{input.field}}`.
- **Conditional branching**: a step's `condition` (`contains`, `equals`, `not_equals`, `not_empty`, `gt`, `lt`) is evaluated against prior outputs — false skips the step (and its dependents), enabling if/then logic without code.
- **Parallel execution**: independent steps at the same dependency level run concurrently, then join.
- **API**: `GET/POST /api/v1/workflows/defs`, `GET/PUT/DELETE /api/v1/workflows/defs/{id}`, `POST /api/v1/workflows/defs/{id}/run`.

Example: step 1 classifies a ticket, step 2 (condition: classification contains "urgent") escalates, step 3 drafts a reply — all defined as JSON.

---

## Deployment Ready (Health, Probes & Container)

Maya is now production-deployable behind a load balancer or orchestrator.

- **Health probes** (`infrastructure/health.py`): `GET /health/live` (cheap liveness — never touches dependencies, used to decide restarts) and `GET /health/ready` (deep readiness — checks storage is writable, the SQLite layer works, and at least one LLM provider is configured; returns 503 when not ready so traffic is held). `GET /health/system` reports uptime, disk, memory (via psutil if present), and platform for dashboards.
- **Hardened Dockerfile**: cached dependency layer, non-root user (uid 10001), `EXPOSE`, a container `HEALTHCHECK` hitting `/health/live`, and a production `uvicorn` command honoring `$PORT` and `$WEB_CONCURRENCY` workers.
- **`.dockerignore`**: keeps `storage/`, `.env`, `tests/`, caches, and `node_modules/` out of the image — smaller, faster, safer builds.
- The original `/health` endpoint is unchanged for backward compatibility.

---

## Mobile Offline Sync

The mobile/PWA client now works offline — actions taken while disconnected are queued and replayed when connectivity returns.

- **Idempotent replay** (`infrastructure/sync_engine.py`): each queued action carries a client-generated `op_id`; the server records processed op_ids so a flaky connection re-sending a batch never double-applies. Applied/failed/rejected op statuses are stored (in SQLite) so the client can reconcile exactly what landed.
- **Decoupled handlers**: action types (`add_memory`, `create_prompt`, `enqueue_goal`) are registered handlers, so the engine stays independent of the rest of the app; unknown types are rejected, not silently dropped, and a failing handler is isolated (other actions in the batch still apply).
- **Frontend queue** (`src/lib/offlineSync.ts`): `enqueue(type, payload)` stores an action locally; `startAutoSync()` (wired into `main.tsx`) flushes on load, on the browser `online` event, and on an interval — removing applied/skipped/rejected ops and retrying only transient failures. The existing PWA service worker already provides offline caching.
- **API**: `POST /api/v1/sync/push` (replay a batch), `GET /api/v1/sync/types`, `GET /api/v1/sync/status/{op_id}`, `GET /api/v1/sync/recent`.

---

## Live Translation

Real-time translation between 16 languages, powered by Maya's LLM router.

- **LLM-backed translation** (`tools/media/translator.py`): handles context, idioms, and Bengali/English code-mixing far better than a phrase table, reusing the router's provider fallback — no new API to configure.
- **Script-based detection**: a cheap Unicode-range heuristic auto-detects the source language (Bengali, Devanagari, Arabic, CJK, Hangul, Cyrillic, Tamil, Telugu, Gurmukhi, …) and short-circuits "already in target language" cases so no LLM call is wasted.
- **TTS pairing**: with `speak: true`, the translation is spoken via the existing TTS tool when available.
- **Frontend**: a **Translate** page with source/target pickers, auto-detect, direction swap, and copy — added to the sidebar (English "Translate" / Bengali "অনুবাদ").
- **API**: `GET /api/v1/translate/languages`, `POST /api/v1/translate` (`{text, target, source?, speak?}`), `POST /api/v1/translate/detect`.

---

## Communication Tools

Maya can send messages through multiple channels.

### Email (SMTP)
```bash
# Configure in .env:
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
SMTP_FROM=your_email@gmail.com
```
Tool: `email(to, subject, body)` — sends an email. Use `action=test` to verify config.

### Outbound Webhooks (Slack / Discord)
```bash
# Configure in .env:
WEBHOOK_SLACK_URL=https://hooks.slack.com/services/xxx/yyy/zzz
WEBHOOK_DISCORD_URL=https://discord.com/api/webhooks/xxx/yyy
```
Tool: `webhook_send(channel="slack", message, title)` — posts to Slack/Discord.

### Push Notifications
Phone push via FCM (Firebase). Configure `FCM_CREDENTIALS_PATH`.
The `infrastructure/notifications.py` `Notify` class also supports in-app storage
and email delivery — never raises on a broken channel.

### Inbound Webhooks
External services can trigger Maya via `POST /api/v1/hooks/{id}` with
HMAC-signed payloads. Create a trigger, get a one-time secret, then POST
JSON to the hook URL. See `infrastructure/webhook_triggers.py`.

---

## API Key Provisioner

Maya can autonomously sign up for LLM API keys and keep them in sync with
the M1 keystore.

- **`search_free_apis(provider_filter)`** — scans web + provider pages +
  Hacker News + r/LocalLLaMA for new free/cheap APIs. Propose-only, pushes
  results to your phone.
- **`provision_api_key(provider, email, name)`** — full automated signup:
  1. Navigates to provider page, fills form
  2. Shows exact form contents in a **critical-risk approval gate** (gates in all modes)
  3. On approve: submits form
  4. If CAPTCHA/OTP detected: notifies phone, pauses for manual handling
  5. Extracts the API key, validates with a test call
  6. Stores hashed via `APIKeyManager` + writes to `.env` silently +
     syncs to M1 keystore + M1's `.env`

Supported providers: groq, gemini, openrouter, nvidia_nim, together, cerebras, mistral.

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
|-- main.py                  # CLI entry point
|-- api.py                   # FastAPI server entry point
|-- .env                     # API keys (never commit!)
|-- requirements.txt         # Dependencies
|
|-- core/                    # Core agent logic
|   |-- maya.py              # Main agent class
|   |-- planner.py           # Goal to step-by-step plan
|   |-- reasoner.py          # Deep thinking and decisions
|   |-- executor.py          # Execute steps with tools
|   |-- verifier.py          # Check if goal is achieved
|   |-- workflow_engine.py   # Plan-Execute-Verify-Learn loop
|   |-- fallback_manager.py  # Failure recovery
|   `-- task_manager.py      # Task lifecycle
|
|-- brain/                   # Phase 3 — Planning intelligence
|   |-- brain_engine.py      # Goal analysis + graph building + confidence
|   |-- goal_analyzer.py     # Decompose goals into steps
|   |-- task_graph.py        # DAG with dependency tracking
|   |-- confidence.py        # Step/plan confidence scoring
|   `-- reflection.py        # Self-critique of results
|
|-- agents/                  # Phase 4 — Multi-agent system
|   |-- base.py              # BaseAgent with permissions + health
|   |-- registry.py          # Skill/keyword-based routing
|   |-- roster.py            # 15 specialist agents
|   |-- orchestrator.py      # Brain → agent assignment → supervised run
|   `-- messaging.py         # Inter-agent message bus
|
|-- workflows/               # Phase 6 — Declarative workflows
|   |-- engine.py            # Supervised, parallel, resumable runs
|   |-- builder.py           # Declarative workflow definitions
|   `-- checkpoint.py        # State persistence for resume
|
|-- autonomous/              # Phase 7 — Autonomous mode
|   |-- maya_auto.py         # Self-running loop
|   |-- executor_bridge.py   # Tool execution bridge
|   |-- recovery.py          # Failure classification + strategy
|   |-- improver.py          # Output improvement
|   `-- reporter.py          # Run report generation
|
|-- llm/
|   |-- router.py            # Smart LLM routing with fallback
|   |-- prompt_builder.py    # Prompt templates
|   `-- providers/           # Groq, Gemini, OpenAI, Claude, DeepSeek, NIM
|
|-- memory/
|   |-- memory_manager.py    # Unified memory interface
|   |-- short_term.py        # Current session memory
|   |-- long_term.py         # SQLite persistent memory
|   |-- episodic_memory.py   # Past task episodes
|   |-- semantic_memory.py   # Facts and knowledge
|   |-- vector_memory.py     # Semantic search (ChromaDB/TF-IDF)
|   `-- context_manager.py   # Context tracking
|
|-- tools/
|   |-- registry.py          # Central tool registry
|   |-- web/                 # Web search, browser, scraping
|   |-- files/               # File read/write/manage
|   |-- code/                # Code execution, git, web builder
|   |-- system/              # Shell, terminal, process manager
|   |-- media/               # Vision, OCR, TTS, image generation
|   |-- communication/       # Email (SMTP), webhooks (Slack/Discord)
|   |-- infrastructure/      # API key provisioner
|   |-- bridge/              # Desktop GUI bridge agent
|   `-- data/                # Database tools
|
|-- infrastructure/          # Service infrastructure
|   |-- notifications.py     # Multi-channel alerts (in-app, email, webhook, FCM)
|   |-- webhook_triggers.py  # Inbound webhooks with HMAC verification
|   |-- scheduler.py         # Cron-based persistent job scheduling
|   |-- cron.py              # 5-field cron expression parser
|   |-- device_bridge.py     # Desktop GUI pairing
|   |-- deploy_pipeline.py   # Build → Deploy pipeline
|   |-- research_engine.py   # Market research engine
|   |-- cognition.py         # Autonomous cognition loop
|   `-- ...                  # Rate limiter, cache, flags, etc.
|
|-- enterprise/              # Enterprise features
|   |-- api_keys.py          # API key lifecycle (hash-stored)
|   |-- rbac.py              # Role-based access control
|   `-- ...                  # Orgs, audit, workspace scoping
|
|-- rag/                     # Retrieval-Augmented Generation
|   |-- retriever.py         # Hybrid search (BM25 + vector)
|   |-- augmenter.py         # RAG auto-connect in chat()
|   `-- ...                  # Chunker, indexer, sources
|
|-- learning/
|   |-- improvement_engine.py  # Learn from every task
|   `-- experience_store.py    # Store lessons
|
|-- security/
|   |-- risk_checker.py      # Risk assessment (HIGH/MEDIUM/LOW/CRITICAL)
|   |-- permissions.py       # Tool permissions
|   `-- sandbox.py           # File system sandbox + env scrubbing
|
|-- human/
|   |-- approval.py          # Human approval for risky actions
|   |-- feedback.py          # Collect user feedback
|   `-- intervention.py      # Manual intervention / kill-switch
|
`-- storage/                 # Auto-created at runtime
    |-- memory/              # Database files
    |-- logs/                # Log files
    |-- backups/             # Code backups
    |-- publish/             # Publish audit trail
    |-- scheduler/           # Cron schedule persistence
    |-- notifications/       # In-app notification store
    `-- hooks/               # Webhook trigger store
```

---

## Available Tools

| Category | Tool | Description |
|----------|------|-------------|
| web | `web_search` | Search the internet (SerpAPI → Google CSE → DuckDuckGo) |
| web | `web_scrape` | Read any webpage |
| web | `browser_open` / `browser_click` / `browser_type` | Browser automation (Playwright) |
| web | `browser_click_visually` | Vision-guided clicking (screenshot → coords → click) |
| web | `browser_look` | Ask vision questions about the current page |
| web | `rest_api_request` | Make HTTP requests to any REST API |
| web | `graphql_query` | Query any GraphQL endpoint |
| web | `search_free_apis` | Scan for new free/cheap LLM APIs and report findings |
| web | `provision_api_key` | Automate LLM API key signup with approval gate |
| web | `youtube_search` / `youtube_transcript` | YouTube search and transcripts |
| file | `read_file` / `write_file` / `list_files` / `delete_file` | File operations |
| file | `read_pdf` / `csv_read` / `csv_write` / `json_read` / `json_write` / `excel_read` / `excel_write` | Document handling |
| file | `zip_create` / `zip_extract` / `zip_list` | Zip archive operations |
| code | `run_code` | Execute Python code in a sandbox |
| code | `calculate` | Math calculations |
| system | `run_shell` / `run_terminal` | Shell and terminal commands |
| system | `list_processes` | List running processes |
| developer | `git_init` / `git_status` / `git_log` / `git_diff` / `git_add` / `git_commit` / `git_branch` / `git_checkout` / `git_merge` | Local git operations |
| developer | `github_get_repo` / `github_list_files` / `github_get_file` | GitHub public API |
| developer | `database_query` / `database_list_tables` | SQL queries against own DB |
| developer | `web_build` / `web_deploy` | Scaffold and deploy static sites |
| media | `vision_analyze` | Image analysis (Gemini → OpenAI → Claude fallback) |
| media | `ocr_image` | Text extraction from images |
| media | `text_to_speech` | Convert text to spoken audio |
| media | `generate_image` | AI image generation |
| media | `image_tool` | Image operations |
| communication | `email` | Send email via SMTP (config: `SMTP_HOST/PORT/USER/PASS/FROM`) |
| communication | `webhook_send` | Send messages to Slack/Discord/generic webhooks |
| memory | `knowledge_search` / `knowledge_ingest` | RAG knowledge base |
| meta | `create_tool` | Self-write and register new tools (approval-gated) |
| meta | `device_control` / `device_result` | Desktop GUI control via Device Bridge |

---

## Supported LLM Providers

| Provider | Speed | Free Tier | Notes |
|----------|-------|-----------|-------|
| **NVIDIA NIM** | Fast | ✅ Free (80+ models) | Primary brain — DeepSeek V3/V4, Qwen, Llama, Kimi, MiniMax |
| **OpenRouter** | Fast | ✅ Free (35+ models) | Fallback #1 — one key, many models |
| **Cerebras** | Fastest | ✅ Free | Fallback #2 |
| **Groq** | Fastest | ✅ Free | Fallback #3 — Llama, Mixtral |
| Gemini | Fast | ✅ Free | Vision, long context |
| OpenAI | Smart | Paid | GPT-4o, complex reasoning |
| Claude | Best | Paid | Writing, analysis |
| DeepSeek | Best | Paid | Coding, math |

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
