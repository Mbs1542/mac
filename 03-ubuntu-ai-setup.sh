#!/bin/bash
# Ubuntu AI Setup Script for Homelab Migration
# Run this INSIDE the Ubuntu VM after initial setup

set -e

# Configuration
HOMELAB_MOUNT="/mnt/homelab"
OLLAMA_MODELS_PATH="$HOMELAB_MOUNT/models"
DOCKER_DATA_PATH="$HOMELAB_MOUNT/docker"
RAM_DISK_SIZE="8G"

echo "🚀 Starting Ubuntu AI Setup for Homelab Migration"
echo "=================================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run this script as a regular user, not root"
    echo "The script will use sudo when needed"
    exit 1
fi

# Check if homelab mount exists
if [ ! -d "$HOMELAB_MOUNT" ]; then
    echo "❌ Homelab mount point not found at $HOMELAB_MOUNT"
    echo "Please ensure external drive is mounted first"
    exit 1
fi

echo "✅ Homelab mount point found at $HOMELAB_MOUNT"

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    iotop \
    nethogs \
    tree \
    jq \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    python3-pip \
    python3-venv

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Ollama
echo "🤖 Installing Ollama..."
curl -fsSL https://ollama.ai/install.sh | sh

# Create directory structure
echo "📁 Creating directory structure..."
sudo mkdir -p "$OLLAMA_MODELS_PATH/ollama"
sudo mkdir -p "$OLLAMA_MODELS_PATH/localai"
sudo mkdir -p "$OLLAMA_MODELS_PATH/textgen"
sudo mkdir -p "$HOMELAB_MOUNT/docker/volumes"
sudo mkdir -p "$HOMELAB_MOUNT/docker/compose"
sudo mkdir -p "$HOMELAB_MOUNT/docker/textgen/characters"
sudo mkdir -p "$HOMELAB_MOUNT/docker/textgen/presets"
sudo mkdir -p "$HOMELAB_MOUNT/backups"
sudo mkdir -p "$HOMELAB_MOUNT/configs"

# Set permissions
sudo chown -R $USER:$USER "$HOMELAB_MOUNT"

# Configure system optimizations for external drive
echo "⚡ Configuring system optimizations..."
sudo tee -a /etc/sysctl.conf << 'EOF'

# External drive optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# AI model optimizations
vm.max_map_count=262144
kernel.shmmax=68719476736
kernel.shmall=4294967296
EOF

# Apply sysctl changes
sudo sysctl -p

# Create RAM disk for AI model caching
echo "💾 Creating RAM disk for AI model caching..."
sudo mkdir -p /mnt/ramdisk
echo "tmpfs /mnt/ramdisk tmpfs defaults,size=$RAM_DISK_SIZE,noatime 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Verify RAM disk
echo "✅ RAM disk created: $(df -h /mnt/ramdisk | tail -1)"

# Configure Docker for external drive
echo "🐳 Configuring Docker for external drive..."
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json << EOF
{
  "data-root": "$DOCKER_DATA_PATH",
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
  }
}
EOF

# Restart Docker
sudo systemctl restart docker
sudo systemctl enable docker

# Wait for Docker to be ready
echo "⏳ Waiting for Docker to be ready..."
sleep 10

# Test Docker
docker --version
docker-compose --version

# Configure Ollama
echo "🤖 Configuring Ollama..."
export OLLAMA_MODELS="$OLLAMA_MODELS_PATH/ollama"

# Create Ollama systemd service
sudo tee /etc/systemd/system/ollama.service << EOF
[Unit]
Description=Ollama Service
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$HOME
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_MODELS=$OLLAMA_MODELS_PATH/ollama"
Environment="OLLAMA_KEEP_ALIVE=24h"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Ollama
sudo systemctl daemon-reload
sudo systemctl enable ollama

# Create AI model download script
echo "📥 Creating AI model download script..."
cat > "$HOMELAB_MOUNT/scripts/download-models.sh" << 'EOF'
#!/bin/bash
# AI Model Download Script

set -e

OLLAMA_MODELS="$1"
echo "🤖 Downloading AI models to $OLLAMA_MODELS"

# Set Ollama models path
export OLLAMA_MODELS="$OLLAMA_MODELS"

# Start Ollama service
sudo systemctl start ollama
sleep 10

# Download models (with progress)
echo "📥 Downloading Llama2 7B..."
ollama pull llama2:7b

