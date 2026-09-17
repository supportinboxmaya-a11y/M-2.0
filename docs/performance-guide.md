# Performance Guide

## Frontend
- Bundle: < 200KB gzipped
- Lazy load all routes
- React Query staleTime: 30s
- Debounce search: 300ms

## Backend
- Simple queries: < 100ms
- LLM calls: < 30s
- Memory search: < 500ms
- Tool execution: < 60s

## Scaling
- Local: SQLite
- Team: PostgreSQL + Redis + Cloudflare
- Enterprise: PostgreSQL cluster + Kubernetes
