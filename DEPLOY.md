# Maya 2.0 ULTRA — Deployment Guide

Two services, deployed separately:

| Service  | Repo                | Host              | URL                                  |
|----------|---------------------|-------------------|--------------------------------------|
| Backend  | M-2.0               | Oracle VPS        | http://130.210.46.182:8000           |
| Frontend | M-2.0 (root)        | Vercel            | (your Vercel domain)                 |
| API Gateway | M-2.0            | Cloudflare Workers| (your *.workers.dev domain)          |

## 1. Backend (Oracle VPS)

The backend runs directly on the Oracle VPS (Ubuntu 24.04) at **130.210.46.182:8000**.

Deploy by:
1. SSH to the VPS: `ssh root@130.210.46.182 -p 20045`
2. Clone/pull the repo: `git clone https://github.com/supportinboxmaya-a11y/M-2.0.git` or `cd M-2.0 && git pull`
3. Install dependencies: `cd M-2.0 && pip install -r requirements.txt && playwright install --with-deps chromium`
4. Copy `.env.example` to `.env` and fill in required secrets
5. Run the service: `sudo systemctl start maya-api` (using `maya-api.service`) or run directly: `python -m uvicorn api:app --host 0.0.0.0 --port 8000`

Required environment variables (in `.env` on the VPS):

| Variable            | Purpose                                          |
|---------------------|--------------------------------------------------|
| `GROQ_KEY`          | LLM calls + **voice transcription (Whisper)**    |
| `NVIDIA_NIM_KEY`    | NVIDIA NIM API (primary brain)                   |
| `GEMINI_KEY`        | Gemini provider (optional but recommended)       |
| `OPENROUTER_KEY`    | OpenRouter fallback (free tier)                  |
| `ADMIN_EMAIL`       | Login email                                      |
| `ADMIN_PASSWORD`    | Login password                                   |
| `SECRET_KEY`        | JWT signing secret (set a long random string)    |
| `CORS_ORIGINS`      | `*` or your Vercel frontend domain               |
| `PORT`              | `8000`                                           |
| `TELEGRAM_BOT_TOKEN`| For approvals & notifications                    |
| `TELEGRAM_CHAT_ID`  | For approvals & notifications                    |

### Service Management
- **Start**: `sudo systemctl start maya-api`
- **Stop**: `sudo systemctl stop maya-api`
- **Restart**: `sudo systemctl restart maya-api`
- **Status**: `sudo systemctl status maya-api`
- **Logs**: `sudo journalctl -u maya-api -f`

### New endpoints
- `POST /api/v1/voice/transcribe` — real Groq Whisper transcription (base64/data-URL audio)
- `GET/POST/PUT/DELETE /api/v1/webhooks` — outbound webhooks, persisted in `storage/webhooks.json`
  - Fired automatically on `task.started`, `task.done`, `task.failed`
  - Payload: `{ "event": "...", "data": { ...task } }`
- `WS /ws/agent?token=<jwt>` — token is now validated when provided

### Fixes in this release
- `/auth/register` was registered 9× (duplicates removed)
- `/vision/analyze` crashed (500) when Maya was not initialized → now returns 503
- `/analytics/daily` ignored the `days` parameter → now filtered correctly

## 2. Frontend (Vercel)

Push this repo to GitHub; Vercel auto-deploys from **root `vercel.json`** (not `frontend/vercel.json`).

The root `vercel.json` rewrites `/api/*`, `/ws/*`, `/health/*` to `http://130.210.46.182:8000`.

If you override env vars in the Vercel dashboard, they must be:
```
VITE_AGENT_URL=http://130.210.46.182:8000/api/v1
VITE_WS_URL=ws://130.210.46.182:8000
VITE_API_URL=https://<your-worker>.workers.dev
```

> ⚠️ `VITE_WS_URL` must point at the **Oracle VPS backend** (port 8000). Previously it pointed at Cloudflare Worker which has no `/ws/agent` — live notifications never worked in production because of this.

## 3. API Gateway (Cloudflare Workers) — Optional

The Cloudflare Worker (`wrangler.toml`) acts as a rate-limited gateway proxying `/api/v1/*` to the Oracle VPS backend. It's optional — the frontend can connect directly to the VPS via Vercel rewrites.

Deploy:
1. `npm install -g wrangler`
2. `wrangler login`
3. `wrangler deploy` (uses `wrangler.toml` with `BACKEND_URL = "http://130.210.46.182:8000"`)

Required secrets in Cloudflare dashboard:
- `CF_API_TOKEN` (for GitHub Actions deploy)
- `CF_ACCOUNT_ID`

## 4. Post-deploy manual test checklist

1. **Login** with admin credentials → lands on Dashboard
2. **Logout** (sidebar) → returns to /auth, refresh does not restore session
3. Dashboard: send a **chat message** → reply appears
4. Dashboard: **attach an image** → vision analysis reply appears
5. Dashboard: **attach a .txt file** → agent summarizes the content
6. Chat/Tasks: create a task → **notification bell badge increments** (proves WebSocket works)
7. Top bar **cost meter** updates after the task completes
8. Memory: add / search / delete a memory
9. Tools: toggle a tool on/off, refresh page → state persists (backend-side)
10. Workflow: **create** a workflow via the new form → run it → task appears
11. Agents page: "Plan (no execution)" returns an orchestration plan
12. Agents page: "Autonomous Run" works after `FLAG_AUTONOMOUS=true`
13. Learning: submit feedback with a star rating → stats update
14. Integrations: **add a webhook** (e.g. a webhook.site URL) → run a task → the URL receives a POST
15. Voice Studio: record audio → transcription appears (requires `GROQ_KEY`)
16. Settings: change values, Save, refresh → values restored; switch language to বাংলা → sidebar translates instantly and persists
17. Security: audit log shows admin actions (create org/key)
18. Backend Overview: live metrics / flags / queue panels populate

## Known limitations
- App-connection toggles on the Integrations page (GitHub/Slack/…) are device-local preferences; no OAuth integrations exist on the backend yet.
- Only the dark theme exists (the theme selector reflects this honestly).
- In-memory stores (`tasks_db`, `workflows_db`, `backups_db`) reset on backend restart by design; webhooks persist to disk.
- Oracle VPS backend must be running for frontend to work (no Render fallback).
