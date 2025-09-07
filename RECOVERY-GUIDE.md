# 🚨 CRITICAL HOMELAB RECOVERY GUIDE 🚨

## Current Situation
- **SEVERITY: CRITICAL** - Entire homelab is DOWN for 2 days
- **Main Issue**: mbs-home.ddns.net returns 404 - NOTHING is accessible
- **Failed Services**: Nextcloud, Jellyfin, AdGuard Home, all web services

## IMMEDIATE ACTION REQUIRED

### Option 1: QUICK RECOVERY (Recommended)

Run the emergency recovery script on your server:

```bash
# Download and run the recovery script
chmod +x emergency-recovery.sh
./emergency-recovery.sh
```

### Option 2: MANUAL STEP-BY-STEP RECOVERY

#### Step 1: Stop Everything and Clean Up
```bash
# Stop all containers
docker-compose down
docker stop $(docker ps -aq)
docker system prune -a --volumes -f

# Backup current broken config
mkdir -p ~/backup_broken_$(date +%Y%m%d_%H%M%S)
cp -r . ~/backup_broken_$(date +%Y%m%d_%H%M%S)/
```

#### Step 2: Create Minimal Working Configuration
```bash
# Create directories
mkdir -p traefik/config traefik/certificates
mkdir -p data/nextcloud data/jellyfin data/adguard

# Create minimal docker-compose.yml (see below)
# Create Traefik config (see below)
```

#### Step 3: Create Minimal docker-compose.yml
```yaml
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
```

#### Step 4: Create Traefik Configuration
Create `traefik/config/traefik.yml`:
```yaml
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
```

#### Step 5: Set Up Permissions
```bash
# Create acme.json with proper permissions
touch traefik/certificates/acme.json
chmod 600 traefik/certificates/acme.json
```

#### Step 6: Start Services
```bash
# Start minimal services
docker-compose up -d

# Wait for services to start
sleep 30

# Check status
docker ps
```

#### Step 7: Test Everything
```bash
# Test local access
curl -I http://localhost
curl -I http://localhost:8080

# Check Traefik logs
docker logs traefik --tail 20

# Test external access
curl -I http://mbs-home.ddns.net
```

## CRITICAL DEBUGGING COMMANDS

```bash
# 1. Check what's running
docker ps -a

# 2. Check Traefik logs
docker logs traefik --tail 100 -f

# 3. Check network
docker network inspect proxy

# 4. Check DNS resolution
dig mbs-home.ddns.net

# 5. Check local access
curl -I http://localhost
curl -I https://localhost -k

# 6. Check Traefik discovered services
curl http://localhost:8080/api/http/routers | jq

# 7. Check from inside container
docker exec traefik ping whoami
docker exec traefik wget -O- http://whoami

# 8. Check firewall
sudo iptables -L -n
sudo ufw status
```

## IF NOTHING WORKS - EMERGENCY RECOVERY

```bash
# 1. Create a simple HTML file to test
mkdir -p emergency_www
echo "<h1>Server is alive</h1>" > emergency_www/index.html

# 2. Run a simple nginx without Traefik
docker run -d -p 80:80 -v $(pwd)/emergency_www:/usr/share/nginx/html:ro nginx

# 3. Check if accessible
curl http://mbs-home.ddns.net

# If this works, the issue is Traefik config
# If this doesn't work, the issue is network/DNS/firewall
```

## COMMON ISSUES AND FIXES

### 1. Port 80/443 already in use:
```bash
sudo lsof -i :80
sudo lsof -i :443
sudo systemctl stop apache2  # or nginx
```

### 2. DNS not updating:
```bash
# Force DDNS update
curl "https://api.cloudflare.com/client/v4/zones/YOUR_ZONE_ID/dns_records/YOUR_RECORD_ID" \
  -X PUT \
  -H "Authorization: Bearer YOUR_API_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"mbs-home","content":"YOUR_PUBLIC_IP","ttl":120}'
```

### 3. Docker network issues:
```bash
docker network rm proxy
docker network create proxy
docker-compose restart
```

## REPORT BACK WITH:

1. Output of `docker ps`
2. Output of `docker logs traefik --tail 50`
3. Output of `curl http://localhost`
4. Your public IP: `curl ifconfig.me`
5. DNS check: `nslookup mbs-home.ddns.net`

## IMPORTANT:

- Work on ONE service at a time
- Test locally FIRST before external
- Don't add Authelia until everything else works
- Keep the configuration SIMPLE initially

## NEXT STEPS AFTER RECOVERY:

Once the basic setup is working:

1. **Add Nextcloud** (most important service)
2. **Add AdGuard Home** (DNS filtering)
3. **Add Jellyfin** (media server)
4. **Add other services one by one**

Each service should be added individually and tested before adding the next one.

---

**🚨 CRITICAL: Start with the emergency recovery script and report the output of each step! 🚨**