echo "📥 Downloading CodeLlama 13B..."
ollama pull codellama:13b

echo "📥 Downloading Mistral 7B..."
ollama pull mistral:7b

echo "📥 Downloading Mixtral 8x7B (this will take a while)..."
ollama pull mixtral:8x7b

echo "📥 Downloading LLaVA 7B (vision model)..."
ollama pull llava:7b

echo "✅ All models downloaded successfully!"
echo "📊 Model sizes:"
ollama list
EOF

chmod +x "$HOMELAB_MOUNT/scripts/download-models.sh"

# Create service management script
echo "🔧 Creating service management script..."
cat > "$HOMELAB_MOUNT/scripts/manage-services.sh" << 'EOF'
#!/bin/bash
# Homelab Service Management Script

set -e

COMPOSE_DIR="$1"
ACTION="$2"

if [ -z "$COMPOSE_DIR" ] || [ -z "$ACTION" ]; then
    echo "Usage: $0 <compose-directory> <start|stop|restart|status>"
    exit 1
fi

cd "$COMPOSE_DIR"

case "$ACTION" in
    start)
        echo "🚀 Starting homelab services..."
        
        # 1. Core infrastructure
        echo "Starting core infrastructure..."
        docker compose up -d traefik adguard
        sleep 15
        
        # 2. Databases
        echo "Starting databases..."
        docker compose up -d nextcloud-db nextcloud-redis
        sleep 15
        
        # 3. AI Services
        echo "Starting AI services..."
        docker compose up -d ollama localai
        sleep 30  # Extra time for model loading
        
        # 4. Web interfaces
        echo "Starting web interfaces..."
        docker compose up -d open-webui text-generation-webui
        
        # 5. Rest of services
        echo "Starting remaining services..."
        docker compose up -d
        
        echo "✅ All services started!"
        ;;
    stop)
        echo "🛑 Stopping homelab services..."
        docker compose down
        echo "✅ All services stopped!"
        ;;
    restart)
        echo "🔄 Restarting homelab services..."
        docker compose down
        sleep 5
        $0 "$COMPOSE_DIR" start
        ;;
    status)
        echo "📊 Service status:"
        docker compose ps
        echo ""
        echo "📊 Resource usage:"
        docker stats --no-stream
        ;;
    *)
        echo "❌ Unknown action: $ACTION"
        exit 1
        ;;
esac
EOF

chmod +x "$HOMELAB_MOUNT/scripts/manage-services.sh"

# Create monitoring script
echo "📊 Creating monitoring script..."
cat > "$HOMELAB_MOUNT/scripts/monitor-ai.sh" << 'EOF'
#!/bin/bash
# AI Services Monitoring Script

echo "🤖 AI Services Status"
echo "===================="

# Check Ollama
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama: Running"
    echo "📊 Loaded models:"
    ollama list 2>/dev/null || echo "   No models loaded"
else
    echo "❌ Ollama: Not running"
fi

echo ""

# Check Docker AI services
echo "🐳 Docker AI Services:"
docker ps --filter "name=ollama" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=localai" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=textgen" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker ps --filter "name=open-webui" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""

# Check resource usage
echo "💾 Resource Usage:"
echo "RAM Usage:"
free -h
echo ""
echo "Disk Usage:"
df -h /mnt/homelab
echo ""
echo "Docker Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""

# Check external drive I/O
echo "💿 External Drive I/O:"
iostat -x 1 1 | grep -E "(Device|sd)"
EOF

chmod +x "$HOMELAB_MOUNT/scripts/monitor-ai.sh"

# Create backup script
echo "💾 Creating backup script..."
cat > "$HOMELAB_MOUNT/scripts/backup-homelab.sh" << 'EOF'
#!/bin/bash
# Homelab Backup Script

set -e

BACKUP_DIR="$1"
SOURCE_DIR="$2"

if [ -z "$BACKUP_DIR" ] || [ -z "$SOURCE_DIR" ]; then
    echo "Usage: $0 <backup-directory> <source-directory>"
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="homelab_backup_$TIMESTAMP"

echo "💾 Starting homelab backup..."
echo "Source: $SOURCE_DIR"
echo "Backup: $BACKUP_DIR/$BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup Docker volumes (excluding logs and cache)
echo "📦 Backing up Docker volumes..."
rsync -avzP --exclude='*.log' --exclude='cache/' --exclude='tmp/' \
    "$SOURCE_DIR/docker/volumes/" "$BACKUP_DIR/$BACKUP_NAME/docker-volumes/"

