#!/bin/bash
# External Drive Optimization Script
# Run this INSIDE the Ubuntu VM after initial setup

set -e

echo "⚡ External Drive Optimization Script"
echo "===================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run this script as a regular user, not root"
    exit 1
fi

# Check if homelab mount exists
if [ ! -d "/mnt/homelab" ]; then
    echo "❌ Homelab mount point not found at /mnt/homelab"
    echo "Please ensure external drive is mounted first"
    exit 1
fi

echo "✅ Homelab mount point found at /mnt/homelab"

# 1. System-level optimizations
echo "🔧 Applying system-level optimizations..."

# Backup original sysctl.conf
sudo cp /etc/sysctl.conf /etc/sysctl.conf.backup

# Add external drive optimizations
sudo tee -a /etc/sysctl.conf << 'EOF'

# External Drive Optimizations
# ============================

# Reduce swap usage (external drive is slower than RAM)
vm.swappiness=10
vm.vfs_cache_pressure=50

# Optimize dirty page handling for external drive
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# Increase file descriptor limits for AI services
fs.file-max=2097152
fs.nr_open=2097152

# AI Model Optimizations
vm.max_map_count=262144
kernel.shmmax=68719476736
kernel.shmall=4294967296

# Network optimizations for AI inference
net.core.rmem_max=134217728
net.core.wmem_max=134217728
net.ipv4.tcp_rmem=4096 65536 134217728
net.ipv4.tcp_wmem=4096 65536 134217728

# Reduce external drive I/O pressure
vm.dirty_background_bytes=16777216
vm.dirty_bytes=67108864
EOF

# Apply sysctl changes
echo "📊 Applying system optimizations..."
sudo sysctl -p

# 2. Create RAM disk for AI model caching
echo "💾 Setting up RAM disk for AI model caching..."

# Create RAM disk mount point
sudo mkdir -p /mnt/ramdisk

# Add RAM disk to fstab
echo "tmpfs /mnt/ramdisk tmpfs defaults,size=8G,noatime 0 0" | sudo tee -a /etc/fstab

# Mount RAM disk
sudo mount -a

# Verify RAM disk
echo "✅ RAM disk created: $(df -h /mnt/ramdisk | tail -1)"

# 3. Optimize Docker for external drive
echo "🐳 Optimizing Docker for external drive..."

# Create Docker data directory on external drive
sudo mkdir -p /mnt/homelab/docker

# Configure Docker daemon
sudo tee /etc/docker/daemon.json << 'EOF'
{
  "data-root": "/mnt/homelab/docker",
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "registry-mirrors": ["https://mirror.gcr.io"],
  "default-ulimits": {
    "memlock": {
      "Hard": -1,
      "Name": "memlock",
      "Soft": -1
    }
  },
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "experimental": false,
  "metrics-addr": "0.0.0.0:9323",
  "live-restore": true
}
EOF

# Restart Docker
echo "🔄 Restarting Docker with new configuration..."
sudo systemctl restart docker

# Wait for Docker to be ready
sleep 10

# Test Docker
docker --version
echo "✅ Docker optimized for external drive"

# 4. Optimize file system
echo "📁 Optimizing file system..."

# Check current mount options
echo "Current mount options for /mnt/homelab:"
mount | grep homelab

# Create optimized mount script
cat > /mnt/homelab/scripts/remount-optimized.sh << 'EOF'
#!/bin/bash
# Remount external drive with optimized options

echo "🔄 Remounting external drive with optimized options..."

# Unmount first
sudo umount /mnt/homelab

# Remount with optimized options
sudo mount -o defaults,noatime,nodiratime,relatime /dev/disk/by-uuid/$(blkid -s UUID -o value /dev/sd*) /mnt/homelab

echo "✅ External drive remounted with optimizations"
echo "New mount options:"
mount | grep homelab
EOF

chmod +x /mnt/homelab/scripts/remount-optimized.sh

