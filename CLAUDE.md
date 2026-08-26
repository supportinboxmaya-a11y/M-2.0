# CLAUDE.md — Maya 2.0 ULTRA · Project Memory

> Read this file first at the start of every session. It is the single source of
> truth for what Maya is, what is already built, what was learned the hard way,
> the safety rules that must never be broken, and what to build next.
> Keep it updated: when a phase finishes, move it from "In progress / Next" to
> "Done", and add any new hard-won lesson to the Lessons section.

---

## ⚡ ACTIVE — 2026-08-25

**Session (2026-08-26) — router resilience + push-validation hardening:**
- **NIM default model rotated AGAIN**: `meta/llama-3.3-70b-instruct` retired
  from NIM (410 Gone). New default `minimaxai/minimax-m3` (verified live,
  ~1.4s latency). Lesson repeats: free model slugs rotate — check
  `/v1/models` and re-probe before assuming code bugs.
- **Router resilience (2 real gaps found by live validation):**
  1. `set_key()` hardcoded `available=False` forever — after any key
     rotation the provider stayed dead → fixed: fresh availability probe,
     error_count reset.
  2. No time-based recovery: 5 rapid errors permanently disabled a
     provider for the whole process life (backoffs couldn't help) → fixed:
     cooldown recovery in `_is_healthy` (`LLM_PROVIDER_COOLDOWN`, default
     120s since last error ⇒ re-probe + fresh start).
- **Phase 41 `resume_incomplete` scan mode**: new `plan_proposals=False`
  param = cheap policy scan of the WHOLE backlog with zero LLM calls.
  Needed because stale goals accumulate oldest-first and a small
  `max_goals` cap silently hides fresh goals behind them (found live:
  106-goal backlog).
- `validate_push.py` (NEW): long-horizon multi-goal, restart-recovery
  policy, Phase 42 propose-only — all against REAL providers;
  `PUSH_SECTIONS=H1,H2b` env gates sections for throttle-window re-runs.
  Status: **15/19 checks PASS**; remaining 4 blocked ONLY by provider
  quota exhaustion (NIM sustained 429 + OpenRouter free-models-per-day
  cap hit) — environmental, re-run when quota resets.
- OpenRouter lesson: free tier has a DAILY request cap
  ("free-models-per-day"); burst retries burn it fast — gate validations.
- Full suite: **353 tests pass** (was 350).

**Highest completed phase: 42** (AGI roadmap Phases 34–42).

**Latest session (2026-08-25, later) — Phase 42 self-improvement loop (`530e74e` + this):**
- `infrastructure/self_improvement.py` — `SelfImprovementEngine`:
  - **Gap analysis**: ranks task types from `SelfModel.weaknesses()`;
    priority = attempts × failure-rate, +1 when no stored skill covers
    the type; suggests reinforce_skill vs create_skill_or_tool.
  - **Proposals** (propose-only): drafted to
    `storage/self_improve/proposals.json`; tool proposals get an LLM
    code draft at propose time but NOTHING loads then.
  - **Execution is explicit-only** (`POST .../proposals/{pid}/execute`,
    requires prior owner approval via `/decide`):
    skill → distills buffered episodes into a Skill; tool → through
    ToolCreator's AST scan + high-risk human approval gate.
  - **Kernel `_distill_episode` stub implemented** — successful goals
    feed the engine's episode buffer; ≥3 similar successes auto-distill
    a skill (group key ignores digits/stopwords; coverage check prevents
    duplicates). Knowledge-level only — NOT a second controller.
- Routes under `/api/v1/cognitive/self-improve/*` (6); flag OFF → clean
  503. RBAC execute on all mutations.
- Flag: `SELF_IMPROVE_ENABLED=false` (default OFF per Safety Rule 3).
- Live-tested against the real self-model DB (gap found: "code" tasks,
  47 attempts / 6.4% success) — propose returned a proper proposal.
- **Lesson:** api.py phase blocks run at IMPORT time but `maya_instance`
  is created in the FastAPI LIFESPAN — never capture maya attributes in
  module-level vars; resolve lazily per-request (here: via the kernel
  singleton `_p18_kernel.self_improvement`).
- Full suite: **350 tests pass** (was 333).

**Highest completed phase: 41** (AGI roadmap Phases 34–41).

**Latest session (2026-08-25, final) — end-to-end completion push:**
- **Phase 40 vector retrieval** (`c422cc1`) — `SemanticIndex` (TF-IDF cosine
  fallback always on; optional ONNX MiniLM embeddings behind
  `SEMANTIC_EMBEDDINGS=false`) wired into skills, knowledge_query,
  learn-dedup, goal grounding.
- **Phase 41 auto-resume across restarts** — `kernel.resume_incomplete()`:
  ACTIVE goals re-execute when `MAYA_AUTO_RESUME=true` (default false);
  SUSPENDED/BLOCKED goals ALWAYS propose-only; boot hook runs it in a
  daemon thread (never blocks startup); audit row per goal.
- **Single-controller hardening** — closed the two latent parallel loops:
  - Phase 17 `CognitionEngine` AUTORUN path now delegates through
    `kernel.process_goal` when the kernel is attached + unified loop on
    (`cognitive_kernel=` ctor arg; wired in api.py Phase 18 block).
  - Phase 7 `POST /autonomous/run` routes through the kernel first;
    standalone `AutonomousMaya.run()` only a legacy fallback (flag-gated).
  - Locked by new `tests/test_delegation_invariants.py`.
- **MAYA_UNIFIED_LOOP=true live in .env** — production runs through the kernel.
- Full suite: **333 tests pass**; validate_final.py 32/32; stress_test mock
  10/10; unseen-tasks & e2e-autonomous suites pass; boot 330 routes.

**Highest completed phase: 40** (AGI roadmap Phases 34–40, all committed).

**Latest session (2026-08-25, later) — Phase 40 vector retrieval (`c422cc1`):**
- `infrastructure/semantic_index.py` — `SemanticIndex`: TF-IDF cosine engine
  (zero deps, always on), optional real embeddings (chromadb ONNX MiniLM)
  behind `SEMANTIC_EMBEDDINGS=false` (default OFF; first use downloads a model).
- Wired into: `ProceduralMemory.search_skills`, `kernel.knowledge_query`,
  `kernel.learn()` nearest-belief lookup, `_gather_cognitive_context`
  belief grounding, belief/skill index sync on add/update/delete.
- Belief-revision dedup stays CONSERVATIVE on the fallback: cosine finds the
  nearest candidate but token-overlap >= 0.8 must still confirm the merge
  (a "succeeds"->"fails" conflict must revise, not duplicate); with real
  embeddings the vector score (>= 0.85) decides.
- `knowledge_stats()` / procedural `stats()` now expose `retrieval_engine`.
- **All 321 tests pass** (was 301). Boot smoke-tested (330 routes).

**Previous session (2026-08-25) — AGI evolution, Phases 34→39:**
- Committed the leftover Phase 18 hardening working tree first (`ecbba53`),
  then implemented six AGI phases sequentially, full suite green after each:
  - **Phase 34 Unified Cognitive Loop** (`644bf2f`) — `CognitiveKernel` is now
    THE single central controller. `kernel.process_goal()` = one control entry
    (persistent goal → memory/belief grounding → execution → learning).
    Exactly ONE executor backend (Maya's own `_run_pipeline`) registered via
    `register_executor()`; models/agents/tools/workflows stay capabilities.
    `Maya.run()` delegates through the kernel when `MAYA_UNIFIED_LOOP=true`.
  - **Phase 35 Persistent goal pursuit** (`5b876ce`) — goals survive restarts;
    `get_incomplete_goals()` + `resume_goal(id, execute=False)` (propose-only
    by default). Boot only logs incomplete goals, never auto-executes.
  - **Phase 36 Knowledge engine** (`76a99bc`) — `kernel.learn()` with odds-form
    Bayesian belief revision (agreeing evidence strengthens, conflicting
    weakens), `knowledge_query()` ranked retrieval feeding planning,
    decay+prune hooked into consolidation, research reports auto-learned.
  - **Phase 37 Skill generalization** (`e87d360`) — `search_skills()` ranked
    retrieval (skills generalize to novel-but-similar goals),
    `compose_skills()` builds higher-order skills; kernel goal grounding and
    planner hints now include learned skills.
  - **Phase 38 MCP client** (`d32fd98`) — Maya as MCP HOST, zero-dependency
    JSON-RPC client (stdio + Streamable HTTP), MCP tools register as ordinary
    registry capabilities (`mcp_<server>_<tool>`); OFF behind `MCP_ENABLED`.
  - **Phase 39 Self-model** (`7cf7c5e`) — persistent SQLite self-model: task-
    type track record, strengths/weaknesses, `assess()` pre-planning check;
    every unified-loop outcome updates it; one-line self-assessment injected
    into planner hints.
- **All 301 tests pass** (was 270 at session start).

**Critical architecture invariant (do not regress):**
Maya/CognitiveKernel is the ONLY control loop. Models, agents, tools, MCPs,
workflow engines are capabilities the kernel uses via its single registered
executor. Never add a second controller or bypass `process_goal`/`_drive_goal`
for goal execution.

**New flag state:**
- `SEMANTIC_EMBEDDINGS=false` — flip to use real ONNX MiniLM embeddings in
  `SemanticIndex` (downloads a local model on first use; TF-IDF fallback
  otherwise).
- `MAYA_UNIFIED_LOOP=false` — flip to route `maya.run()` through the kernel.
- `MCP_ENABLED=false` + `MCP_SERVERS=[...]` — MCP host support.
- All prior flags unchanged.

**Next candidates:** flip `MAYA_UNIFIED_LOOP=true` after watching propose-only
behavior; auto-resume policy for incomplete goals (still explicit-only by
design); add one Groq/OpenRouter key as router fallback vs NIM throttling.

**Lesson (Phase 40):** TF-IDF cosine cannot bridge zero-overlap paraphrase on
short texts (~0.05 similarity) — that is what the embeddings engine is for;
the fallback upgrades RANKING (IDF weighting), not vocabulary gap. Keep
belief-revision dedup conservative on the fallback (token-overlap confirm).

---

## ⚡ PRODUCTION PROVIDER — 2026-08-25 (later session)

- **NVIDIA NIM is LIVE with a working inference key** (owner rotated it after
  the old key turned out 403-on-inference; old default model had been retired).
- Default model: `meta/llama-3.3-70b-instruct`; override via `NVIDIA_NIM_MODEL`.
  Timeout tunable via `NVIDIA_NIM_TIMEOUT` (default 180s — planning calls can
  take 1-3 min on free tier).
- **Cost tracking now real**: every provider reports token usage through
  `llm/providers/base.py::report_usage` -> Maya's CostTracker, so budget
  gating works. Verified live (13 calls / 10,932 tokens captured).
- **Known NIM behavior**: free tier throttles hard under burst load (429s,
  read timeouts). Pipeline degrades gracefully (blocked goal, no state loss,
  audit intact); operator-level retry with exponential backoff succeeds when
  the window passes.
- **OpenRouter fallback LIVE (2026-08-25)** — `OPENROUTER_KEY` in `.env`;
  default model now `nvidia/nemotron-3-super-120b-a12b:free`
  (`meta-llama/llama-3.3-70b-instruct:free` was retired from the free tier,
  404). Verified live: direct provider call + router `provider='openrouter'`.
  Router priority: omniroute → nvidia_nim → groq → cerebras → openrouter → ...
- Lesson: OpenRouter rotates `:free` slugs — if a 404 "unavailable for free"
  appears, re-query https://openrouter.ai/api/v1/models for current free ids.
- SECURITY: the OpenRouter key was pasted into chat once (2026-08-25) —
  rotate it once testing stabilizes (Safety Rule 6).
- Live E2E harness: `validate_live.py` (real inference end-to-end).
- SECURITY: the rotated key was pasted into chat once — rotate again after
  testing stabilizes (Safety Rule 6).
- `DEPLOY_PIPELINE_ENABLED=false` — pipeline routes return 503.
- `APP_MONITOR_ENABLED=false` — Phase 30 health monitor off.

**All safety gaps (CLAUDE.md section 3.5) are now FIXED and verified (uncommitted working tree):**
  1. `docker restart`/`start`/`stop/kill/rm/rmi` — promoted from MEDIUM to HIGH in RiskChecker (blocked without approval).
  2. `run_terminal` blocklist — added matching `BLOCKED_COMMANDS` list (same 8 patterns as `run_shell`).
  3. Per-objective SSH rate limit — `_P17_SSH_MAX_PER_OBJECTIVE=10` counter in execute-objective endpoint.

**Remaining roadmap:**
- Phase 19 — Market / research engine
- Phase 20 — Business agents + strategy
- Phase 21 — Guarded real-world action

**Resume command:** `cd ~/maya/M-2.0 && cat CLAUDE.md`

---

## 1. What Maya is

Maya is an autonomous, modular AI agent ("AI OS"). It understands a goal, breaks
it into tasks, executes them with tools, verifies results, recovers from
failures, and improves over time.

**The full vision (the owner's intent):**
- Maya thinks on its own (self-directed, not only reactive).
- Maya uses any app/tool it needs — and can write new tools for itself.
- Maya builds software / websites / apps / agents.
- Maya hosts and manages those apps (deploy, run, monitor, restart).
- Maya does market analysis and eventually runs a business — with a human
  approving every real-world / money / irreversible action.
- Goal: more capable and more structured than AutoGPT (auth, RBAC, memory,
  approval gates, multi-agent — not a naive loop).

**Stack:** Python + FastAPI. Main app entry: `api.py` (large; phases are appended
as soft-failing blocks). ~218 Python files. Runs on Termux (Android) during
development at `/data/data/com.termux/files/home/maya/M-2.0`.

---

## 2. Current state (verified)

### Integrated in api.py (soft-fail blocks, each prints "Phase N active")
- Phase 1 Infrastructure — metrics, task queue, rate limiter, flags
- Phase 2 Memory system
- Phase 3 Brain engine — goal analysis, task graph, confidence, reflection
- Phase 4 Multi-agent — 11 agents + orchestrator
- Phase 5 Tool framework
- Phase 6 Workflow engine
- Phase 7 Autonomous mode (`AutonomousMaya`)
- Phase 8 Multi-model router+
- Phase 9 Enterprise — RBAC, orgs, API keys, audit, dashboard
- Phase 10 Learning — feedback, experience replay, prompt optimization
- Phase 11 RAG (hybrid search)
- Phase 12 Multimodal (vision, OCR, TTS)

### Feature phases (in tests/modules, merged into existing code)
- Phase 13 vector memory · Phase 14 git + GraphQL tools · Phase 15 sandbox
  hardening · Phase 16 (tests) autonomous recovery

### Phase 30 — App registry + remote monitoring (NEW, verified live)
- `infrastructure/app_registry.py` — SQLite store for remote Docker containers
- Routes under `/api/v1/hosting/registry/...` — CRUD, health-check (single-SSH
  sweep), restart (approval-gated), logs. Default OFF behind `APP_MONITOR_ENABLED`.

### Phase 31 — Build → Deploy Pipeline (NEW, flag OFF)
- `infrastructure/deploy_pipeline.py` — `DeployPipeline` class + singleton
- `POST /api/v1/deploy/pipeline/plan` — validate inputs, return step list (no SSH)
- `POST /api/v1/deploy/pipeline/execute` — dry-run by default; `confirm=true` triggers
  SCP → docker build → docker run → auto-register in Phase 30 AppRegistry
- `GET /api/v1/deploy/pipeline/status` — last execution result
- Reads: local directory with Dockerfile + code → SCP to VPS → build → run → register
- Rolling: 4-step rollback cleans remote dir, image, and orphan container on any failure
- Default OFF behind `DEPLOY_PIPELINE_ENABLED=false`

### Phase 33 — APIKeyProvisioner + Communication (NEW, no flag needed)
- `tools/infrastructure/api_key_provisioner.py` — `APIKeyProvisioner` class with
  `search_free_apis` (weekly watcher, propose-only scans) and `provision_key`
  (autonomous signup with critical-risk approval gate, CAPTCHA/OTP pause, M1 key
  pool integration). Registered as `search_free_apis` and `provision_api_key` tools.
- Communication tools — `EmailTool` fixed (env_first, SMTP_FROM, test action),
  `WebhookTool` added (Slack/Discord/generic outbound webhooks). Both registered
  under `communication` category in tool_manager.py.
- `.env.example` updated with SMTP, webhook URL, and FCM credential vars.
- Brain engine fixed — circular import resolved, 35/35 tests passing.

### Phase 32 — Research / Market Engine (NEW, flag OFF)
- `infrastructure/research_engine.py` — `ResearchEngine` class + singleton
- `POST /api/v1/research/analyze` — fetch URLs → chunk → summarize via LLM → save report
- `GET /api/v1/research/reports` — list all reports (most recent first)
- `GET /api/v1/research/reports/{id}` — get a single report with URLs and metadata
- Analysis-only: reads public web pages, writes local SQLite + markdown file only
- Reuses: WebScraper, LLMRouter (Nvidia NIM + fallback), Chunker, MemorySummarizer
- Per-domain crawl delay >= 1s; Chrome user-agent; LLM failure falls back to extractive
- Default OFF behind `RESEARCH_ENGINE_ENABLED=false`

- `.env` backup lives at `~/storage/downloads/maya-env-backup.txt` — refresh it after any .env change.
- Phase 17.5 verified — 2 propose-only cycles clean, proposals sensible; duplicate mission cleaned; delete_mission rowcount bug fixed.

### Remote deploy — DONE & LIVE (committed `d11f259`)
- `infrastructure/remote_deploy.py` — `RemoteDeployer` (SSH + Docker).
- api.py routes: `POST /api/v1/hosting/remote/deploy` and
  `POST /api/v1/hosting/remote/{app}/{start|stop|restart|logs}`.
- Every route requires RBAC `execute`. Destructive ops go through
  RiskChecker + ApprovalManager. No VPS configured → clean 503, never 500.
- **Verified live:** deployed an nginx container to the real VPS
  (container id `7213ab4ab5a8`, confirmed with `docker ps`).

### Phase 17 — Autonomous Cognition engine — BUILT, committed, flags ON (propose-only)
- File: `infrastructure/cognition.py` (moved here from `autonomous/` to avoid a
  circular import via `autonomous/__init__.py` → AutonomousMaya → BrainEngine).
- `CognitionEngine`: SQLite store (missions, objectives, cognition_audit).
  - **Mission** — persistent directive (has `self_gen` flag).
  - **Objective** — concrete goal with priority, status, optional depends_on,
    `requires_approval`.
  - Self-goal generation via `llm_fn` (decomposes a mission into 3–8 objectives).
  - Priority scoring; `_cycle()`; scheduler registration (cron on TaskQueue).
- api.py Phase 17 block: 10 routes under `/api/v1/cognitive/...`, all require
  RBAC `execute`; when disabled they return clean 503, `/status` works even when
  disabled. Server boots with ~196 routes.
- **Two feature flags:**
  - ~~`COGNITION_ENABLED=false`~~ → now `COGNITION_ENABLED=true` (live in propose-only).
  - `COGNITION_AUTORUN=false` — even when enabled, `_cycle()` only PROPOSES the
    chosen objective (propose-only); it does NOT call `AutonomousMaya.run()`.
- `_cycle()` order (the three safety gates are all present, verified in summary):
  `check_interrupt` (kill-switch) → load missions → auto-generate objectives if
  self_gen → pick top-priority pending → **approval gate for external actions** →
  **propose-only if AUTORUN=false** else execute → reflect → store experience →
  **audit log every step**.

---

## 3. Lessons learned the hard way (do not relearn these)

- **Login endpoint is `/api/v1/auth/login`** — NOT `/api/v1/login`. Wrong path
  returns empty / fails silently.
- **Password SSH needs `sshpass`.** paramiko is not installed on the Termux
  device, so RemoteDeployer falls back to the system `ssh` binary; password auth
  through it requires `sshpass` (`pkg install -y sshpass`). Missing sshpass was
  the cause of an earlier deploy 400.
- **VPS custom SSH port** is 20045 (not 22). Always pass the port.
- **First SSH to a new host** may hit "Host key verification failed"; deploy uses
  `StrictHostKeyChecking=no` for automation.
- **Circular imports:** don't put loop/engine code inside `autonomous/` if it
  imports `AutonomousMaya` — put persistent-service code in `infrastructure/`.
- **Build discipline that works:** read the relevant modules first → write →
  `py_compile` → boot-test with a short `timeout` → only then wire/enable.
- **Always inspect a script before running it** if it's a separate file Claude
  hasn't seen (we caught bugs this way).

---

## 3.5 Known safety gaps

- **docker restart/start/stop pass RiskChecker as only MEDIUM (not blocked)** —
  must be approval-gated before `AUTORUN=true`. The cognitive execute path
  (`POST /api/v1/cognitive/execute-objective`) has its own **read-only command
  whitelist** (`_P17_RO_PREFIXES` in api.py) that explicitly blocks any
  lifecycle commands — that whitelist is an independent layer and should stay
  in place even after AUTORUN flips to true.
- **run_terminal has no blocked-command list** — unlike `run_shell` which blocks
  `rm -rf /`, `mkfs`, `dd`, fork bombs, and `chmod -R 777 /`, the terminal tool
  has zero filtering. Any LLM-generated command passes through unrestricted.
- **No per-objective rate limit on SSH** — the execute-objective endpoint makes
  one SSH call per sub-step, but there's no global cap. A buggy or malicious
  objective could hammer the VPS with repeated SSH connections.

---

## 4. VPS / environment config

VPS provider panel: aiccloud. Ubuntu 24.04, Docker 29.1.3 installed and working.

`.env` (gitignored — line 2 of `.gitignore`; NEVER commit it) holds:
```
VPS_HOST=152.228.227.51
VPS_PORT=20045
VPS_USER=root
VPS_PASSWORD=<secret>        # or VPS_SSH_KEY_PATH=<path>
# LLM keys (need at least one — see Loose Threads):
GROQ_KEY=...                 # free at console.groq.com
GEMINI_KEY=...               # free at aistudio.google.com
# JWT signing secret (rotate away from the default):
SECRET_KEY=<your-own-secret>
```

---

## 5. SAFETY RULES (never break — human-in-the-loop is the backbone)

1. **Think freely, act gated.** Maya may reason/plan/decide internally without
   limit, but every EXTERNAL or IRREVERSIBLE action (deploy, publish, spend
   money, touch an account, delete) MUST pass through `human/approval.py`.
2. **Kill-switch always on.** `human/intervention.py` `check_interrupt()` runs at
   the top of every cognition cycle. The owner can pause/stop at any time.
3. **New capabilities ship OFF.** Feature flags default to false; enable one step
   at a time, watch behavior, then loosen.
4. **Propose-only first.** For any new autonomy, run with AUTORUN=false so Maya
   proposes and the owner approves each "go" before it can execute on its own.
5. **Audit everything.** Every cognition step writes an audit-log row.
6. **Rotate any secret that has been shown on screen / in chat / in shell
   history** (VPS password, JWT secret) once testing is done.
7. **Self-written tools** (`tools/system/tool_creator.py`) pass an AST scan AND
   the approval gate before loading — keep both on.

---

## 6. Loose threads — seal these to "finish" the current work

- [x] **Rotate VPS password** in the panel, update `.env` — DONE (both `.env` and VPS panel updated).
- [x] **Rotate JWT `SECRET_KEY`** away from the default `maya-secret-key-2024` — DONE (256-bit random hex in `.env`).

---

## 7. Roadmap (what's left, in order)

### Phase 17.5 — Bring cognition to life (carefully)
- Set `COGNITION_ENABLED=true`, keep `COGNITION_AUTORUN=false`.
- Create a mission (e.g. "Monitor the VPS and suggest improvements"), run
  `POST /api/v1/cognitive/cycle` once, and read what Maya PROPOSES. No execution.
- Gradually loosen only after watching several propose-only cycles.

### Phase 30 — App registry + remote monitoring (DONE, verified live)
- `infrastructure/app_registry.py` — SQLite store for remote Docker apps.
- Health checks via single-connection `batch_container_status()` SSH sweep.
- Auto-restart through approval gate.
- Routes under `/api/v1/hosting/registry/...` (Phase 15's `/hosting/apps/` is
  local subprocesses — separate domain).
- Default OFF: `APP_MONITOR_ENABLED=false`.

### Phase 31 — Build → Deploy Pipeline (DONE, flag OFF)
- `infrastructure/deploy_pipeline.py` — `DeployPipeline` class + singleton.
- SCP local source → VPS → docker build → docker run → auto-register.
- `/plan` (no SSH, no side effects), `/execute` (approval-gated, dry-run by default),
  `/status` (last result).
- 4-step rollback on failure.

### Phase 32 — Research / Market Engine (DONE, flag OFF)
- `infrastructure/research_engine.py` — `ResearchEngine` class + singleton.
- 3 routes: POST /analyze (fetch→chunk→summarize→save), GET /reports, GET /reports/{id}.
- Analysis-only: reads public web pages, writes local SQLite + markdown. Zero external writes.
- Reuses: WebScraper, LLMRouter (Nvidia NIM + fallback), Chunker, MemorySummarizer.
- Per-domain crawl delay >= 1s. LLM failure → extractive fallback.

### Phase 20 — Business agents + strategy (DONE, flagless — no env toggle needed)
- 4 new business agents in `agents/roster.py` — pricing, finance, marketing, strategy
  (all pure-LLM with `permissions=()`, zero tool access).
- New `mission_type` column on the missions table (`'general'` or `'business'`).
- `infrastructure/business_research.py` — `BusinessResearchEngine` that runs a
  business objective through all 4 agents via `llm_fn` in sequence and produces
  a bundled report (pricing → finance → marketing → strategy → summary).
- 3 new API endpoints under the Phase 17 block:
  - `POST /cognitive/missions/{id}/analyze` — triggers business analysis
  - `GET /cognitive/missions/{id}/reports` — list reports
  - `GET /cognitive/missions/{id}/reports/{report_id}` — full report with agent responses
- Business objectives set `requires_approval=False` (pure analysis — no side effects).
- Propose-only design: `COGNITION_AUTORUN=false` throughout.
- No SSH, no Docker, no tool execution, no payment/publish paths.

### Phase 21 — Guarded publish (DONE — scoped to static-site publish only)
- `infrastructure/publish_engine.py` — wraps `WebBuilderTool.deploy()` with:
  - Hard approval gate via `ApprovalManager` (risk_level="critical" — blocks in ALL modes)
  - Approval prompt shows **exact file contents verbatim**, not a summary
  - Permanent, write-once audit trail (`publish_audit` SQLite table in `storage/publish/`)
- 3 API endpoints: `POST /api/v1/publish`, `GET /api/v1/publish/history`,
  `GET /api/v1/publish/history/{id}`
- No new SSH, Docker, payment, or account-modifying code paths.
- Payments and account management remain for a future phase.

---

## 8. Future architecture — multi-part Maya & Business Maya

Maya is already multi-agent (11 role agents) and now mission-based (Phase 17), so
splitting Maya into parts is natural.

**Business Maya** = a dedicated business part.
- **Stage 1 (start here):** one Maya, with a separate **Business Mission** +
  business agents (market-research, finance, strategy) living on the existing
  cognition/agent framework. Shares memory and tools; can directly use Maya's
  app-building and deploy abilities.
- **Stage 2 (when it handles real money):** move Business Maya to a **fully
  isolated instance** — its own DB, memory, mission set, possibly its own VPS —
  talking to the main Maya only when needed.

**Why isolate the business part:** it is the ONLY part that touches money /
publishing / external accounts. Isolation lets its safety rules be the strictest
(every spend/transaction behind approval) without affecting the rest of Maya.

---

## 9. LLM Strategy (decided — $0/month stack)

Budget: ~$0/month (hard limit $1-2). No paid frontier APIs.

Primary brain: **NVIDIA NIM** — free API, 80+ strong open models
(DeepSeek V3.2/V4, Qwen3 Coder 480B, MiniMax, GLM, Kimi, Llama).
- Sign up free at build.nvidia.com (phone verification, no credit card)
- OpenAI-compatible: `base_url = https://integrate.api.nvidia.com/v1`
- env: `NVIDIA_NIM_KEY=nvapi-...` ; limit ~40 req/min, no daily token cap
- Model IDs use slash format, e.g. `deepseek-ai/deepseek-v3`

Fallbacks (when NIM rate-limits): OpenRouter free (one key, 35+ free
models), Cerebras free, Groq free.
Special cases only: GitHub Models (free GPT-5/o3 class, tiny token limits).

Rules: never anchor to a single free provider; always keep at least one
fallback. Router default = NIM, fallback chain = OpenRouter → Cerebras → Groq.

---

## 10. How to resume in a new chat / session

1. Give this file to Claude (or let Command Code read it — it reads CLAUDE.md
   each session).
2. Say which phase you want to work on (default suggestion: seal the Loose
   Threads, then Phase 17.5 propose-only).
3. Keep the build discipline: read modules → write → py_compile → boot-test →
   enable one flag at a time.
4. Never skip the Safety Rules in section 5.

_Last updated: Phase 17 cognition engine committed (`b398210`), flags ON
(propose-only). Remote deploy verified live. M1 keystore integrated._
