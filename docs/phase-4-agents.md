# Phase 4 — Multi-Agent System

## Purpose
Orchestrator + the 11 spec agents as a new `agents/` package, built on
the Phase 3 brain. Existing single-agent core untouched.

## Components
| Module | Provides |
|---|---|
| base | BaseAgent: skills, tool-category permissions (never bypassed), agent memory, health (success rate, degraded status) |
| registry | register/get/list, capability routing (name > skills > permission fit), health report |
| messaging | In-memory bus: send/receive/broadcast + history |
| roster | The 11 spec agents: planner, research, coding, reviewer, testing, security, deployment, documentation, database, frontend, backend |
| orchestrator | plan(goal): brain analysis → graph → assignments; run(goal, execute_fn): supervised parallel-ready loop with permission enforcement, confidence, reflection, replan signal |

## New endpoints (JWT)
GET /api/v1/agents · POST /api/v1/agents/orchestrate {goal} · GET /api/v1/agents/messages

## Safety
Permission checks happen in the orchestrator per node; violations fail
the node (never bypassed). All failures recorded — no silent failures.
Execution is injected (execute_fn), so nothing runs implicitly.

## Testing
tests/test_agents_phase4.py — 7 groups, all passing (incl. permission
denial and failure→replan paths).

## Limitations / future
run() wiring to the real executor/tools lands with Phase 5 tool
framework; LLM-powered agents activate by passing llm_fn.