# 5. Create I/O monitoring script
echo "📊 Creating I/O monitoring script..."

cat > /mnt/homelab/scripts/monitor-io.sh << 'EOF'
#!/bin/bash
# I/O Monitoring Script for External Drive

echo "💿 External Drive I/O Monitoring"
echo "================================"

# Check disk usage
echo "📁 Disk Usage:"
df -h /mnt/homelab

echo ""

# Check I/O statistics
echo "📊 I/O Statistics (last 5 seconds):"
iostat -x 1 5 | grep -E "(Device|sd|nvme)"

echo ""

# Check disk health
echo "🔍 Disk Health:"
sudo smartctl -a /dev/sd* 2>/dev/null | grep -E "(Model|Temperature|Power_On_Hours|Reallocated_Sector)" || echo "No SMART data available"

echo ""

# Check for I/O errors
echo "⚠️ I/O Errors:"
dmesg | grep -i "i/o error" | tail -5 || echo "No I/O errors found"

echo ""

# Check Docker I/O
echo "🐳 Docker I/O:"
docker system df
echo ""
echo "Docker container I/O:"
docker stats --no-stream --format "table {{.Container}}\t{{.BlockIO}}"
EOF

chmod +x /mnt/homelab/scripts/monitor-io.sh

# 6. Create performance test script
echo "🧪 Creating performance test script..."

cat > /mnt/homelab/scripts/test-performance.sh << 'EOF'
#!/bin/bash
# Performance Test Script for External Drive

echo "🧪 External Drive Performance Test"
echo "================================="

# Test write speed
echo "📝 Testing write speed..."
dd if=/dev/zero of=/mnt/homelab/speedtest bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s'

# Test read speed
echo "📖 Testing read speed..."
dd if=/mnt/homelab/speedtest of=/dev/null bs=1024k 2>&1 | grep -o '[0-9.]* MB/s'

# Clean up test file
rm -f /mnt/homelab/speedtest

echo ""

# Test Docker performance
echo "🐳 Testing Docker performance..."
echo "Pulling small image..."
time docker pull hello-world

echo "Removing test image..."
docker rmi hello-world

echo ""

# Test AI model loading (if Ollama is running)
if systemctl is-active --quiet ollama; then
    echo "🤖 Testing AI model loading..."
    echo "Loading small model (this may take a while)..."
    time ollama run llama2:7b "Hello, this is a performance test." || echo "Ollama not ready or model not available"
else
    echo "🤖 Ollama not running, skipping AI model test"
fi

echo ""
echo "✅ Performance test completed"
EOF

chmod +x /mnt/homelab/scripts/test-performance.sh

# 7. Create backup optimization script
echo "💾 Creating backup optimization script..."

cat > /mnt/homelab/scripts/optimize-backups.sh << 'EOF'
#!/bin/bash
# Backup Optimization Script

BACKUP_DIR="/mnt/homelab/backups"
SOURCE_DIR="/mnt/homelab"

echo "💾 Optimizing backups for external drive..."

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create incremental backup script
cat > "$BACKUP_DIR/incremental-backup.sh" << 'EOL'
#!/bin/bash
# Incremental backup script optimized for external drive

SOURCE="$1"
BACKUP_DIR="$2"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -z "$SOURCE" ] || [ -z "$BACKUP_DIR" ]; then
    echo "Usage: $0 <source-directory> <backup-directory>"
    exit 1
fi

echo "🔄 Starting incremental backup..."

# Use rsync with optimizations for external drive
rsync -avzP \
    --delete \
    --delete-excluded \
    --exclude='*.log' \
    --exclude='cache/' \
    --exclude='tmp/' \
    --exclude='*.tmp' \
    --exclude='.git/' \
    --exclude='node_modules/' \
    --exclude='*.pyc' \
    --exclude='__pycache__/' \
    --bwlimit=50000 \
    "$SOURCE/" "$BACKUP_DIR/current/"

