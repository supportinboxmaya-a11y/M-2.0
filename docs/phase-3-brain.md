# Phase 3 — Brain Engine

## Purpose
Planning intelligence on top of the existing core (planner/verifier/
reasoner) as a new `brain/` package. Existing modules untouched.

## Modules
| Module | Provides |
|---|---|
| task_graph | Dependency graph: ready-set scheduling, cycle detection, fail→block propagation, retry/replan reset, progress |
| confidence | Step scoring (verification, error/success signals, retries) + weakest-link plan score + should_replan |
| reflection | Self-critique before returning results (empty/short/off-goal/placeholder checks; optional llm_fn) |
| goal_analyzer | Complexity classification, sub-goal split, suggested tool categories |
| brain_engine | Facade: analyze → build_graph (adapts existing planner step lists) → record (score+reflect+complete/fail) → plan_confidence |

## New endpoints (JWT)
GET /api/v1/brain/analyze?goal=… · POST /api/v1/brain/graph {steps:[…]}

## Design notes
depends_on uses list indexes (planner-friendly); omitted → sequential chain.
Parallel-ready: TaskGraph.ready() returns ALL runnable nodes.

## Testing
tests/test_brain_phase3.py — 6 groups, all passing.

## Limitations / future
LLM-powered decomposition & critique plug in via llm_fn (Phase 4 orchestrator
wires agents to graph nodes; executor adoption is incremental by design).
