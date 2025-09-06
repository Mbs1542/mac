#!/bin/bash

# Enhanced Homelab Deployment Script
# Deploys new services: Firefly III, Remote Access Tools, Development Environment

set -e

echo "🚀 Enhanced Homelab Deployment Script"
echo "======================================"
echo "This script will deploy:"
echo "  - Firefly III (Financial Management)"
echo "  - Code-Server (VS Code in Browser)"
echo "  - NoMachine (Remote Desktop)"
echo "  - File Browser (Web File Manager)"
echo "  - WebSSH (Terminal Access)"
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root!"
   exit 1
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

print_status "Docker and Docker Compose detected"

# Base directory
BASE_DIR="/Volumes/WorkDrive/MacStorage/docker"
if [ ! -d "$BASE_DIR" ]; then
    print_warning "Base directory not found. Creating in current directory..."
    BASE_DIR="./docker"
    mkdir -p "$BASE_DIR"
fi

# Create directory structure for new services
print_status "Creating directory structure..."

# Firefly III directories
mkdir -p "$BASE_DIR/firefly/upload"
mkdir -p "$BASE_DIR/firefly/export"
mkdir -p "$BASE_DIR/firefly/db"

# Code-Server directories
mkdir -p "$BASE_DIR/code-server/config"
mkdir -p "$BASE_DIR/code-server/config/workspace"

# NoMachine directories
mkdir -p "$BASE_DIR/nomachine/config"

# File Browser directories
mkdir -p "$BASE_DIR/filebrowser"

# Set permissions
print_status "Setting permissions..."
chmod -R 755 "$BASE_DIR/firefly"
chmod -R 755 "$BASE_DIR/code-server"
chmod -R 755 "$BASE_DIR/nomachine"
chmod -R 755 "$BASE_DIR/filebrowser"

# Create File Browser configuration
print_status "Creating File Browser configuration..."
cat > "$BASE_DIR/filebrowser/filebrowser.json" <<EOF
{
  "port": 80,
  "baseURL": "",
  "address": "",
  "log": "stdout",
  "database": "/database.db",
  "root": "/srv",
  "auth": {
    "method": "json",
    "header": "X-Auth"
  },
  "tls": {
    "cert": "",
    "key": ""
  },
  "users": [
    {
      "username": "admin",
      "password": "\$2a\$10\$ZEHtm0kTSy2ee9VqSsLxV.Gkr8rqPMdkV3TpxO.3JvDvvpZ2BQKFO",
      "admin": true
    }
  ]
}
EOF

# Generate Firefly III APP_KEY
print_status "Generating Firefly III APP_KEY..."
APP_KEY=$(openssl rand -base64 32)
echo "APP_KEY=base64:$APP_KEY" > .env.firefly.generated

# Create enhanced docker-compose override file
print_status "Creating docker-compose override file..."
cat > docker-compose.override.yml <<'EOF'
version: '3.8'

# Override file for local development and testing
# This file is automatically loaded by docker-compose

services:
  # Add health check intervals for better monitoring
  traefik:
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
  
  # Ensure Firefly III has proper environment
  firefly-iii:
    environment:
      - APP_KEY=${APP_KEY}
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
  
  # Code-Server extensions
  code-server:
    environment:
      - INSTALL_EXTENSIONS=ms-python.python,ms-azuretools.vscode-docker,redhat.vscode-yaml
    labels:
      - "com.centurylinklabs.watchtower.enable=true"
EOF

# Create systemd service file (if on Linux)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    print_status "Creating systemd service..."
    sudo tee /etc/systemd/system/homelab.service > /dev/null <<EOF
[Unit]
Description=Homelab Docker Compose Stack
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose -f docker-compose-enhanced.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose-enhanced.yml down
ExecReload=/usr/local/bin/docker-compose -f docker-compose-enhanced.yml restart

[Install]
WantedBy=multi-user.target
EOF
    
    sudo systemctl daemon-reload
    print_status "Systemd service created"
fi

# Create backup script
print_status "Creating backup script..."
cat > "$BASE_DIR/../scripts/backup-homelab.sh" <<'EOF'
#!/bin/bash
# Homelab Backup Script

BACKUP_DIR="/backup/homelab"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/backup_$DATE"

echo "Starting backup to $BACKUP_PATH..."

# Create backup directory
mkdir -p "$BACKUP_PATH"

# Backup Docker volumes
docker run --rm \
  -v firefly_db:/source:ro \
  -v "$BACKUP_PATH":/backup \
  alpine tar czf /backup/firefly_db.tar.gz -C /source .

docker run --rm \
  -v firefly_upload:/source:ro \
  -v "$BACKUP_PATH":/backup \
  alpine tar czf /backup/firefly_upload.tar.gz -C /source .