# Create timestamped backup
cp -al "$BACKUP_DIR/current" "$BACKUP_DIR/backup_$TIMESTAMP"

echo "✅ Incremental backup completed: backup_$TIMESTAMP"
EOL

chmod +x "$BACKUP_DIR/incremental-backup.sh"

echo "✅ Backup optimization completed"
EOF

chmod +x /mnt/homelab/scripts/optimize-backups.sh

# 8. Create service startup optimization
echo "🚀 Creating service startup optimization..."

cat > /mnt/homelab/scripts/optimize-startup.sh << 'EOF'
#!/bin/bash
# Service Startup Optimization Script

echo "🚀 Optimizing service startup for external drive..."

# Create startup order script
cat > /mnt/homelab/scripts/startup-order.sh << 'EOL'
#!/bin/bash
# Optimized startup order for external drive

COMPOSE_DIR="/mnt/homelab/docker/compose"

echo "🚀 Starting services in optimized order for external drive..."

cd "$COMPOSE_DIR"

# Phase 1: Core infrastructure (fastest to start)
echo "Phase 1: Starting core infrastructure..."
docker compose up -d traefik adguard
sleep 10

# Phase 2: Databases (critical, need time to initialize)
echo "Phase 2: Starting databases..."
docker compose up -d nextcloud-db nextcloud-redis
sleep 20  # Extra time for external drive

# Phase 3: AI Services (start early, slow to load)
echo "Phase 3: Starting AI services..."
docker compose up -d ollama localai
sleep 30  # Model loading time

# Phase 4: Web interfaces
echo "Phase 4: Starting web interfaces..."
docker compose up -d open-webui text-generation-webui

# Phase 5: File services
echo "Phase 5: Starting file services..."
docker compose up -d nextcloud

# Phase 6: Media services
echo "Phase 6: Starting media services..."
docker compose up -d jellyfin

# Phase 7: Monitoring
echo "Phase 7: Starting monitoring..."
docker compose up -d prometheus grafana portainer

# Phase 8: Everything else
echo "Phase 8: Starting remaining services..."
docker compose up -d

echo "✅ All services started in optimized order!"
EOL

chmod +x /mnt/homelab/scripts/startup-order.sh

echo "✅ Service startup optimization completed"
EOF

chmod +x /mnt/homelab/scripts/optimize-startup.sh

# 9. Create system monitoring script
echo "📊 Creating system monitoring script..."

cat > /mnt/homelab/scripts/monitor-system.sh << 'EOF'
#!/bin/bash
# System Monitoring Script for External Drive Setup

echo "🖥️ Homelab System Monitor"
echo "========================"

# System overview
echo "📊 System Overview:"
echo "Uptime: $(uptime)"
echo "Load Average: $(cat /proc/loadavg)"
echo ""

# Memory usage
echo "💾 Memory Usage:"
free -h
echo ""

# Disk usage
echo "💿 Disk Usage:"
df -h
echo ""

# External drive specific
echo "🔌 External Drive Status:"
mount | grep homelab
echo ""

# I/O statistics
echo "📊 I/O Statistics:"
iostat -x 1 1 | grep -E "(Device|sd|nvme)"
echo ""

# Docker status
echo "🐳 Docker Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# AI services status
echo "🤖 AI Services Status:"
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama: Running"
    echo "📊 Loaded models:"
    ollama list 2>/dev/null || echo "   No models loaded"
else
    echo "❌ Ollama: Not running"
fi

echo ""

# Network status
echo "🌐 Network Status:"
ip addr show | grep -E "(inet |UP|DOWN)"
echo ""

# Service status
echo "⚙️ Service Status:"
systemctl list-units --type=service --state=running | grep -E "(docker|ollama|traefik)"
EOF

chmod +x /mnt/homelab/scripts/monitor-system.sh

# 10. Create maintenance script
echo "🔧 Creating maintenance script..."

cat > /mnt/homelab/scripts/maintenance.sh << 'EOF'
#!/bin/bash
# Maintenance Script for External Drive Setup

