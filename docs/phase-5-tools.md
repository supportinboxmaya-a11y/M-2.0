# Phase 5 — Tool Framework

## Purpose
Every tool call gets the five spec guarantees — Permission, Logging,
Timeout, Retry, Validation — via a wrapper layer (`tools/framework.py`).
The existing ToolRegistry and all 15+ tools stay byte-identical; the
framework ADOPTS them (adopt_existing) instead of replacing them.

## Components
- ToolPolicy: category, timeout_s, retries, dangerous, validate_fn
- ManagedTool.execute(): permission check → dangerous-approval gate →
  validation → retry loop with per-attempt timeout → metrics + logs.
  Never raises; always returns {ok, output, error, elapsed, attempts}.
- ToolFramework: register/execute/list + adopt_existing(registry)
- CATEGORY_MAP: spec taxonomy (git/docker/terminal/pdf/office/…) →
  agent permission categories (shell/file/code/web/media)

## Safety
- shell-category tools are marked dangerous ⇒ require approved=True
- Remote execution endpoint is OFF by default; enable with
  FLAG_TOOL_EXECUTE=true (uses Phase 1 feature flags)

## New endpoints (JWT)
GET /api/v1/tools/framework · POST /api/v1/tools/execute (flag-gated)

## Testing
tests/test_tools_phase5.py — 7 groups, all passing (permission denial,
approval gate, validation, retry-until-success, timeout, metrics, adoption).

## Limitations / future
Async tools run via thread wrapper; orchestrator→framework wiring for
fully autonomous runs lands in Phase 6/7 with checkpointing.
