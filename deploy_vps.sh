#!/bin/bash
# =============================================================================
# Maya 2.0 ULTRA - Oracle ARM64 VPS Deployment Script
# =============================================================================
# Deploys the complete AGI/Jarvis-class autonomous agent system.
# Run as root on a fresh Ubuntu 24.04 ARM64 VPS.
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $*"; }
warn() { echo -e "${YELLOW}[$(date '+%H:%M:%S')] WARNING:${NC} $*"; }
error() { echo -e "${RED}[$(date '+%H:%M:%S')] ERROR:${NC} $*"; }
info() { echo -e "${BLUE}[$(date '+%H:%M:%S')] INFO:${NC} $*"; }

# Configuration
MAYA_USER="maya"
MAYA_DIR="/opt/maya"
MAYA_REPO="https://github.com/your-org/maya-2.0.git"  # Update with your repo
MAYA_BRANCH="main"
PYTHON_VERSION="3.11"
NODE_VERSION="20"

# Feature flags (set to true to enable)
ENABLE_BROWSER_POOL="${ENABLE_BROWSER_POOL:-true}"
ENABLE_SANDBOX="${ENABLE_SANDBOX:-true}"
ENABLE_VECTOR_STORE="${ENABLE_VECTOR_STORE:-true}"
ENABLE_MULTIMODAL="${ENABLE_MULTIMODAL:-true}"
ENABLE_ENHANCED_MEMORY="${ENABLE_ENHANCED_MEMORY:-true}"
ENABLE_AGENT_GRAPHS="${ENABLE_AGENT_GRAPHS:-true}"

# External services
QDRANT_HOST="${QDRANT_HOST:-localhost}"
QDRANT_PORT="${QDRANT_PORT:-6333}"
CHROMA_PERSIST_DIR="${CHROMA_PERSIST_DIR:-/opt/maya/storage/vector_store/chroma}"

# =============================================================================
# Pre-flight checks
# =============================================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

check_arch() {
    local arch=$(uname -m)
    if [[ "$arch" != "aarch64" ]]; then
        warn "This script is optimized for ARM64 (aarch64). Current: $arch"
    fi
}

check_os() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot determine OS version"
        exit 1
    fi
    source /etc/os-release
    if [[ "$ID" != "ubuntu" ]] || [[ "$VERSION_ID" != "24.04" ]]; then
        warn "Tested on Ubuntu 24.04. Current: $PRETTY_NAME"
    fi
}

# =============================================================================
# System preparation
# =============================================================================

update_system() {
    log "Updating system packages..."
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y \
        curl wget git unzip jq \
        build-essential pkg-config \
        python3-dev python3-venv python3-pip \
        nodejs npm \
        docker.io docker-compose \
        nginx certbot python3-certbot-nginx \
        postgresql-client redis-tools \
        htop iotop nethogs \
        fail2ban ufw \
        software-properties-common \
        apt-transport-https ca-certificates gnupg lsb-release
}

create_maya_user() {
    log "Creating maya user..."
    if ! id "$MAYA_USER" &>/dev/null; then
        useradd -r -m -d "$MAYA_DIR" -s /bin/bash "$MAYA_USER"
        usermod -aG docker "$MAYA_USER"
    fi
}

setup_directories() {
    log "Setting up directories..."
    mkdir -p "$MAYA_DIR"/{storage,logs,workspace,config,backups}
    mkdir -p "$MAYA_DIR/storage"/{browser_pool,sandbox,vector_store,cognitive_kernel,agent_graphs,multimodal,enhanced_memory,procedural_memory,streaming_sessions,self_improve}
    chown -R "$MAYA_USER:$MAYA_USER" "$MAYA_DIR"
    chmod 750 "$MAYA_DIR"
}

install_python() {
    log "Installing Python $PYTHON_VERSION..."
    add-apt-repository -y ppa:deadsnakes/ppa
    apt-get update -y
    apt-get install -y python${PYTHON_VERSION} python${PYTHON_VERSION}-venv python${PYTHON_VERSION}-dev
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1
}

