# Phase 6 — Workflow Engine

## Purpose
The spec pipeline (Goal → Planning → Breakdown → Agent Assignment →
Tool Selection → Execution → Verification → Retry → Completion) as a
new `workflows/` package on the Phase 4 orchestrator. Existing
core/workflow_engine.py untouched.

## Capabilities
- **Parallel**: every round runs ALL ready nodes concurrently (asyncio.gather)
- **Conditional**: per-step predicates (conditions map) can skip nodes
- **Dependencies**: from the Phase 3 task graph
- **Cancellation**: run.cancel() stops before the next round; state saved
- **Checkpoint**: state persisted after every round (Memory or File store)
- **Resume**: WorkflowRun.from_state rebuilds the graph; interrupted
  'running' nodes are safely reset to pending; completed work preserved
- **Retry stage**: failed nodes get retry_failed extra chances after the
  main pass (verification → retry → completion)

## New endpoints (JWT)
POST /api/v1/workflows/plan · GET /api/v1/workflows/runs ·
GET /api/v1/workflows/runs/{id} · POST /api/v1/workflows/runs/{id}/cancel
(Execution endpoint intentionally deferred: server-side autonomous runs
arrive with Phase 7 alongside the approval flow.)

## Testing
tests/test_workflows_phase6.py — 6 groups, all passing, including a
measured parallelism check (3×0.15s tasks finish in ~0.15s) and a
crash→resume→complete scenario.

## Limitations / future
Sync execute_fn runs via asyncio.to_thread; distributed checkpoints
(Redis/D1) are a Phase 9 option.
