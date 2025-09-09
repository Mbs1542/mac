#!/bin/bash
# Data Migration Script for Homelab with AI Models
# Run this INSIDE the Ubuntu VM after AI setup is complete

set -e

# Configuration
EXTERNAL="/mnt/homelab"
SOURCE_MAC="/Volumes/WorkDrive/MacStorage"  # Change to your source location
BACKUP_DIR="$EXTERNAL/backups"
LOG_FILE="$EXTERNAL/migration.log"

echo "🚀 Starting Homelab Data Migration with AI Considerations"
echo "========================================================"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run this script as a regular user, not root"
    exit 1
fi

# Check if source exists
if [ ! -d "$SOURCE_MAC" ]; then
    echo "❌ Source directory not found at $SOURCE_MAC"
    echo "Please update the SOURCE_MAC variable to point to your data source"
    exit 1
fi

# Check if external drive is mounted
if [ ! -d "$EXTERNAL" ]; then
    echo "❌ External drive not mounted at $EXTERNAL"
    exit 1
fi

echo "✅ Source directory found: $SOURCE_MAC"
echo "✅ External drive mounted: $EXTERNAL"

# Create migration log
echo "Migration started at $(date)" > "$LOG_FILE"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to check available space
check_space() {
    local required_gb=$1
    local available_gb=$(df -BG "$EXTERNAL" | tail -1 | awk '{print $4}' | sed 's/G//')
    
    if [ "$available_gb" -lt "$required_gb" ]; then
        log "❌ Insufficient space: Need ${required_gb}GB, have ${available_gb}GB"
        return 1
    else
        log "✅ Sufficient space: ${available_gb}GB available, need ${required_gb}GB"
        return 0
    fi
}

# Function to estimate migration time
estimate_time() {
    local size_gb=$1
    local speed_mbps=158  # External drive speed
    local time_seconds=$((size_gb * 1024 / speed_mbps))
    local time_minutes=$((time_seconds / 60))
    local time_hours=$((time_minutes / 60))
    
    if [ $time_hours -gt 0 ]; then
        echo "${time_hours}h ${time_minutes}m"
    else
        echo "${time_minutes}m"
    fi
}

# Phase 1: Pre-migration checks
log "Phase 1: Pre-migration checks"

# Check available space
log "Checking available space..."
if ! check_space 100; then
    log "❌ Migration aborted due to insufficient space"
    exit 1
fi

# Check source directory size
log "Calculating source directory size..."
SOURCE_SIZE=$(du -s "$SOURCE_MAC" 2>/dev/null | cut -f1)
SOURCE_SIZE_GB=$((SOURCE_SIZE / 1024 / 1024))

log "Source directory size: ${SOURCE_SIZE_GB}GB"
ESTIMATED_TIME=$(estimate_time $SOURCE_SIZE_GB)
log "Estimated migration time: $ESTIMATED_TIME"

# Phase 2: Create backup of current state
log "Phase 2: Creating backup of current state"
mkdir -p "$BACKUP_DIR/pre-migration"

# Backup current Docker volumes
if [ -d "$EXTERNAL/docker/volumes" ]; then
    log "Backing up existing Docker volumes..."
    tar -czf "$BACKUP_DIR/pre-migration/docker-volumes-$(date +%Y%m%d_%H%M%S).tar.gz" -C "$EXTERNAL" docker/volumes
fi

# Phase 3: Essential configurations first
log "Phase 3: Migrating essential configurations"

# Create essential directories
mkdir -p "$EXTERNAL/docker/volumes"
mkdir -p "$EXTERNAL/configs"
mkdir -p "$EXTERNAL/media"

# Migrate Docker configurations
if [ -d "$SOURCE_MAC/docker" ]; then
    log "Migrating Docker configurations..."
    rsync -avzP --exclude='*.log' --exclude='cache/' --exclude='tmp/' \
        "$SOURCE_MAC/docker/" "$EXTERNAL/docker/" \
        --progress | tee -a "$LOG_FILE"
fi

# Migrate configuration files
if [ -d "$SOURCE_MAC/configs" ]; then
    log "Migrating configuration files..."
    rsync -avzP "$SOURCE_MAC/configs/" "$EXTERNAL/configs/" \
        --progress | tee -a "$LOG_FILE"
fi

# Phase 4: Database migrations (critical for external drive)
log "Phase 4: Migrating databases"