install_node() {
    log "Installing Node.js $NODE_VERSION..."
    curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
    apt-get install -y nodejs
    npm install -g pm2 pnpm
}

install_docker() {
    log "Configuring Docker..."
    systemctl enable docker
    systemctl start docker
    # Enable buildx for multi-arch
    docker run --rm --privileged tonistiigi/binfmt --install all
}

# =============================================================================
# gVisor (runsc) for sandboxing
# =============================================================================

install_gvisor() {
    if [[ "$ENABLE_SANDBOX" != "true" ]]; then
        info "Sandbox disabled, skipping gVisor"
        return
    fi
    
    log "Installing gVisor (runsc)..."
    local RUNSC_VERSION="2024-01-15"
    local ARCH="arm64"
    
    curl -fsSL "https://storage.googleapis.com/gvisor/releases/release/${RUNSC_VERSION}/runsc-${ARCH}.deb" -o /tmp/runsc.deb
    dpkg -i /tmp/runsc.deb || apt-get install -f -y
    rm /tmp/runsc.deb
    
    # Configure runsc for rootless
    runsc install --rootless
    
    # Verify
    runsc --version
    log "gVisor installed successfully"
}

# =============================================================================
# ChromaDB / Qdrant for vector storage
# =============================================================================

install_chromadb() {
    if [[ "$ENABLE_VECTOR_STORE" != "true" ]]; then
        info "Vector store disabled, skipping ChromaDB"
        return
    fi
    
    log "Installing ChromaDB..."
    docker run -d \
        --name chromadb \
        --restart unless-stopped \
        -p 8000:8000 \
        -v "$CHROMA_PERSIST_DIR:/chroma/chroma" \
        -e CHROMA_SERVER_HOST=0.0.0.0 \
        -e CHROMA_SERVER_HTTP_PORT=8000 \
        -e ANONYMIZED_TELEMETRY=False \
        chromadb/chroma:latest
    
    # Wait for startup
    sleep 5
    curl -f http://localhost:8000/api/v1/heartbeat || warn "ChromaDB health check failed"
}

install_qdrant() {
    if [[ "$ENABLE_VECTOR_STORE" != "true" ]]; then
        return
    fi
    
    log "Installing Qdrant..."
    docker run -d \
        --name qdrant \
        --restart unless-stopped \
        -p 6333:6333 -p 6334:6334 \
        -v "$MAYA_DIR/storage/qdrant:/qdrant/storage" \
        qdrant/qdrant:latest
    
    sleep 5
    curl -f http://localhost:6333/health || warn "Qdrant health check failed"
}

# =============================================================================
# Playwright browsers for browser pool
# =============================================================================

install_playwright() {
    if [[ "$ENABLE_BROWSER_POOL" != "true" ]]; then
        info "Browser pool disabled, skipping Playwright"
        return
    fi
    
    log "Installing Playwright browsers..."
    # Run as maya user
    sudo -u "$MAYA_USER" bash -c "
        cd $MAYA_DIR
        python -m playwright install chromium
        python -m playwright install-deps chromium
    "
}

# =============================================================================
# ML models for multi-modal
# =============================================================================

