# Hybrid: Cloudflare Worker (gateway) + Render (brain)
Frontend -> Worker -> (proxy /api/v1/*) -> Render FastAPI (https://m-2-0.onrender.com)
- Worker native routes (/run, /memory/*, /tasks) unchanged, API_SECRET auth.
- /api/v1/* proxied; backend JWT auth; per-IP rate limit at edge.
- WebSocket connects directly to Render (VITE_WS_URL).
- Phase 0 fixes: removed stdlib-shadowing logging/, env key dual-read,
  CORS_ORIGINS config, default-credential warnings, /auth/register stub.
- Note: Render free tier cold start ~50s; worker returns 502 until awake.