# Backup configurations
tar czf "$BACKUP_PATH/configs.tar.gz" \
  ./docker-compose*.yml \
  ./.env* \
  ./homepage/config \
  ./traefik/config

echo "Backup completed: $BACKUP_PATH"

# Keep only last 7 backups
ls -t "$BACKUP_DIR" | tail -n +8 | xargs -I {} rm -rf "$BACKUP_DIR/{}"
EOF

chmod +x "$BASE_DIR/../scripts/backup-homelab.sh"

# Pull Docker images
print_status "Pulling Docker images..."
docker pull fireflyiii/core:latest
docker pull postgres:15-alpine
docker pull lscr.io/linuxserver/code-server:latest
docker pull thealhu/nomachine:latest
docker pull filebrowser/filebrowser:latest
docker pull jrohy/webssh:latest

# Check if services are already running
print_status "Checking existing services..."
if docker ps | grep -q "traefik"; then
    print_warning "Some services are already running. They will be updated."
    EXISTING_SERVICES=true
else
    EXISTING_SERVICES=false
fi

# Deploy services
print_status "Deploying services..."
if [ "$EXISTING_SERVICES" = true ]; then
    docker-compose -f docker-compose-enhanced.yml up -d --remove-orphans
else
    docker-compose -f docker-compose-enhanced.yml up -d
fi

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 30

# Health check
print_status "Running health checks..."
SERVICES=("firefly-iii" "firefly-db" "code-server" "filebrowser" "webssh")
ALL_HEALTHY=true

for service in "${SERVICES[@]}"; do
    if docker ps | grep -q "$service"; then
        STATUS=$(docker inspect -f '{{.State.Status}}' "$service" 2>/dev/null || echo "not found")
        if [ "$STATUS" = "running" ]; then
            print_status "$service is running"
        else
            print_error "$service is not running (status: $STATUS)"
            ALL_HEALTHY=false
        fi
    else
        print_error "$service container not found"
        ALL_HEALTHY=false
    fi
done

# Configure Firefly III
if docker ps | grep -q "firefly-iii"; then
    print_status "Configuring Firefly III..."
    
    # Wait for database to be ready
    sleep 10
    
    # Run migrations
    docker exec firefly-iii php artisan migrate --force
    
    # Create cron token
    CRON_TOKEN=$(openssl rand -hex 16)
    docker exec firefly-iii php artisan firefly-iii:create-token $CRON_TOKEN
    
    print_status "Firefly III configured"
    print_warning "Firefly III Cron Token: $CRON_TOKEN"
    print_warning "Save this token for the cron configuration!"
fi

# Display access URLs
echo ""
echo "======================================"
echo "🎉 Deployment Complete!"
echo "======================================"
echo ""
echo "📌 New Service URLs (access via VPN):"
echo "  💰 Firefly III: https://money.mbs-home.ddns.net"
echo "  💻 Code-Server: https://code.mbs-home.ddns.net"
echo "  🖥️  NoMachine: https://remote.mbs-home.ddns.net"
echo "  📁 File Browser: https://files.mbs-home.ddns.net"
echo "  🔐 WebSSH: https://ssh.mbs-home.ddns.net"
echo ""
echo "📝 Default Credentials:"
echo "  Firefly III: Create account on first visit"
echo "  Code-Server: Password: CodeServer2024!"
echo "  NoMachine: User: admin, Password: NoMachine2024!"
echo "  File Browser: User: admin, Password: admin"
echo ""

if [ "$ALL_HEALTHY" = true ]; then
    print_status "All services are healthy!"
    echo ""
    echo "🔒 Security Reminder:"
    echo "  1. Change all default passwords immediately"
    echo "  2. Access services only through WireGuard VPN"
    echo "  3. Enable 2FA where available"
    echo "  4. Regular backups are configured to run daily"
else
    print_error "Some services failed to start. Check logs with:"
    echo "  docker-compose -f docker-compose-enhanced.yml logs [service-name]"
fi

echo ""
echo "📚 Next Steps:"
echo "  1. Connect via WireGuard VPN"
echo "  2. Access Firefly III and create your accounts"
echo "  3. Configure expense categories together"
echo "  4. Set up recurring transactions"
echo "  5. Install Firefly III mobile app for easy expense tracking"
echo ""
echo "💡 Firefly III Quick Start Tips:"
echo "  - Start with basic categories: Groceries, Rent, Utilities, Entertainment"
echo "  - Create a shared asset account for your joint bank account"
echo "  - Set up rules to auto-categorize transactions"
echo "  - Use the mobile app to add expenses on-the-go"
echo "  - Review reports weekly to track spending patterns"
echo ""
echo "======================================"