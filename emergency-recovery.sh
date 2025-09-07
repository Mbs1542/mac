#!/bin/bash

# CRITICAL HOMELAB RECOVERY SCRIPT
# Run this on your actual server to restore services

set -e

echo "🚨 CRITICAL HOMELAB RECOVERY STARTING 🚨"
echo "=========================================="

# Step 1: Stop everything and clean up
echo "Step 1: Stopping all containers and cleaning up..."
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker system prune -a --volumes -f 2>/dev/null || true

# Step 2: Create backup of current broken config
echo "Step 2: Creating backup of current configuration..."
mkdir -p ~/backup_broken_$(date +%Y%m%d_%H%M%S)
cp -r . ~/backup_broken_$(date +%Y%m%d_%H%M%S)/ 2>/dev/null || true

# Step 3: Create minimal working directories
echo "Step 3: Creating minimal working directories..."
mkdir -p traefik/config traefik/certificates
mkdir -p data/nextcloud data/jellyfin data/adguard
mkdir -p logs

# Step 4: Create minimal docker-compose.yml
echo "Step 4: Creating minimal docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

networks:
  proxy:
    driver: bridge

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"  # Traefik dashboard
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./traefik/config:/etc/traefik:ro
      - ./traefik/certificates:/certificates
    environment:
      - TZ=UTC
    command:
      - "--api.dashboard=true"
      - "--api.insecure=true"  # Only for development
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=proxy"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencrypt.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencrypt.acme.email=admin@mbs-home.ddns.net"
      - "--certificatesresolvers.letsencrypt.acme.storage=/certificates/acme.json"
      - "--log.level=INFO"
      - "--accesslog=true"
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=Host(`traefik.mbs-home.ddns.net`)"
      - "traefik.http.routers.traefik.entrypoints=websecure"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.tls.certresolver=letsencrypt"

  whoami:
    image: traefik/whoami
    container_name: whoami
    networks:
      - proxy
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.whoami.rule=Host(`whoami.mbs-home.ddns.net`) || Host(`mbs-home.ddns.net`)"
      - "traefik.http.routers.whoami.entrypoints=websecure"
      - "traefik.http.routers.whoami.tls.certresolver=letsencrypt"
EOF

# Step 5: Create Traefik configuration
echo "Step 5: Creating Traefik configuration..."
cat > traefik/config/traefik.yml << 'EOF'
api:
  dashboard: true
  debug: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

serversTransport:
  insecureSkipVerify: true

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: proxy

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@mbs-home.ddns.net
      storage: /certificates/acme.json
      caServer: https://acme-v02.api.letsencrypt.org/directory
      httpChallenge:
        entryPoint: web
EOF

# Step 6: Create acme.json with proper permissions
echo "Step 6: Creating acme.json with proper permissions..."
touch traefik/certificates/acme.json
chmod 600 traefik/certificates/acme.json

# Step 7: Start minimal services
echo "Step 7: Starting minimal services..."
docker-compose up -d

# Step 8: Wait and check status
echo "Step 8: Waiting for services to start..."
sleep 30

echo "Step 9: Checking service status..."
docker ps

echo "Step 10: Testing local access..."
curl -I http://localhost || echo "Local access failed"
curl -I http://localhost:8080 || echo "Traefik dashboard failed"

echo "Step 11: Checking Traefik logs..."
docker logs traefik --tail 20

echo "=========================================="
echo "🎉 RECOVERY COMPLETE! 🎉"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Check if Traefik is running: docker ps"
echo "2. Check Traefik logs: docker logs traefik"
echo "3. Test local access: curl http://localhost"
echo "4. Test Traefik dashboard: curl http://localhost:8080"
echo "5. Check external access: curl http://mbs-home.ddns.net"
echo ""
echo "If everything works, you can add more services one by one."
echo "If not, check the logs and network configuration."