# Phase 10 — Learning Layer

## Purpose
Maya now learns from every run: feedback learning, workflow learning,
project knowledge retention, prompt optimization, memory compression,
task history, experience replay — new `learning/` package.

## Components
- FeedbackStore: ratings (+1/0/-1) + comments; satisfaction stats;
  lessons() surfaces recent negative feedback
- ExperienceReplay: episodes (goal/steps/outcome/confidence);
  similar() recalls related past work; success_rate(); history()
- PromptOptimizer: per-task variant tracking, Laplace-smoothed scores,
  epsilon-greedy choose(), improve_from_feedback() hardening
- MemoryCompressor: folds old memories into digests via the Phase 2
  summarizer (dry-run default; >50% typical space saving)
- Autonomous runs auto-feed experience replay (workflow learning)

## New endpoints (JWT)
POST /api/v1/learning/feedback · GET /api/v1/learning/stats ·
GET /api/v1/learning/experience?goal=… · POST /api/v1/learning/compress

## Testing
tests/test_learning_phase10.py — 4 groups, all passing.