# Backup configurations
echo "⚙️ Backing up configurations..."
rsync -avzP "$SOURCE_DIR/configs/" "$BACKUP_DIR/$BACKUP_NAME/configs/"

# Backup AI models (if not too large)
echo "🤖 Backing up AI models..."
rsync -avzP --exclude='*.tmp' "$SOURCE_DIR/models/" "$BACKUP_DIR/$BACKUP_NAME/models/"

# Create backup info
cat > "$BACKUP_DIR/$BACKUP_NAME/backup-info.txt" << EOL
Homelab Backup Information
=========================
Backup Date: $(date)
Source: $SOURCE_DIR
Backup Size: $(du -sh "$BACKUP_DIR/$BACKUP_NAME" | cut -f1)
Services: $(docker ps --format "{{.Names}}" | wc -l) running
Models: $(ollama list 2>/dev/null | wc -l) available
EOL

echo "✅ Backup completed: $BACKUP_DIR/$BACKUP_NAME"
EOF

chmod +x "$HOMELAB_MOUNT/scripts/backup-homelab.sh"

# Create system info script
echo "ℹ️ Creating system info script..."
cat > "$HOMELAB_MOUNT/scripts/system-info.sh" << 'EOF'
#!/bin/bash
# System Information Script

echo "🖥️ Homelab System Information"
echo "============================="

echo "OS Information:"
uname -a
echo ""

echo "CPU Information:"
lscpu | grep -E "(Model name|CPU\(s\)|Thread|Core)"
echo ""

echo "Memory Information:"
free -h
echo ""

echo "Disk Information:"
df -h
echo ""

echo "Docker Information:"
docker --version
docker-compose --version
echo ""

echo "Ollama Information:"
ollama --version 2>/dev/null || echo "Ollama not installed"
echo ""

echo "Network Information:"
ip addr show | grep -E "(inet |UP|DOWN)"
echo ""

echo "Running Services:"
systemctl list-units --type=service --state=running | grep -E "(docker|ollama)"
echo ""

echo "Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
EOF

chmod +x "$HOMELAB_MOUNT/scripts/system-info.sh"

# Create directories for scripts
mkdir -p "$HOMELAB_MOUNT/scripts"

# Set up environment variables
echo "🔧 Setting up environment variables..."
cat >> ~/.bashrc << 'EOF'

# Homelab AI Environment
export HOMELAB_MOUNT="/mnt/homelab"
export OLLAMA_MODELS="$HOMELAB_MOUNT/models/ollama"
export DOCKER_DATA_PATH="$HOMELAB_MOUNT/docker"
export PATH="$HOMELAB_MOUNT/scripts:$PATH"

# Aliases for convenience
alias homelab-status="$HOMELAB_MOUNT/scripts/monitor-ai.sh"
alias homelab-start="$HOMELAB_MOUNT/scripts/manage-services.sh $HOMELAB_MOUNT/docker/compose start"
alias homelab-stop="$HOMELAB_MOUNT/scripts/manage-services.sh $HOMELAB_MOUNT/docker/compose stop"
alias homelab-restart="$HOMELAB_MOUNT/scripts/manage-services.sh $HOMELAB_MOUNT/docker/compose restart"
alias homelab-backup="$HOMELAB_MOUNT/scripts/backup-homelab.sh $HOMELAB_MOUNT/backups $HOMELAB_MOUNT"
alias homelab-info="$HOMELAB_MOUNT/scripts/system-info.sh"
EOF

# Reload bashrc
source ~/.bashrc

echo ""
echo "🎉 Ubuntu AI Setup Completed!"
echo "============================="
echo ""
echo "Next steps:"
echo "1. Download AI models: $HOMELAB_MOUNT/scripts/download-models.sh $OLLAMA_MODELS_PATH/ollama"
echo "2. Create your docker-compose.yml in $HOMELAB_MOUNT/docker/compose/"
echo "3. Start services: homelab-start"
echo "4. Monitor: homelab-status"
echo ""
echo "Available commands:"
echo "- homelab-status: Check AI services status"
echo "- homelab-start: Start all services"
echo "- homelab-stop: Stop all services"
echo "- homelab-restart: Restart all services"
echo "- homelab-backup: Create backup"
echo "- homelab-info: Show system information"
echo ""
echo "⚠️  Remember to log out and back in for environment variables to take effect!"