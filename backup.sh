#!/bin/bash
# Maya backup script - runs daily via cron

BACKUP_DIR="/opt/maya/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

mkdir -p "$BACKUP_DIR"

# Backup storage (excluding large caches)
tar -czf "$BACKUP_DIR/maya_storage_$DATE.tar.gz"     -C /opt/maya storage     --exclude='storage/browser_pool'     --exclude='storage/sandbox/exec'     --exclude='storage/vector_store/chroma'     --exclude='storage/streaming_sessions'     --exclude='storage/multimodal/models'     2>/dev/null

# Backup database (if using local PostgreSQL)
# pg_dump -U maya maya_db | gzip > "$BACKUP_DIR/maya_db_$DATE.sql.gz"

# Backup config
cp /opt/maya/.env "$BACKUP_DIR/env_$DATE.backup"

# Cleanup old backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_DIR" -name "*.backup" -mtime +$RETENTION_DAYS -delete

echo "Backup completed: $DATE"
