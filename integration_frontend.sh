#!/usr/bin/env bash
# Frontend↔Backend integration check. Boots the real API, logs in, and
# exercises every endpoint group the frontend depends on.
set -u
cd "$(dirname "$0")"
PORT=8620
LOG=.integ_server.log

cleanup() { [ -n "${SRV_PID:-}" ] && kill -9 "$SRV_PID" 2>/dev/null; }
trap cleanup EXIT

./venv/bin/python -m uvicorn api:app --host 127.0.0.1 --port $PORT > "$LOG" 2>&1 &
SRV_PID=$!

echo "waiting for boot..."
up=0
for i in $(seq 1 45); do
  sleep 2
  if curl -sf -m 3 "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then up=1; echo "UP after ~$((i*2))s"; break; fi
done
if [ "$up" -ne 1 ]; then echo "SERVER FAILED TO BOOT"; tail -30 "$LOG"; exit 1; fi

EMAIL=$(grep '^ADMIN_EMAIL=' .env | cut -d= -f2-)
PASS=$(grep '^ADMIN_PASSWORD=' .env | cut -d= -f2-)
TOKEN=$(curl -s -X POST "http://127.0.0.1:$PORT/api/v1/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | ./venv/bin/python -c "import sys,json;print(json.load(sys.stdin).get('access_token',''))")
if [ -z "$TOKEN" ]; then echo "LOGIN FAILED"; exit 1; fi
AUTH="Authorization: Bearer $TOKEN"

pass=0; fail=0
check() { # name expected_code url [method] [data]
  local name=$1 want=$2 url=$3 method=${4:-GET} data=${5:-}
  local code
  if [ "$method" = POST ] || [ "$method" = PATCH ] || [ "$method" = PUT ]; then
    code=$(curl -s -o .integ_body -w '%{http_code}' -m 60 -X $method -H "$AUTH" -H 'Content-Type: application/json' ${data:+-d "$data"} "$url")
  else
    code=$(curl -s -o .integ_body -w '%{http_code}' -m 60 -H "$AUTH" "$url")
  fi
  if [ "$code" = "$want" ]; then echo "PASS [$code] $name"; pass=$((pass+1));
  else echo "FAIL [$code want $want] $name :: $(head -c 160 .integ_body)"; fail=$((fail+1)); fi
}

# Flag-gated capabilities: 200 when enabled, 503 is the designed OFF state.
check_flagged() { # name url
  local name=$1 url=$2 code
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 60 -H "$AUTH" "$url")
  if [ "$code" = "200" ] || [ "$code" = "503" ]; then echo "PASS [$code] $name"; pass=$((pass+1));
  else echo "FAIL [$code] $name"; fail=$((fail+1)); fi
}

B="http://127.0.0.1:$PORT"
check health                    200 "$B/health"
check auth/me                   200 "$B/api/v1/users/me"
check agent/status              200 "$B/api/v1/agent/status"
check kernel-status             200 "$B/api/v1/cognitive/kernel/status"
check kernel-audit              200 "$B/api/v1/cognitive/kernel/audit?limit=5"
check kernel-checkpoints        200 "$B/api/v1/cognitive/kernel/checkpoints"
check kernel-cp-create    200 "$B/api/v1/cognitive/kernel/checkpoint" POST '{}'
check wm-capacity               200 "$B/api/v1/cognitive/memory/working/capacity"
check wm-add             200 "$B/api/v1/cognitive/memory/working/add" POST '{"content":"integ probe","type":"fact"}'
check wm-search                 200 "$B/api/v1/cognitive/memory/working/search?q=integ"
check goals-list                200 "$B/api/v1/cognitive/goals"
check goals-incomplete          200 "$B/api/v1/cognitive/kernel/goals/incomplete"
check resume-scan         200 "$B/api/v1/cognitive/kernel/resume-incomplete" POST '{"plan_proposals":true,"max_goals":3}'
check knowledge-stats           200 "$B/api/v1/cognitive/knowledge/stats"
check knowledge-query           200 "$B/api/v1/cognitive/knowledge/query?q=docker"
check beliefs                   200 "$B/api/v1/cognitive/beliefs"
check learn             200 "$B/api/v1/cognitive/knowledge/learn" POST '{"proposition":"integration probe belief","confidence":0.6}'
check capabilities-list         200 "$B/api/v1/capabilities?limit=10"
check capabilities-stats        200 "$B/api/v1/capabilities/stats"
check caps-search               200 "$B/api/v1/capabilities/search?q=code"
check episodic                  200 "$B/api/v1/cognitive/memory/episodic?limit=5"
check episodic-stats            200 "$B/api/v1/cognitive/memory/episodic/stats"
check procedural                200 "$B/api/v1/cognitive/memory/procedural?limit=10"
check procedural-stats          200 "$B/api/v1/cognitive/memory/procedural/stats"
check meta-status               200 "$B/api/v1/cognitive/metacognitive/status"
check meta-events               200 "$B/api/v1/cognitive/metacognitive/events?limit=5"
check society-status            200 "$B/api/v1/cognitive/society/status"
check society-agents            200 "$B/api/v1/cognitive/society/agents"
check bb-query                  200 "$B/api/v1/cognitive/society/blackboard/query?pattern=x"
check mcp-status                200 "$B/api/v1/mcp/status"
check self-profile              200 "$B/api/v1/cognitive/self/profile"
check self-assess               200 "$B/api/v1/cognitive/self/assess?q=deploy%20a%20site"
check selfimprove-status        200 "$B/api/v1/cognitive/self-improve/status"
check core-status               200 "$B/api/v1/maya/core/status"
check core-identity             200 "$B/api/v1/maya/core/identity"
check core-models               200 "$B/api/v1/maya/core/models"
check core-checkpoints          200 "$B/api/v1/maya/core/checkpoints"
check core-audit                200 "$B/api/v1/maya/core/audit?limit=5"
check providers                 200 "$B/api/v1/providers"
check llm-stats                 200 "$B/api/v1/llm/stats"
check tasks                     200 "$B/api/v1/tasks?limit=10"
check memory                    200 "$B/api/v1/memory?limit=5"
check tools                     200 "$B/api/v1/tools"
check rag-stats                 200 "$B/api/v1/rag/stats"
check approval-mode             200 "$B/api/v1/approval/mode"
check approvals                 200 "$B/api/v1/approvals"
check cognition-status          200 "$B/api/v1/cognitive/status"
check missions                  200 "$B/api/v1/cognitive/missions"
check_flagged research-reports  "$B/api/v1/research/reports"
check publish-history           200 "$B/api/v1/publish/history"
check registry                  200 "$B/api/v1/hosting/registry"
check flags                     200 "$B/api/v1/flags"
check notifications             200 "$B/api/v1/notifications?limit=5"
check workspaces                200 "$B/api/v1/workspaces"
check workspace-memory          200 "$B/api/v1/workspace/memory?workspace=default&q="
check workspace-stats           200 "$B/api/v1/workspace/stats?workspace=default"
check learning-prompts          200 "$B/api/v1/learning/prompts"
check tools-framework           200 "$B/api/v1/tools/framework"

