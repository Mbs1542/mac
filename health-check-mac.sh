#!/bin/bash

# ===================================================================
# MAC HOMELAB HEALTH CHECK SCRIPT
# ===================================================================
# This script checks the health of all homelab services
# Run this script to diagnose issues and verify service status
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

echo "🏥 Mac Homelab Health Check"
echo "============================"
echo "Date: $(date)"
echo ""

# Check if Docker is running
print_status "Checking Docker Desktop..."
if docker info >/dev/null 2>&1; then
    print_success "Docker Desktop is running"
else
    print_error "Docker Desktop is not running!"
    exit 1
fi

# Check external drive mount
print_status "Checking external drive mount..."
if [ -d "/Volumes/WorkDrive" ]; then
    print_success "External drive is mounted at /Volumes/WorkDrive"
    if [ -d "/Volumes/WorkDrive/MacStorage/docker" ]; then
        print_success "Docker directory exists on external drive"
    else
        print_warning "Docker directory not found on external drive"
    fi
else
    print_error "External drive not mounted at /Volumes/WorkDrive!"
    print_warning "Please mount your external drive and run the setup script"
fi

# Check Docker networks
print_status "Checking Docker networks..."
networks=("homelab-main" "homelab-media" "homelab-mgmt" "homelab-db")
for network in "${networks[@]}"; do
    if docker network ls | grep -q "$network"; then
        print_success "Network $network exists"
    else
        print_warning "Network $network not found"
    fi
done

# Check running containers
print_status "Checking running containers..."
echo ""
echo "Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -20
echo ""

# Check disk space
print_status "Checking disk space..."
echo "External Drive Usage:"
df -h /Volumes/WorkDrive 2>/dev/null || print_warning "Cannot check external drive usage"
echo ""

# Check Mac's local IP
print_status "Getting Mac's local IP address..."
mac_ip_wifi=$(ipconfig getifaddr en0 2>/dev/null || echo "Not available")
mac_ip_ethernet=$(ipconfig getifaddr en1 2>/dev/null || echo "Not available")
echo "WiFi IP: $mac_ip_wifi"
echo "Ethernet IP: $mac_ip_ethernet"
echo ""

# Check router port forwarding (manual check)
print_status "Router Port Forwarding Check:"
print_warning "Manual verification required:"
echo "1. Check your router settings"
echo "2. Ensure ports 80 and 443 are forwarded to Mac IP: $mac_ip_wifi"
echo "3. Verify Cloudflare DNS settings (DNS only, not proxied)"
echo ""

# Check service health
print_status "Checking service health..."
services=("traefik" "nextcloud" "jellyfin" "vaultwarden" "authelia" "adguard-home" "portainer" "homepage")

for service in "${services[@]}"; do
    if docker ps | grep -q "$service"; then
        print_success "$service is running"
        # Check if service is healthy
        if docker inspect "$service" | grep -q '"Health": "healthy"'; then
            print_success "$service is healthy"
        else
            print_warning "$service is running but not healthy"
        fi
    else
        print_error "$service is not running"
    fi
done

echo ""

# Check service logs for errors
print_status "Checking recent service logs for errors..."
for service in "${services[@]}"; do
    if docker ps | grep -q "$service"; then
        echo "--- $service logs (last 5 lines) ---"
        docker logs "$service" --tail 5 2>/dev/null | grep -i error || echo "No errors found"
        echo ""
    fi
done

# Test local connectivity
print_status "Testing local connectivity..."
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 >/dev/null 2>&1; then
    print_success "Traefik dashboard accessible locally"
else
    print_warning "Traefik dashboard not accessible locally"
fi

# Test external connectivity (if domain is configured)
print_status "Testing external connectivity..."
if command -v nslookup >/dev/null 2>&1; then
    if nslookup mbs-home.ddns.net >/dev/null 2>&1; then
        print_success "DNS resolution working for mbs-home.ddns.net"
        
        # Test HTTPS connectivity
        if curl -s -o /dev/null -w "%{http_code}" https://mbs-home.ddns.net >/dev/null 2>&1; then
            response_code=$(curl -s -o /dev/null -w "%{http_code}" https://mbs-home.ddns.net)
            if [ "$response_code" = "200" ]; then
                print_success "HTTPS connectivity working (HTTP $response_code)"
            else
                print_warning "HTTPS connectivity issue (HTTP $response_code)"
            fi
        else
            print_warning "HTTPS connectivity failed"
        fi
    else
        print_warning "DNS resolution failed for mbs-home.ddns.net"
    fi
else
    print_warning "nslookup not available, skipping DNS test"
fi

echo ""
print_status "Health check completed!"
echo ""
echo "If you're experiencing issues:"
echo "1. Check Docker Desktop file sharing settings"
echo "2. Verify external drive is mounted and accessible"
echo "3. Check router port forwarding (80, 443 → Mac IP)"
echo "4. Verify Cloudflare DNS settings (DNS only, not proxied)"
echo "5. Check service logs: docker logs <service-name>"
echo ""
echo "For detailed troubleshooting, run:"
echo "  docker-compose logs <service-name>"
echo "  docker system df"
echo "  docker system prune -f  # Clean up if needed"