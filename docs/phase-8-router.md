# Phase 8 — Multi-Model Router+

## Purpose
The existing LLMRouter (6 providers) already covers routing basics; this
phase adds the remaining spec items as an ADDITIVE layer
(`llm/router_plus.py` + `llm/providers/openrouter.py`). router.py untouched.

## Components
- ProviderStats: latency EMA + rolling error rate per provider
- SmartSelector: strategy ordering — cost | latency | quality | balanced
  (quality-per-dollar); providers over 50% error rate are skipped
  (unless nothing else is left — never returns empty)
- RouterPlus.call(): per-provider retries → fallback chain → stats;
  never raises, returns {ok, provider, output|error, tried}
- OpenRouterProvider: OpenAI-compatible aggregator; dual env keys
  (OPENROUTER_KEY / OPENROUTER_API_KEY); injectable http for tests

## New endpoints (JWT)
GET /api/v1/llm/stats · GET /api/v1/llm/strategy?strategy=cost

## Testing
tests/test_router_phase8.py — 5 groups, all passing (EMA math, all four
strategies, unhealthy-skip, retry→fallback chain, OpenRouter payload).

## Limitations / future
Wiring RouterPlus as the default path inside chat endpoints is a
follow-up once live stats accumulate; token-level cost accounting joins
the Phase 1 metrics in Phase 10.