# Start databases first
log "Starting database services..."
cd "$EXTERNAL/docker/compose"
docker compose up -d nextcloud-db nextcloud-redis

# Wait for databases to be ready
log "Waiting for databases to initialize..."
sleep 30

# Migrate database dumps if they exist
if [ -d "$SOURCE_MAC/databases" ]; then
    log "Migrating database dumps..."
    rsync -avzP "$SOURCE_MAC/databases/" "$EXTERNAL/backups/databases/" \
        --progress | tee -a "$LOG_FILE"
fi

# Phase 5: AI models migration (throttled for external drive)
log "Phase 5: Migrating AI models"

# Create AI models directory
mkdir -p "$EXTERNAL/models"

# Migrate existing AI models with throttling
if [ -d "$SOURCE_MAC/models" ]; then
    log "Migrating AI models (throttled for external drive)..."
    rsync -avzP --bwlimit=50000 \
        "$SOURCE_MAC/models/" "$EXTERNAL/models/" \
        --progress | tee -a "$LOG_FILE"
else
    log "No existing AI models found, will download fresh models"
fi

# Phase 6: Media files migration (heavily throttled)
log "Phase 6: Migrating media files"

if [ -d "$SOURCE_MAC/media" ]; then
    log "Migrating media files (heavily throttled for external drive)..."
    rsync -avzP --bwlimit=20000 \
        "$SOURCE_MAC/media/" "$EXTERNAL/media/" \
        --progress | tee -a "$LOG_FILE"
else
    log "No media files found to migrate"
fi

# Phase 7: Application data migration
log "Phase 7: Migrating application data"

# Migrate Nextcloud data
if [ -d "$SOURCE_MAC/nextcloud" ]; then
    log "Migrating Nextcloud data..."
    rsync -avzP --bwlimit=30000 \
        "$SOURCE_MAC/nextcloud/" "$EXTERNAL/docker/volumes/nextcloud/" \
        --progress | tee -a "$LOG_FILE"
fi

# Migrate other application data
if [ -d "$SOURCE_MAC/appdata" ]; then
    log "Migrating application data..."
    rsync -avzP --bwlimit=30000 \
        "$SOURCE_MAC/appdata/" "$EXTERNAL/docker/volumes/" \
        --progress | tee -a "$LOG_FILE"
fi

# Phase 8: Start AI services
log "Phase 8: Starting AI services"

# Start Ollama
log "Starting Ollama service..."
sudo systemctl start ollama
sleep 10

# Start AI Docker services
log "Starting AI Docker services..."
docker compose up -d ollama localai text-generation-webui open-webui

# Wait for AI services to initialize
log "Waiting for AI services to initialize..."
sleep 30

# Phase 9: Download AI models if not migrated
log "Phase 9: Downloading AI models"

# Check if models exist
if [ ! -d "$EXTERNAL/models/ollama" ] || [ -z "$(ls -A $EXTERNAL/models/ollama 2>/dev/null)" ]; then
    log "Downloading AI models..."
    export OLLAMA_MODELS="$EXTERNAL/models/ollama"
    
    # Download models in background to not block migration
    nohup bash -c '
        ollama pull llama2:7b
        ollama pull mistral:7b
        ollama pull codellama:13b
        ollama pull llava:7b
        echo "AI models download completed" >> /mnt/homelab/migration.log
    ' > /dev/null 2>&1 &
    
    log "AI models download started in background"
else
    log "AI models already exist, skipping download"
fi

# Phase 10: Start remaining services
log "Phase 10: Starting remaining services"

# Start core infrastructure
log "Starting core infrastructure..."
docker compose up -d traefik adguard

sleep 15

# Start file services
log "Starting file services..."
docker compose up -d nextcloud jellyfin

sleep 15

# Start monitoring services
log "Starting monitoring services..."
docker compose up -d prometheus grafana portainer

sleep 15

# Start all remaining services
log "Starting all remaining services..."
docker compose up -d

# Phase 11: Validation
log "Phase 11: Validating migration"

# Check service status
log "Checking service status..."
docker compose ps

# Check AI services
log "Checking AI services..."
if systemctl is-active --quiet ollama; then
    log "✅ Ollama is running"
    log "Available models: $(ollama list 2>/dev/null | wc -l)"
else
    log "❌ Ollama is not running"
fi

# Check disk usage
log "Checking disk usage..."
df -h "$EXTERNAL"

