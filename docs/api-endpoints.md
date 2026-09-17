# API Endpoints

## Base URL
- Local: http://localhost:8000/api/v1
- Cloud: https://maya-brain-api.supportinbox-maya.workers.dev

## Auth
- POST /auth/login
- POST /auth/register
- POST /auth/refresh
- POST /auth/logout

## Agent
- POST /agent/run
- POST /agent/chat
- POST /agent/think
- GET /agent/status

## Tasks
- GET /tasks
- GET /tasks/:id
- POST /tasks
- DELETE /tasks/:id

## Memory
- GET /memory
- GET /memory/search?q=
- POST /memory
- DELETE /memory/:id
- GET /memory/stats

## Tools
- GET /tools
- POST /tools/:name/run
- PUT /tools/:name
- GET /tools/logs

## Workflows
- GET /workflows
- POST /workflows
- PUT /workflows/:id
- DELETE /workflows/:id
- POST /workflows/:id/run

## WebSocket
- WS /ws/agent
- Events: agent:status, task:step, task:done, task:failed, cost:update
