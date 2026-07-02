# Phase 1 — Foundation Hardening

## Purpose
Production infrastructure primitives as a new `infrastructure/` package.
Zero changes to existing modules; api.py gains an appended, soft-failing
integration block (the API boots even if the package is broken).

## Modules (all stdlib-only, thread-safe, independently testable)
| Module | Provides |
|---|---|
| config_manager | Typed env config + runtime overrides (`config.get_int/bool/float`) |
| secrets | Single gate for credentials, dual naming, masked logging |
| metrics | Counters + latency p95/avg, `/api/v1/metrics` |
| retry | `@retry()` decorator, sync+async, exp backoff + jitter |
| cache | `TTLCache` with max-size eviction + hit/miss stats |
| rate_limiter | Token bucket per key; HTTP layer: `RATE_LIMIT_PER_MIN` (default 120) |
| task_queue | Background asyncio queue, `/api/v1/queue/status` |
| feature_flags | `FLAG_<NAME>=true` env flags, `/api/v1/flags` |
| exceptions | `MayaError` + one global JSON exception handler |

## Configuration
`RATE_LIMIT_PER_MIN`, `TASK_WORKERS`, `FLAG_*` — all optional with safe defaults.

## Testing
`tests/test_infrastructure.py` — 9 test groups, all passing.

## Known limitations / future
Metrics are in-memory (reset on restart); Redis backend is a Phase 9 option.
Existing modules (router, tools) adopt `@retry`/cache incrementally in later phases.