# goal create + detail + patch (no execution)
GID=$(curl -s -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"description":"integ lifecycle goal","priority":50}' "$B/api/v1/cognitive/goals" \
  | ./venv/bin/python -c "import sys,json;print(json.load(sys.stdin).get('goal_id',''))")
if [ -n "$GID" ]; then
  check "goal-detail($GID)"   200 "$B/api/v1/cognitive/goals/$GID"
  check "goal-patch($GID)"    200 "$B/api/v1/cognitive/goals/$GID" PATCH '{"status":"abandoned"}'
else
  echo "FAIL goal-create (no id returned)"; fail=$((fail+1))
fi

# static assets used by the SPA
for p in "/" "/js/app.js" "/js/api.js" "/js/BaseView.js" "/css/cognitive.css" \
         "/js/views/LoginView.js" "/js/views/KernelView.js" "/js/views/GoalsView.js" \
         "/js/views/SkillsView.js" "/js/views/SelfModelView.js" "/js/views/CapabilitiesView.js" \
         "/js/views/MetacognitionView.js"          "/js/views/SocietyView.js" "/js/views/MCPView.js" \
         "/js/views/CoreLoopView.js" "/js/views/ResearchView.js"; do
  code=$(curl -s -o /dev/null -w '%{http_code}' -m 10 "$B$p")
  if [ "$code" = "200" ]; then echo "PASS [200] static $p"; pass=$((pass+1));
  else echo "FAIL [$code] static $p"; fail=$((fail+1)); fi
done

# memory lifecycle: add → update → delete
MID=$(curl -s -X POST -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"content":"integ probe memory","type":"general"}' "$B/api/v1/memory" | ./venv/bin/python -c "import sys,json;print(json.load(sys.stdin).get('id',''))")
if [ -n "$MID" ]; then
  # find the real DB id for the probe memory via search
  RID=$(curl -s -H "$AUTH" "$B/api/v1/memory/search?q=integ%20probe&limit=1" | ./venv/bin/python -c "
import sys,json
d=json.load(sys.stdin)
print(d[0]['id'] if isinstance(d,list) and d else '')")
  if [ -n "$RID" ]; then
    check "memory-update" 200 "$B/api/v1/memory/$RID" PUT '{"content":"integ probe memory v2"}' || true
    code=$(curl -s -o /dev/null -w '%{http_code}' -X PUT -H "$AUTH" -H 'Content-Type: application/json' -d '{"content":"integ probe memory v2"}' "$B/api/v1/memory/$RID")
    if [ "$code" = 200 ]; then echo "PASS [$code] memory-put"; pass=$((pass+1)); else echo "FAIL [$code] memory-put"; fail=$((fail+1)); fi
    curl -s -X DELETE -H "$AUTH" "$B/api/v1/memory/$RID" > /dev/null
  fi
fi

echo ""
echo "RESULT: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
