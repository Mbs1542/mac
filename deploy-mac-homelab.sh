#!/bin/bash

# ===================================================================
# MAC HOMELAB DEPLOYMENT SCRIPT
# ===================================================================
# This script deploys the Mac homelab with proper startup sequence
# Run this script after setting up Docker Desktop and external drive
# ===================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🚀 Deploying Mac Homelab..."
echo "=========================="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only!"
    exit 1
fi

# Check if Docker Desktop is running
if ! docker info >/dev/null 2>&1; then
    print_error "Docker Desktop is not running! Please start Docker Desktop first."
    exit 1
fi

# Check if external drive is mounted
if [ ! -d "/Volumes/WorkDrive" ]; then
    print_error "External drive '/Volumes/WorkDrive' is not mounted!"
    print_status "Please mount your external drive and run the setup script first:"
    echo "  ./mac-homelab-setup.sh"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found. Creating from template..."
    cp .env.mac .env
    print_warning "Please edit .env file with your actual values before continuing!"
    print_status "Required values:"
    echo "  - CF_API_EMAIL (your email)"
    echo "  - CF_DNS_API_TOKEN (Cloudflare API token)"
    echo "  - All password fields"
    echo ""
    read -p "Press Enter after editing .env file, or Ctrl+C to exit..."
fi

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
    print_success "Environment variables loaded"
else
    print_error ".env file not found!"
    exit 1
fi

# Create necessary directories
print_status "Creating required directories..."
mkdir -p /Volumes/WorkDrive/MacStorage/docker/{traefik/{config,certificates},nextcloud/{config,data,custom_apps,themes,postgres,redis},jellyfin/{config,cache},authelia,vaultwarden,adguard/{work,conf},portainer,homepage/config}

# Set proper permissions
print_status "Setting file permissions..."
chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json 2>/dev/null || true
chmod 755 /Volumes/WorkDrive/MacStorage/docker/traefik/config
chmod 755 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates

# Fix ownership
print_status "Fixing ownership..."
sudo chown -R $(whoami):staff /Volumes/WorkDrive/MacStorage/docker/

# Copy Traefik configuration
print_status "Setting up Traefik configuration..."
cp traefik/config/traefik-mac.yml /Volumes/WorkDrive/MacStorage/docker/traefik/config/traefik.yml
cp traefik/config/dynamic-mac.yml /Volumes/WorkDrive/MacStorage/docker/traefik/config/dynamic.yml

# Create acme.json if it doesn't exist
if [ ! -f "/Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json" ]; then
    print_status "Creating acme.json file..."
    touch /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
    chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
fi

# Create Docker networks
print_status "Creating Docker networks..."
docker network create homelab-main 2>/dev/null || print_warning "Network homelab-main already exists"
docker network create homelab-media 2>/dev/null || print_warning "Network homelab-media already exists"
docker network create homelab-mgmt 2>/dev/null || print_warning "Network homelab-mgmt already exists"
docker network create homelab-db 2>/dev/null || print_warning "Network homelab-db already exists"

# Clean up any existing containers
print_status "Cleaning up existing containers..."
docker-compose -f docker-compose-mac.yml down 2>/dev/null || true

# Start services in proper order
print_status "Starting services in deployment order..."

# 1. Start Traefik first
print_status "Starting Traefik..."
docker-compose -f docker-compose-mac.yml up -d traefik
sleep 10

# Check Traefik health
if docker logs traefik 2>&1 | grep -q "Configuration loaded"; then
    print_success "Traefik started successfully"
else
    print_warning "Traefik may have issues, checking logs..."
    docker logs traefik --tail 10
fi

# 2. Start database services
print_status "Starting database services..."
docker-compose -f docker-compose-mac.yml up -d nextcloud-db nextcloud-redis
sleep 15

# 3. Start core services
print_status "Starting core services..."
docker-compose -f docker-compose-mac.yml up -d nextcloud authelia vaultwarden
sleep 20

# 4. Start remaining services
print_status "Starting remaining services..."
docker-compose -f docker-compose-mac.yml up -d

# Wait for all services to start
print_status "Waiting for all services to start..."
sleep 30

# Check service status
print_status "Checking service status..."
echo ""
echo "Running containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# Test local connectivity
print_status "Testing local connectivity..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 >/dev/null 2>&1; then
    print_success "Traefik dashboard accessible at http://localhost:8080"
else
    print_warning "Traefik dashboard not accessible locally"
fi

# Get Mac's local IP
mac_ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "unknown")
print_status "Mac local IP: $mac_ip"

print_success "Mac homelab deployment completed!"
echo ""
echo "Next steps:"
echo "1. Configure your router to forward ports 80 and 443 to Mac IP: $mac_ip"
echo "2. Set up Cloudflare DNS with 'DNS only' (gray cloud) for mbs-home.ddns.net"
echo "3. Test external access: https://mbs-home.ddns.net"
echo "4. Run health check: ./health-check-mac.sh"
echo ""
echo "Service URLs (once DNS is configured):"
echo "  - https://mbs-home.ddns.net (Nextcloud/Homepage)"
echo "  - https://jellyfin.mbs-home.ddns.net (Jellyfin)"
echo "  - https://vault.mbs-home.ddns.net (Vaultwarden)"
echo "  - https://auth.mbs-home.ddns.net (Authelia)"
echo "  - https://traefik.mbs-home.ddns.net (Traefik Dashboard)"
echo "  - https://portainer.mbs-home.ddns.net (Portainer)"
echo ""
echo "Local access:"
echo "  - Traefik Dashboard: http://localhost:8080"
echo "  - Portainer: http://localhost:9000"