# PDF 08 - API Bible

## 1. Base URL
- Local: http://localhost:8000/api/v1
- Cloud: https://maya-brain-api.supportinbox-maya.workers.dev

## 2. Authentication
POST /auth/login
POST /auth/register
POST /auth/refresh
POST /auth/logout

## 3. Agent API
POST /agent/run          # Run autonomous task
POST /agent/chat         # Simple chat
POST /agent/think        # Deep reasoning
GET  /agent/status       # Current agent status

## 4. Task API
GET  /tasks              # List all tasks
GET  /tasks/:id          # Get task details
POST /tasks              # Create task
PUT  /tasks/:id          # Update task
DELETE /tasks/:id        # Delete task

## 5. Memory API
GET  /memory             # List memories
GET  /memory/search?q=   # Search memories
POST /memory             # Add memory
DELETE /memory/:id       # Delete memory
GET  /memory/stats       # Memory statistics

## 6. Tool API
GET  /tools              # List all tools
POST /tools/:name/run    # Run a tool
PUT  /tools/:name        # Update tool config
GET  /tools/logs         # Tool execution logs

## 7. Workflow API
GET  /workflows          # List workflows
POST /workflows          # Create workflow
PUT  /workflows/:id      # Update workflow
DELETE /workflows/:id    # Delete workflow
POST /workflows/:id/run  # Run workflow

## 8. WebSocket
WS /ws/agent             # Real-time agent updates
WS /ws/task/:id          # Task execution stream

## 9. Response Format
{
  "success": true,
  "data": {},
  "error": null,
  "timestamp": "2025-01-15T10:00:00Z"
}
