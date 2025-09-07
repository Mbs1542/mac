#!/bin/bash

# ===================================================================
# MAC HOMELAB EXTERNAL DRIVE SETUP SCRIPT
# ===================================================================
# This script sets up the Mac homelab with external drive support
# Run this script to configure Docker Desktop and fix permissions
# ===================================================================

set -e

echo "🚀 Starting Mac Homelab External Drive Setup..."
echo "=============================================="

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

print_status "Docker Desktop is running ✓"

# Check if external drive is mounted
if [ ! -d "/Volumes/WorkDrive" ]; then
    print_warning "External drive '/Volumes/WorkDrive' is not mounted!"
    print_status "Please mount your external drive and ensure it's accessible at /Volumes/WorkDrive"
    print_status "You can check mounted drives with: mount | grep WorkDrive"
    read -p "Press Enter when the drive is mounted, or Ctrl+C to exit..."
fi

if [ ! -d "/Volumes/WorkDrive/MacStorage" ]; then
    print_status "Creating MacStorage directory structure..."
    mkdir -p /Volumes/WorkDrive/MacStorage/docker
    print_success "Created directory structure"
fi

# Create necessary directories
print_status "Creating required directories..."
mkdir -p /Volumes/WorkDrive/MacStorage/docker/{traefik/{config,certificates},nextcloud/{config,data,custom_apps,themes,postgres,redis},jellyfin/{config,cache},authelia,vaultwarden,adguard/{work,conf},wireguard/config,portainer,homepage/config,grafana/{data,config},prometheus/{config,data,blackbox},homeassistant,scripts,logs/homelab-reports,ai-local/open-webui}

# Set proper permissions
print_status "Setting file permissions..."
chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json 2>/dev/null || true
chmod 755 /Volumes/WorkDrive/MacStorage/docker/traefik/config
chmod 755 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates

# Fix ownership
print_status "Fixing ownership..."
sudo chown -R $(whoami):staff /Volumes/WorkDrive/MacStorage/docker/

print_success "Directory structure and permissions configured"

# Check Docker Desktop file sharing
print_status "Checking Docker Desktop file sharing configuration..."
print_warning "IMPORTANT: You need to manually configure Docker Desktop file sharing:"
echo ""
echo "1. Open Docker Desktop"
echo "2. Go to Settings → Resources → File Sharing"
echo "3. Add these paths:"
echo "   - /Volumes/WorkDrive"
echo "   - /Volumes/WorkDrive/MacStorage"
echo "4. Click 'Apply & Restart'"
echo ""

# Test Docker access to external drive
print_status "Testing Docker access to external drive..."
if docker run --rm -v /Volumes/WorkDrive/MacStorage/docker:/data alpine ls -la /data >/dev/null 2>&1; then
    print_success "Docker can access external drive ✓"
else
    print_error "Docker cannot access external drive!"
    print_warning "Please ensure Docker Desktop file sharing is configured correctly"
    exit 1
fi

# Create Docker networks
print_status "Creating Docker networks..."
docker network create homelab-main 2>/dev/null || print_warning "Network homelab-main already exists"
docker network create homelab-media 2>/dev/null || print_warning "Network homelab-media already exists"
docker network create homelab-mgmt 2>/dev/null || print_warning "Network homelab-mgmt already exists"
docker network create homelab-db 2>/dev/null || print_warning "Network homelab-db already exists"

print_success "Docker networks created"

# Check Mac firewall
print_status "Checking Mac firewall..."
firewall_state=$(sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -o "enabled\|disabled" || echo "unknown")

if [ "$firewall_state" = "enabled" ]; then
    print_warning "Mac firewall is enabled. Adding Docker to firewall exceptions..."
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Docker.app 2>/dev/null || true
    sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /Applications/Docker.app 2>/dev/null || true
    print_success "Docker added to firewall exceptions"
else
    print_status "Mac firewall is $firewall_state"
fi

# Get Mac's local IP
print_status "Getting Mac's local IP address..."
mac_ip_wifi=$(ipconfig getifaddr en0 2>/dev/null || echo "Not available")
mac_ip_ethernet=$(ipconfig getifaddr en1 2>/dev/null || echo "Not available")

echo "WiFi IP: $mac_ip_wifi"
echo "Ethernet IP: $mac_ip_ethernet"

# Create acme.json if it doesn't exist
if [ ! -f "/Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json" ]; then
    print_status "Creating acme.json file..."
    touch /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
    chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
    print_success "Created acme.json with correct permissions"
fi

print_success "Mac homelab setup completed!"
echo ""
echo "Next steps:"
echo "1. Ensure Docker Desktop file sharing is configured (see instructions above)"
echo "2. Configure your router to forward ports 80 and 443 to your Mac's IP: $mac_ip_wifi"
echo "3. Set up Cloudflare DNS with 'DNS only' (gray cloud) for mbs-home.ddns.net"
echo "4. Run: docker-compose up -d"
echo ""
echo "For troubleshooting, run: ./health-check.sh"