echo "🔧 Homelab Maintenance Script"
echo "============================="

# Clean Docker
echo "🧹 Cleaning Docker..."
docker system prune -f
docker volume prune -f

# Clean logs
echo "🧹 Cleaning logs..."
sudo journalctl --vacuum-time=7d

# Clean temporary files
echo "🧹 Cleaning temporary files..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# Clean RAM disk
echo "🧹 Cleaning RAM disk..."
sudo rm -rf /mnt/ramdisk/*

# Update system
echo "🔄 Updating system..."
sudo apt update
sudo apt upgrade -y

# Restart services if needed
echo "🔄 Restarting services..."
sudo systemctl restart docker
sudo systemctl restart ollama

echo "✅ Maintenance completed"
EOF

chmod +x /mnt/homelab/scripts/maintenance.sh

# 11. Create performance baseline
echo "📊 Creating performance baseline..."

cat > /mnt/homelab/scripts/create-baseline.sh << 'EOF'
#!/bin/bash
# Create Performance Baseline Script

echo "📊 Creating performance baseline..."

BASELINE_FILE="/mnt/homelab/performance-baseline.txt"

cat > "$BASELINE_FILE" << EOL
Homelab Performance Baseline
============================
Created: $(date)
System: $(uname -a)
CPU: $(lscpu | grep "Model name" | cut -d: -f2 | xargs)
RAM: $(free -h | grep "Mem:" | awk '{print $2}')
Disk: $(df -h /mnt/homelab | tail -1 | awk '{print $2 " total, " $3 " used, " $4 " available"}')

External Drive Performance:
- Write Speed: $(dd if=/dev/zero of=/mnt/homelab/speedtest bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s')
- Read Speed: $(dd if=/mnt/homelab/speedtest of=/dev/null bs=1024k 2>&1 | grep -o '[0-9.]* MB/s')

Docker Performance:
- Images: $(docker images | wc -l) images
- Containers: $(docker ps | wc -l) running
- Volumes: $(docker volume ls | wc -l) volumes

AI Services:
- Ollama: $(systemctl is-active ollama 2>/dev/null || echo "Not installed")
- Models: $(ollama list 2>/dev/null | wc -l) models available

Expected Performance:
- VM Boot: 2-3 minutes
- 7B Model Load: 30-40 seconds
- 13B Model Load: 60-90 seconds
- Mixtral 8x7B Load: 3-4 minutes
- Container Starts: +20-30% slower than internal drive
EOL

# Clean up test file
rm -f /mnt/homelab/speedtest

echo "✅ Performance baseline created: $BASELINE_FILE"
EOF

chmod +x /mnt/homelab/scripts/create-baseline.sh

# Run baseline creation
/mnt/homelab/scripts/create-baseline.sh

echo ""
echo "🎉 External Drive Optimization Completed!"
echo "========================================="
echo ""
echo "Available optimization scripts:"
echo "- /mnt/homelab/scripts/monitor-io.sh: Monitor I/O performance"
echo "- /mnt/homelab/scripts/test-performance.sh: Test drive performance"
echo "- /mnt/homelab/scripts/optimize-backups.sh: Optimize backup strategy"
echo "- /mnt/homelab/scripts/startup-order.sh: Optimized service startup"
echo "- /mnt/homelab/scripts/monitor-system.sh: System monitoring"
echo "- /mnt/homelab/scripts/maintenance.sh: Regular maintenance"
echo "- /mnt/homelab/scripts/create-baseline.sh: Create performance baseline"
echo ""
echo "Next steps:"
echo "1. Run performance test: /mnt/homelab/scripts/test-performance.sh"
echo "2. Start services: /mnt/homelab/scripts/startup-order.sh"
echo "3. Monitor performance: /mnt/homelab/scripts/monitor-system.sh"
echo ""
echo "⚠️  Remember to reboot after applying system optimizations!"