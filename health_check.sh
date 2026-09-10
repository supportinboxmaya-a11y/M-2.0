#!/bin/bash
# Health check for monitoring

check_service() {
    local name=$1
    local url=$2
    local expected=${3:-200}
    
    if curl -sf -o /dev/null -w "%{http_code}" "$url" | grep -q "^$expected$"; then
        echo "✅ $name: OK"
        return 0
    else
        echo "❌ $name: FAILED"
        return 1
    fi
}

echo "=== Maya Health Check ==="
echo "Time: $(date)"
echo ""

# Core services
check_service "Maya API" "http://localhost:8000/health" 200
check_service "ChromaDB" "http://localhost:8001/api/v2/heartbeat" 200
check_service "Qdrant" "http://localhost:6333/" 200

# System resources
echo ""
echo "=== System Resources ==="
echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')% used"
echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
echo "Disk: $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
echo "Docker: $(docker ps -q | wc -l) containers running"

# Maya specific
if curl -sf http://localhost:8000/api/v1/agent/status >/dev/null 2>&1; then
    echo "✅ Maya API responding"
else
    echo "❌ Maya API not responding (requires auth)"
fi
