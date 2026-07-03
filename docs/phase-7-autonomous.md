# Phase 7 — Autonomous Mode

## Purpose
Wires Phases 3–6 into one self-running loop (new `autonomous/` package):
plan independently → use tools independently → recover from failures →
retry automatically → verify outputs → improve outputs → generate reports.

## Components
- ExecutorBridge: node → matching Phase 5 managed tool (permissions +
  dangerous-approval respected) → LLM fallback on tool failure → never raises
- OutputImprover: heuristic critique → LLM revision rounds → accept best
- ReportGenerator: markdown run report (steps, confidence, failures, output)
- AutonomousMaya: create workflow → execute (parallel/retry/checkpoint) →
  improve combined output → report

## Endpoint (JWT + flag)
POST /api/v1/autonomous/run {goal, approve_dangerous?} — returns
run_id, status, confidence, improved output, and the full report.
DISABLED by default; enable with FLAG_AUTONOMOUS=true.
Dangerous (shell) tools additionally need approve_dangerous=true per call.

## Testing
tests/test_autonomous_phase7.py — 7 groups, all passing, incl. permission
gate on dangerous tools, LLM fallback, auto-recovery from a failing tool,
and a full end-to-end autonomous run.

## Limitations / future
Runs execute in-request; queueing long runs through the Phase 1 task
queue + live progress over WebSocket is a Phase 9/10 enhancement.
