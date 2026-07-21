# CLAUDE.md — Maya 2.0 ULTRA · Project Memory

> Read this file first at the start of every session. It is the single source of
> truth for what Maya is, what is already built, what was learned the hard way,
> the safety rules that must never be broken, and what to build next.
> Keep it updated: when a phase finishes, move it from "In progress / Next" to
> "Done", and add any new hard-won lesson to the Lessons section.

---

## ⏸ PROJECT PAUSED — 2026-07-20

**Highest completed phase: 31** (Build → Deploy Pipeline).

**What works:**
- Cognition propose-only (Phase 17) — `POST /api/v1/cognitive/cycle` proposes
  objectives from the VPS Health mission; AUTORUN=false so nothing auto-executes.
- Approved one-shot execution via `POST /api/v1/cognitive/execute-objective`
  (read-only whitelist: docker ps/info/logs, journalctl, systemctl status, etc.).
- Build→Deploy pipeline (Phase 31) — verified live end-to-end: SCP local source
  to VPS → docker build → docker run → auto-register in Phase 30 AppRegistry.

**Flag state (all safe defaults):**
- `COGNITION_ENABLED=true` — cognition loop enabled, but propos-only.
- `COGNITION_AUTORUN=false` — Maya never auto-executes; proposes only.
- `DEPLOY_PIPELINE_ENABLED=false` — pipeline routes return 503.
- `APP_MONITOR_ENABLED=false` — Phase 30 health monitor off.

**Known safety gaps (CLAUDE.md section 3.5, must fix before AUTORUN=true):**
  1. `docker restart`/`start`/`stop` pass RiskChecker as only MEDIUM (not blocked).
  2. `run_terminal` has no blocked-command list (unlike `run_shell`).
  3. No per-objective rate limit on SSH.

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

- [ ] **Commit Phase 17** (`infrastructure/cognition.py` + api.py block). Not yet
      committed — do this so it isn't lost.
- [ ] **Add an LLM key** to `.env` (GROQ_KEY or GEMINI_KEY). Without it Maya
      cannot actually think — self-goal generation needs an LLM. (`No API keys
      found` warning has been appearing.)
- [ ] **Rotate VPS password** in the panel, update `.env`.
- [ ] **Rotate JWT `SECRET_KEY`** away from the default `maya-secret-key-2024`.

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
- 4-step rollback on failure. Needs live VPS test before enabling.

### Phase 19 — Market / research engine
- Turn the research agent + web scraping into market analysis: scrape →
  summarize → report. Analysis only, NO external action. Safe first business step.

### Phase 20 — Business agents + strategy
- Add pricing / finance / marketing / strategy agents and a "business goal" type.
- Output = plans/proposals, not execution.

### Phase 21 — Guarded real-world action
- publish / accounts / payments — all behind hard approval gates + full audit.
- This is where isolation matters most (see Business Maya below).

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

_Last updated: after Phase 17 cognition engine built (flags OFF, not yet
committed) and remote deploy verified live on the VPS._
