#!/bin/bash
# Maya 2.0 ULTRA - Docker Entrypoint
# Initializes and starts all services

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $*"; }

# Ensure directories exist
mkdir -p /opt/maya/logs /opt/maya/storage /opt/maya/workspace /opt/maya/backups
mkdir -p /opt/maya/storage/{browser_pool,sandbox,vector_store,cognitive_kernel,agent_graphs,multimodal,enhanced_memory,procedural_memory,streaming_sessions,self_improve}

# Fix permissions
chown -R maya:maya /opt/maya/logs /opt/maya/storage /opt/maya/workspace /opt/maya/backups 2>/dev/null || true

# Generate .env if not exists
if [[ ! -f /opt/maya/.env ]]; then
    log "Generating .env file..."
    cat > /opt/maya/.env <<EOF
# Maya 2.0 ULTRA - Auto-generated Configuration
# Generated at $(date)

# Security
SECRET_KEY=$(openssl rand -hex 32)
ADMIN_EMAIL=admin@localhost
ADMIN_PASSWORD=$(openssl rand -base64 32)

# CORS
CORS_ORIGINS=*

# Budget
BUDGET_USD=10.0
DEFAULT_USER_BUDGET_USD=5.0

# LLM Providers (SET YOUR KEYS)
NVIDIA_NIM_KEY=
GROQ_KEY=
GEMINI_KEY=
OPENROUTER_KEY=
NVIDIA_NIM_MODEL=meta/llama-3.3-70b-instruct
NVIDIA_NIM_TIMEOUT=180

# Vector Store
VECTOR_STORE_BACKEND=chroma
CHROMA_PERSIST_DIR=/opt/maya/storage/vector_store/chroma
SEMANTIC_EMBEDDINGS=false

# Browser Pool
BROWSER_POOL_SIZE=5
BROWSER_HEADLESS=true

# Sandbox
SANDBOX_RUNTIME=gvisor
SANDBOX_TIMEOUT=30
SANDBOX_MEMORY_MB=512

# Multi-Modal
VISION_MODEL=ViT-B-32
AUDIO_MODEL=base
DOCUMENT_MODEL=microsoft/layoutlmv3-base
ML_DEVICE=cpu

# Cognitive Architecture
COGNITION_ENABLED=true
COGNITION_AUTORUN=false
MAYA_UNIFIED_LOOP=true
MAYA_AUTO_RESUME=false
SELF_IMPROVE_ENABLED=false

# Features
MCP_ENABLED=false
APP_MONITOR_ENABLED=false
DEPLOY_PIPELINE_ENABLED=false
RESEARCH_ENGINE_ENABLED=false

# Logging
LOG_LEVEL=INFO
MAYA_LOG_DIR=/opt/maya/logs
EOF
    chown maya:maya /opt/maya/.env
    chmod 600 /opt/maya/.env
    warn "IMPORTANT: Edit /opt/maya/.env and add your API keys!"
fi

# Initialize ChromaDB if needed
if [[ ! -d /opt/maya/storage/vector_store/chroma/chroma.sqlite3 ]]; then
    log "Initializing ChromaDB..."
    sudo -u maya chroma run --host 0.0.0.0 --port 8000 --path /opt/maya/storage/vector_store/chroma &
    CHROMA_PID=$!
    sleep 5
    kill $CHROMA_PID 2>/dev/null || true
fi

# Run database migrations if needed
if [[ -f /opt/maya/migrate.py ]]; then
    log "Running database migrations..."
    cd /opt/maya && sudo -u maya /opt/venv/bin/python migrate.py
fi

# Create initial checkpoint
log "Creating initial checkpoint..."
cd /opt/maya && sudo -u maya /opt/venv/bin/python -c "
import asyncio, sys
sys.path.insert(0, '.')
from core.maya import Maya
m = Maya()
if hasattr(m, 'create_checkpoint'):
    cid = m.create_checkpoint({'initial': True})
    print(f'Initial checkpoint: {cid}')
" 2>/dev/null || warn "Checkpoint creation skipped"

log "Starting services with supervisord..."
exec supervisord -c /etc/supervisor/conf.d/maya.conf