install_ml_models() {
    if [[ "$ENABLE_MULTIMODAL" != "true" ]]; then
        info "Multi-modal disabled, skipping ML models"
        return
    fi
    
    log "Pre-downloading ML models..."
    sudo -u "$MAYA_USER" bash -c "
        cd $MAYA_DIR
        python -c '
import os
os.environ[\"HF_HOME\"] = \"$MAYA_DIR/storage/multimodal/models\"
os.environ[\"TRANSFORMERS_CACHE\"] = \"$MAYA_DIR/storage/multimodal/models\"

# Vision (CLIP)
from open_clip import create_model_and_transforms
create_model_and_transforms(\"ViT-B-32\", pretrained=\"openai\", device=\"cpu\")

# Audio (Whisper)
from faster_whisper import WhisperModel
WhisperModel(\"base\", device=\"cpu\", compute_type=\"int8\")

# Document (LayoutLM)
from transformers import LayoutLMv3Processor, LayoutLMv3ForTokenClassification
LayoutLMv3Processor.from_pretrained(\"microsoft/layoutlmv3-base\")
LayoutLMv3ForTokenClassification.from_pretrained(\"microsoft/layoutlmv3-base\")

print(\"Models downloaded successfully\")
'
    "
}

# =============================================================================
# Redis for caching/sessions
# =============================================================================

install_redis() {
    log "Installing Redis..."
    apt-get install -y redis-server
    sed -i 's/^bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory <bytes>/maxmemory 512mb/' /etc/redis/redis.conf
    sed -i 's/^# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/' /etc/redis/redis.conf
    systemctl enable redis-server
    systemctl restart redis-server
}

# =============================================================================
# PostgreSQL for Supabase (optional)
# =============================================================================

install_postgresql() {
    log "Installing PostgreSQL client..."
    apt-get install -y postgresql-client-16
    # Full PostgreSQL server if needed locally:
    # apt-get install -y postgresql-16 postgresql-contrib-16
}

# =============================================================================
# Maya application deployment
# =============================================================================

deploy_maya() {
    log "Deploying Maya application..."
    
    # Clone or update repository
    if [[ -d "$MAYA_DIR/.git" ]]; then
        log "Updating existing repository..."
        sudo -u "$MAYA_USER" bash -c "
            cd $MAYA_DIR
            git fetch origin
            git reset --hard origin/$MAYA_BRANCH
        "
    else
        log "Cloning repository..."
        sudo -u "$MAYA_USER" bash -c "
            git clone -b $MAYA_BRANCH $MAYA_REPO $MAYA_DIR
        "
    fi
    
    # Create virtual environment
    log "Creating Python virtual environment..."
    sudo -u "$MAYA_USER" bash -c "
        cd $MAYA_DIR
        python -m venv venv
        source venv/bin/activate
        pip install --upgrade pip setuptools wheel
        pip install -r requirements.txt
        
        # Extra dependencies for new features
        pip install \
            open_clip_torch \
            faster-whisper \
            transformers torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu \
            chromadb qdrant-client \
            rank_bm25 \
            langgraph \
            sentence-transformers \
            playwright \
            aiofiles \
            python-multipart
    "
    
    # Install Playwright browsers
    if [[ "$ENABLE_BROWSER_POOL" == "true" ]]; then
        sudo -u "$MAYA_USER" bash -c "
            cd $MAYA_DIR
            source venv/bin/activate
            playwright install chromium
            playwright install-deps chromium
        "
    fi
    
    # Build frontend
    log "Building frontend..."
    sudo -u "$MAYA_USER" bash -c "
        cd $MAYA_DIR/frontend
        npm ci
        npm run build
    "
}

# =============================================================================
# Configuration
# =============================================================================

create_env_file() {
    log "Creating .env configuration..."
    cat > "$MAYA_DIR/.env" <<EOF
# =============================================================================
# Maya 2.0 ULTRA - Production Configuration
# =============================================================================

# Security (CHANGE THESE IN PRODUCTION!)
SECRET_KEY=$(openssl rand -hex 32)
ADMIN_EMAIL=admin@yourdomain.com
ADMIN_PASSWORD=$(openssl rand -base64 32)

# JWT
JWT_ALGORITHM=HS256
JWT_EXPIRATION_DAYS=7

# CORS
CORS_ORIGINS=https://yourdomain.com,https://www.yourdomain.com

# Budget
BUDGET_USD=10.0
DEFAULT_USER_BUDGET_USD=5.0

# =============================================================================
# LLM Providers (ADD YOUR KEYS)
# =============================================================================
NVIDIA_NIM_KEY=
GROQ_KEY=
GEMINI_KEY=
OPENROUTER_KEY=
NVIDIA_NIM_MODEL=meta/llama-3.3-70b-instruct
NVIDIA_NIM_TIMEOUT=180

# =============================================================================
# Vector Store
# =============================================================================
VECTOR_STORE_BACKEND=chroma
CHROMA_PERSIST_DIR=$CHROMA_PERSIST_DIR
SEMANTIC_EMBEDDINGS=false

# Qdrant (if using)
QDRANT_HOST=$QDRANT_HOST
QDRANT_PORT=$QDRANT_PORT

# =============================================================================
# Browser Pool
# =============================================================================
BROWSER_POOL_SIZE=5
BROWSER_HEADLESS=true

# =============================================================================
# Sandbox
# =============================================================================
SANDBOX_RUNTIME=gvisor
SANDBOX_TIMEOUT=30
SANDBOX_MEMORY_MB=512

# =============================================================================
# Multi-Modal
# =============================================================================
VISION_MODEL=ViT-B-32
AUDIO_MODEL=base
DOCUMENT_MODEL=microsoft/layoutlmv3-base
ML_DEVICE=cpu

# =============================================================================
# Enhanced Memory
# =============================================================================
WM_CAPACITY=7

# =============================================================================
# Cognitive Architecture
# =============================================================================
COGNITION_ENABLED=true
COGNITION_AUTORUN=false
MAYA_UNIFIED_LOOP=true
MAYA_AUTO_RESUME=false
SELF_IMPROVE_ENABLED=false

# =============================================================================
# MCP (Model Context Protocol)
# =============================================================================
MCP_ENABLED=false

# =============================================================================
# App Monitor / Deploy Pipeline
# =============================================================================
APP_MONITOR_ENABLED=false
DEPLOY_PIPELINE_ENABLED=false

# =============================================================================
# Research Engine
# =============================================================================
RESEARCH_ENGINE_ENABLED=false

# =============================================================================
# VPS / Remote Deploy
# =============================================================================
VPS_HOST=
VPS_PORT=22
VPS_USER=root
VPS_PASSWORD=
VPS_SSH_KEY_PATH=

# =============================================================================
# Notifications
# =============================================================================
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=
WEBHOOK_SLACK_URL=
WEBHOOK_DISCORD_URL=
WEBHOOK_GENERIC_URL=

# =============================================================================
# Device Bridge
# =============================================================================
FCM_CREDENTIALS_PATH=

# =============================================================================
# API Keys
# =============================================================================
PROVISIONER_EMAIL=
PROVISIONER_NAME=

# =============================================================================
# Logging
# =============================================================================
LOG_LEVEL=INFO
MAYA_LOG_DIR=$MAYA_DIR/logs
EOF
    
    chown "$MAYA_USER:$MAYA_USER" "$MAYA_DIR/.env"
    chmod 600 "$MAYA_DIR/.env"
    warn "IMPORTANT: Edit $MAYA_DIR/.env and add your API keys!"
}

create_systemd_service() {
    log "Creating systemd service..."
    cat > /etc/systemd/system/maya.service <<EOF
[Unit]
Description=Maya 2.0 ULTRA - Autonomous AI Agent
After=network.target docker.service redis-server.service chromadb.service qdrant.service
Wants=docker.service redis-server.service
Requires=network.target

[Service]
Type=simple
User=$MAYA_USER
Group=$MAYA_USER
WorkingDirectory=$MAYA_DIR
Environment=PATH=$MAYA_DIR/venv/bin:/usr/local/bin:/usr/bin:/bin
EnvironmentFile=$MAYA_DIR/.env
ExecStart=$MAYA_DIR/venv/bin/python api.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=maya

# Resource limits
LimitNOFILE=65536
LimitNPROC=32768
MemoryMax=4G
CPUQuota=200%

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$MAYA_DIR

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable maya
}

create_nginx_config() {
    log "Creating Nginx configuration..."
    cat > /etc/nginx/sites-available/maya <<'NGINX_EOF'
upstream maya_backend {
    server 127.0.0.1:8000;
    keepalive 32;
}

server {
    listen 80;
    server_name _;
    
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name _;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy strict-origin-when-cross-origin;
    
    # Proxy settings
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
    
    # Timeouts
    proxy_connect_timeout 60s;
    proxy_send_timeout 300s;
    proxy_read_timeout 300s;
    
    # Frontend static files
    location / {
        root /opt/maya/frontend/dist;
        try_files $uri $uri/ /index.html;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
    
    # API routes
    location /api/ {
        proxy_pass http://maya_backend;
        proxy_buffering off;
    }
    
    # WebSocket
    location /ws {
        proxy_pass http://maya_backend;
    }
    
    # SSE
    location /events {
        proxy_pass http://maya_backend;
        proxy_buffering off;
        proxy_cache off;
    }
    
    # Health check
    location /health {
        proxy_pass http://maya_backend;
        access_log off;
    }
}
NGINX_EOF
    
    ln -sf /etc/nginx/sites-available/maya /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    nginx -t && systemctl reload nginx
}

setup_ssl() {
    log "Setting up SSL with Let's Encrypt..."
    # This requires a valid domain name
    warn "SSL setup requires a valid domain. Run manually after DNS is configured:"
    warn "  certbot --nginx -d yourdomain.com -d www.yourdomain.com"
}

# =============================================================================
# Firewall
# =============================================================================

setup_firewall() {
    log "Configuring firewall..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    # Internal services (restrict to local network)
    ufw allow from 10.0.0.0/8 to any port 6333,6334,8000,6379
    ufw allow from 172.16.0.0/12 to any port 6333,6334,8000,6379
    ufw allow from 192.168.0.0/16 to any port 6333,6334,8000,6379
}

# =============================================================================
# Monitoring
# =============================================================================

setup_monitoring() {
    log "Setting up monitoring..."
    
    # Prometheus node exporter
    docker run -d \
        --name node-exporter \
        --restart unless-stopped \
        -p 9100:9100 \
        --pid="host" \
        -v "/:/host:ro,rslave" \
        quay.io/prometheus/node-exporter:latest \
        --path.rootfs=/host
    
    # cAdvisor for container metrics
    docker run -d \
        --name cadvisor \
        --restart unless-stopped \
        -p 8080:8080 \
        -v /:/rootfs:ro \
        -v /var/run:/var/run:ro \
        -v /sys:/sys:ro \
        -v /var/lib/docker/:/var/lib/docker:ro \
        -v /dev/disk/:/dev/disk:ro \
        gcr.io/cadvisor/cadvisor:latest
}

# =============================================================================
# Backup script
# =============================================================================

create_backup_script() {
    log "Creating backup script..."
    cat > "$MAYA_DIR/backup.sh" <<'BACKUP_EOF'
#!/bin/bash
# Maya backup script - runs daily via cron

BACKUP_DIR="/opt/maya/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# Backup storage (excluding large caches)
tar -czf "$BACKUP_DIR/maya_storage_$DATE.tar.gz" \
    -C /opt/maya storage \
    --exclude='storage/browser_pool' \
    --exclude='storage/sandbox/exec' \
    --exclude='storage/vector_store/chroma' \
    --exclude='storage/streaming_sessions' \
    --exclude='storage/multimodal/models' \
    2>/dev/null

# Backup database (if using local PostgreSQL)
# pg_dump -U maya maya_db | gzip > "$BACKUP_DIR/maya_db_$DATE.sql.gz"

# Backup config
cp /opt/maya/.env "$BACKUP_DIR/env_$DATE.backup"

# Cleanup old backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.backup" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
BACKUP_EOF
    
    chmod +x "$MAYA_DIR/backup.sh"
    chown "$MAYA_USER:$MAYA_USER" "$MAYA_DIR/backup.sh"
    
    # Add to crontab
    (crontab -u "$MAYA_USER" -l 2>/dev/null; echo "0 3 * * * $MAYA_DIR/backup.sh >> $MAYA_DIR/logs/backup.log 2>&1") | crontab -u "$MAYA_USER" -
}

# =============================================================================
# Health check script
# =============================================================================

create_health_check() {
    log "Creating health check script..."
    cat > "$MAYA_DIR/health_check.sh" <<'HEALTH_EOF'
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
check_service "ChromaDB" "http://localhost:8000/api/v1/heartbeat" 200
check_service "Qdrant" "http://localhost:6333/health" 200
check_service "Redis" "http://localhost:6379" 0  # Redis doesn't use HTTP

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
    echo "❌ Maya API not responding"
fi
HEALTH_EOF
    
    chmod +x "$MAYA_DIR/health_check.sh"
    chown "$MAYA_USER:$MAYA_USER" "$MAYA_DIR/health_check.sh"
}

# =============================================================================
# Start services
# =============================================================================

start_services() {
    log "Starting all services..."
    
    # Start databases
    systemctl start redis-server
    systemctl start postgresql 2>/dev/null || true
    
    # Start containers
    docker start chromadb qdrant node-exporter cadvisor 2>/dev/null || true
    
    # Start Maya
    systemctl start maya
    
    # Wait for startup
    sleep 10
    
    # Health check
    log "Running health checks..."
    "$MAYA_DIR/health_check.sh"
}

# =============================================================================
# Main deployment flow
# =============================================================================

main() {
    log "==========================================="
    log "Maya 2.0 ULTRA - Oracle ARM64 VPS Deploy"
    log "==========================================="
    
    check_root
    check_arch
    check_os
    
    log "Phase 1: System preparation"
    update_system
    create_maya_user
    setup_directories
    install_python
    install_node
    install_docker
    
    log "Phase 2: Core infrastructure"
    install_gvisor
    install_chromadb
    install_qdrant
    install_playwright
    install_redis
    install_postgresql
    
    log "Phase 3: ML Models"
    install_ml_models
    
    log "Phase 4: Application deployment"
    deploy_maya
    create_env_file
    
    log "Phase 5: Service configuration"
    create_systemd_service
    create_nginx_config
    setup_firewall
    create_backup_script
    create_health_check
    
    log "Phase 6: Start services"
    start_services
    
    log "==========================================="
    log "DEPLOYMENT COMPLETE!"
    log "==========================================="
    echo ""
    info "Next steps:"
    echo "  1. Edit $MAYA_DIR/.env and add your API keys"
    echo "  2. Configure DNS for your domain"
    echo "  3. Run: certbot --nginx -d yourdomain.com"
    echo "  4. Restart Maya: systemctl restart maya"
    echo ""
    info "Service management:"
    echo "  - Maya status: systemctl status maya"
    echo "  - Maya logs: journalctl -u maya -f"
    echo "  - Health check: $MAYA_DIR/health_check.sh"
    echo "  - Backup: $MAYA_DIR/backup.sh"
    echo ""
    info "Access points:"
    echo "  - Frontend: https://yourdomain.com"
    echo "  - API: https://yourdomain.com/api/v1/"
    echo "  - ChromaDB: http://localhost:8000"
    echo "  - Qdrant: http://localhost:6333"
    echo "  - Prometheus metrics: http://localhost:9100/metrics"
    echo ""
    warn "REMEMBER TO:"
    echo "  - Set strong SECRET_KEY and ADMIN_PASSWORD in .env"
    echo "  - Add at least one LLM provider key (NVIDIA_NIM_KEY, GROQ_KEY, etc.)"
    echo "  - Configure VPS_* settings for remote deploy"
    echo "  - Set up SMTP for notifications"
}

# Run main
main "$@"