#!/bin/bash

# Test script to verify recovery
echo "🧪 TESTING HOMELAB RECOVERY 🧪"
echo "==============================="

# Test 1: Check if Docker is running
echo "Test 1: Checking Docker status..."
if docker ps >/dev/null 2>&1; then
    echo "✅ Docker is running"
    docker ps
else
    echo "❌ Docker is not running"
    echo "Run: sudo systemctl start docker"
    exit 1
fi

echo ""

# Test 2: Check if containers are running
echo "Test 2: Checking container status..."
if docker ps | grep -q traefik; then
    echo "✅ Traefik is running"
else
    echo "❌ Traefik is not running"
    echo "Run: docker-compose up -d"
    exit 1
fi

if docker ps | grep -q whoami; then
    echo "✅ Whoami test service is running"
else
    echo "❌ Whoami test service is not running"
fi

echo ""

# Test 3: Check local access
echo "Test 3: Testing local access..."
if curl -s -I http://localhost | grep -q "200 OK"; then
    echo "✅ Local HTTP access works"
else
    echo "❌ Local HTTP access failed"
fi

if curl -s -I http://localhost:8080 | grep -q "200 OK"; then
    echo "✅ Traefik dashboard accessible"
else
    echo "❌ Traefik dashboard not accessible"
fi

echo ""

# Test 4: Check Traefik logs
echo "Test 4: Checking Traefik logs..."
echo "Last 10 lines of Traefik logs:"
docker logs traefik --tail 10

echo ""

# Test 5: Check network
echo "Test 5: Checking Docker network..."
docker network inspect proxy 2>/dev/null || echo "❌ Proxy network not found"

echo ""

# Test 6: Check external access
echo "Test 6: Testing external access..."
PUBLIC_IP=$(curl -s ifconfig.me)
echo "Public IP: $PUBLIC_IP"

if curl -s -I http://mbs-home.ddns.net | grep -q "200 OK"; then
    echo "✅ External access to mbs-home.ddns.net works"
else
    echo "❌ External access to mbs-home.ddns.net failed"
    echo "Check DNS and port forwarding"
fi

echo ""

# Test 7: Check DNS resolution
echo "Test 7: Checking DNS resolution..."
if nslookup mbs-home.ddns.net >/dev/null 2>&1; then
    echo "✅ DNS resolution works"
    nslookup mbs-home.ddns.net
else
    echo "❌ DNS resolution failed"
fi

echo ""
echo "==============================="
echo "🎯 RECOVERY TEST COMPLETE 🎯"
echo "==============================="
echo ""
echo "If all tests pass, your homelab is recovered!"
echo "If any tests fail, check the specific error messages above."
echo ""
echo "Next steps:"
echo "1. If basic tests pass, add Nextcloud"
echo "2. If external access fails, check router port forwarding"
echo "3. If DNS fails, check Cloudflare settings"