# Check external drive performance
log "Testing external drive performance..."
dd if=/dev/zero of="$EXTERNAL/speedtest" bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s' | tee -a "$LOG_FILE"
rm -f "$EXTERNAL/speedtest"

# Phase 12: Create post-migration report
log "Phase 12: Creating post-migration report"

cat > "$EXTERNAL/migration-report.md" << EOF
# Homelab Migration Report

## Migration Summary
- **Date**: $(date)
- **Source**: $SOURCE_MAC
- **Destination**: $EXTERNAL
- **Total Size**: ${SOURCE_SIZE_GB}GB
- **Migration Time**: $ESTIMATED_TIME

## Services Status
\`\`\`
$(docker compose ps)
\`\`\`

## AI Services Status
- **Ollama**: $(systemctl is-active ollama 2>/dev/null || echo "Not running")
- **Models Available**: $(ollama list 2>/dev/null | wc -l)
- **LocalAI**: $(docker ps --filter name=localai --format "{{.Status}}" 2>/dev/null || echo "Not running")
- **Text Generation WebUI**: $(docker ps --filter name=textgen --format "{{.Status}}" 2>/dev/null || echo "Not running")

## Disk Usage
\`\`\`
$(df -h $EXTERNAL)
\`\`\`

## Performance Test
- **Write Speed**: $(dd if=/dev/zero of=$EXTERNAL/speedtest bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s')
- **Read Speed**: $(dd if=$EXTERNAL/speedtest of=/dev/null bs=1024k 2>&1 | grep -o '[0-9.]* MB/s')

## Next Steps
1. Verify all services are accessible
2. Test AI model inference
3. Configure backups
4. Monitor performance
5. Update DNS/hosts file if needed

## Troubleshooting
- Check logs: \`docker compose logs\`
- Monitor I/O: \`/mnt/homelab/scripts/monitor-io.sh\`
- System status: \`/mnt/homelab/scripts/monitor-system.sh\`
EOF

rm -f "$EXTERNAL/speedtest"

# Phase 13: Create maintenance schedule
log "Phase 13: Creating maintenance schedule"

cat > "$EXTERNAL/scripts/maintenance-schedule.sh" << 'EOF'
#!/bin/bash
# Maintenance Schedule for External Drive Homelab

echo "🔧 Homelab Maintenance Schedule"
echo "==============================="

# Daily maintenance
echo "📅 Daily Maintenance:"
echo "- Check service status"
echo "- Monitor disk usage"
echo "- Clean temporary files"
echo "- Check AI model status"

# Weekly maintenance
echo "📅 Weekly Maintenance:"
echo "- Full system backup"
echo "- Docker cleanup"
echo "- Log rotation"
echo "- Performance monitoring"

# Monthly maintenance
echo "📅 Monthly Maintenance:"
echo "- System updates"
echo "- Security patches"
echo "- Disk health check"
echo "- AI model updates"

# Create cron jobs
echo "Setting up maintenance cron jobs..."

# Daily maintenance at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /mnt/homelab/scripts/maintenance.sh >> /mnt/homelab/logs/maintenance.log 2>&1") | crontab -

# Weekly backup on Sunday at 3 AM
(crontab -l 2>/dev/null; echo "0 3 * * 0 /mnt/homelab/scripts/backup-homelab.sh /mnt/homelab/backups /mnt/homelab >> /mnt/homelab/logs/backup.log 2>&1") | crontab -

echo "✅ Maintenance schedule created"
EOF

chmod +x "$EXTERNAL/scripts/maintenance-schedule.sh"

# Run maintenance schedule setup
"$EXTERNAL/scripts/maintenance-schedule.sh"

log "Migration completed successfully!"
log "Report saved to: $EXTERNAL/migration-report.md"
log "Log file: $LOG_FILE"

echo ""
echo "🎉 Homelab Migration Completed!"
echo "==============================="
echo ""
echo "Migration Summary:"
echo "- Source: $SOURCE_MAC"
echo "- Destination: $EXTERNAL"
echo "- Total Size: ${SOURCE_SIZE_GB}GB"
echo "- Migration Time: $ESTIMATED_TIME"
echo ""
echo "Next Steps:"
echo "1. Check migration report: $EXTERNAL/migration-report.md"
echo "2. Verify all services: docker compose ps"
echo "3. Test AI services: /mnt/homelab/scripts/monitor-ai.sh"
echo "4. Monitor performance: /mnt/homelab/scripts/monitor-system.sh"
echo ""
echo "⚠️  Remember to update your router DNS settings if needed!"