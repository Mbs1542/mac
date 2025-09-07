#!/bin/bash

# ===================================================================
# MAC HOMELAB SETUP TEST SCRIPT
# ===================================================================
# This script tests the Mac homelab setup without starting services
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

echo "🧪 Testing Mac Homelab Setup"
echo "============================"

# Test 1: Check if running on macOS
print_status "Test 1: Checking macOS..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_success "Running on macOS"
else
    print_error "Not running on macOS!"
    exit 1
fi

# Test 2: Check Docker Desktop
print_status "Test 2: Checking Docker Desktop..."
if docker info >/dev/null 2>&1; then
    print_success "Docker Desktop is running"
else
    print_error "Docker Desktop is not running!"
    exit 1
fi

# Test 3: Check external drive
print_status "Test 3: Checking external drive..."
if [ -d "/Volumes/WorkDrive" ]; then
    print_success "External drive mounted at /Volumes/WorkDrive"
else
    print_error "External drive not mounted at /Volumes/WorkDrive!"
    print_warning "Please mount your external drive first"
    exit 1
fi

# Test 4: Check Docker file sharing
print_status "Test 4: Testing Docker file sharing..."
if docker run --rm -v /Volumes/WorkDrive/MacStorage/docker:/data alpine ls -la /data >/dev/null 2>&1; then
    print_success "Docker can access external drive"
else
    print_error "Docker cannot access external drive!"
    print_warning "Please configure Docker Desktop file sharing:"
    echo "  1. Open Docker Desktop"
    echo "  2. Go to Settings → Resources → File Sharing"
    echo "  3. Add: /Volumes/WorkDrive"
    echo "  4. Add: /Volumes/WorkDrive/MacStorage"
    echo "  5. Click 'Apply & Restart'"
    exit 1
fi

# Test 5: Check required files
print_status "Test 5: Checking required files..."
required_files=(
    "docker-compose-mac.yml"
    ".env.mac"
    "traefik/config/traefik-mac.yml"
    "traefik/config/dynamic-mac.yml"
    "mac-homelab-setup.sh"
    "deploy-mac-homelab.sh"
    "health-check-mac.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        print_success "Found $file"
    else
        print_error "Missing $file"
        exit 1
    fi
done

# Test 6: Check .env file
print_status "Test 6: Checking .env file..."
if [ -f ".env" ]; then
    print_success ".env file exists"
    
    # Check for required variables
    if grep -q "CF_API_EMAIL" .env && grep -q "CF_DNS_API_TOKEN" .env; then
        print_success "Required environment variables found"
    else
        print_warning "Please configure .env file with your values"
    fi
else
    print_warning ".env file not found, will be created from template"
fi

# Test 7: Check directory structure
print_status "Test 7: Checking directory structure..."
if [ -d "/Volumes/WorkDrive/MacStorage/docker" ]; then
    print_success "Docker directory exists on external drive"
else
    print_warning "Docker directory not found, will be created"
fi

# Test 8: Check Mac IP
print_status "Test 8: Getting Mac IP address..."
mac_ip_wifi=$(ipconfig getifaddr en0 2>/dev/null || echo "Not available")
mac_ip_ethernet=$(ipconfig getifaddr en1 2>/dev/null || echo "Not available")
echo "WiFi IP: $mac_ip_wifi"
echo "Ethernet IP: $mac_ip_ethernet"

if [ "$mac_ip_wifi" != "Not available" ] || [ "$mac_ip_ethernet" != "Not available" ]; then
    print_success "Mac IP address found"
else
    print_warning "Could not determine Mac IP address"
fi

# Test 9: Check Docker networks
print_status "Test 9: Checking Docker networks..."
networks=("homelab-main" "homelab-media" "homelab-mgmt" "homelab-db")
for network in "${networks[@]}"; do
    if docker network ls | grep -q "$network"; then
        print_success "Network $network exists"
    else
        print_warning "Network $network not found (will be created)"
    fi
done

# Test 10: Check file permissions
print_status "Test 10: Checking file permissions..."
if [ -f "/Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json" ]; then
    perms=$(stat -f "%OLp" /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json 2>/dev/null || echo "unknown")
    if [ "$perms" = "600" ]; then
        print_success "acme.json has correct permissions (600)"
    else
        print_warning "acme.json permissions: $perms (should be 600)"
    fi
else
    print_warning "acme.json not found (will be created)"
fi

echo ""
print_success "Setup test completed!"
echo ""
echo "Next steps:"
echo "1. If .env file is missing or incomplete, edit it with your values"
echo "2. Run: ./deploy-mac-homelab.sh"
echo "3. Configure router port forwarding (80, 443 → Mac IP)"
echo "4. Configure Cloudflare DNS (DNS only, not proxied)"
echo "5. Test: ./health-check-mac.sh"
echo ""
echo "Your Mac IP for router configuration: $mac_ip_wifi"