# Hybrid: Cloudflare Worker (gateway) + Oracle VPS (brain)
Frontend -> Worker -> (proxy /api/v1/*) -> Oracle VPS FastAPI (http://130.210.46.182:8000)
- Worker native routes (/run, /memory/*, /tasks) unchanged, API_SECRET auth.
- /api/v1/* proxied; backend JWT auth; per-IP rate limit at edge.
- WebSocket connects directly to Oracle VPS (VITE_WS_URL = ws://130.210.46.182:8000).
- Phase 0 fixes: removed stdlib-shadowing logging/, env key dual-read,
  CORS_ORIGINS config, default-credential warnings, /auth/register stub.
- Note: Oracle VPS runs 24/7; no cold start issues.
