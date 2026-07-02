# Phase 2 — Memory System

## Purpose
Adds the MAYA 3.0 spec memory capabilities ON TOP of the existing six
stores (short_term, long_term, episodic, semantic, vector, manager).
Nothing replaced; five new modules + three new API endpoints.

## New modules (memory/)
| Module | Provides |
|---|---|
| importance.py | 0–1 importance score: type weight + signals + recency + access |
| ranker.py | Retrieval ranking: 0.6×keyword overlap + 0.4×importance |
| lifecycle.py | TTL expiration per type + max-count cap; dry-run default; store injected |
| summarizer.py | Extractive digest offline; optional llm_fn for abstractive |
| layers.py | Spec's 4 layers (Conversation/User/Project/Semantic) routed onto existing stores |

## New endpoints (JWT required)
GET /api/v1/memory/rank?q=… · POST /api/v1/memory/cleanup?dry_run=true · GET /api/v1/memory/summary

## TTL defaults
chat 14d, episode 60d, general/task 90d; preference/identity/fact/user/project = forever.
Cleanup never deletes rows with unparseable timestamps (safety).

## Testing
tests/test_memory_phase2.py — 5 groups, all passing (offline, fake stores).

## Limitations / future
RAG uses existing vector_memory (Chroma) when available; embedding-based
ranking and LLM summarization wiring land with the Brain Engine (Phase 3).
