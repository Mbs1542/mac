#!/bin/bash

# ===================================================================
# Homelab Deployment Script - v2.2 COMPLETE
# סקריפט פריסה מלא עם כל התיקונים והיצירת הקונפיגורציות
# ===================================================================

set -e  # יציאה במקרה של שגיאה

# צבעים לפלט יפה
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# פונקציה להדפסה עם צבעים
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

print_header() {
    echo -e "\n${BLUE}======================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}======================================${NC}\n"
}

# נתיבים בסיסיים
BASE_PATH="/Volumes/WorkDrive/MacStorage/docker"
BACKUP_PATH="/Volumes/WorkDrive/MacStorage/backups/docker"

print_header "🚀 התחלת פריסת Homelab"

# 1. יצירת גיבוי של המערכת הנוכחית
print_status "יוצר גיבוי של המערכת הנוכחית..."
DATE=$(date +%Y%m%d-%H%M%S)
mkdir -p "$BACKUP_PATH"

if [ -d "$BASE_PATH" ]; then
    cp -r "$BASE_PATH" "$BACKUP_PATH/docker-backup-$DATE"
    print_success "גיבוי נוצר ב: $BACKUP_PATH/docker-backup-$DATE"
fi

# 2. עצירת השירותים הנוכחיים
print_status "עוצר את כל השירותים הנוכחיים..."

# עצירת Docker Stack
if docker stack ls | grep -q homelab; then
    print_status "עוצר Docker Stack..."
    docker stack rm homelab
    sleep 30  # המתנה לעצירה מלאה
fi

# עצירת containers בודדים
print_status "עוצר containers בודדים..."
docker stop portainer 2>/dev/null || true
docker rm portainer 2>/dev/null || true

print_success "כל השירותים נעצרו"

# 3. יצירת מבני התיקיות הנדרשים
print_header "📁 יוצר מבני תיקיות"

SERVICES=(
    "traefik/config"
    "traefik/certificates"
    "adguard/work"
    "adguard/conf"
    "wireguard/config"
    "portainer"
    "homepage/config"
    "jellyfin/config"
    "jellyfin/cache"
    "sonarr/config"
    "radarr/config"
    "lidarr/config"
    "bazarr/config"
    "prowlarr/config"
    "transmission/config"
    "slskd/config"
    "ai-local/open-webui"
    "prometheus/config"
    "prometheus/data"
    "grafana/config"
    "grafana/data"
)

for service in "${SERVICES[@]}"; do
    mkdir -p "$BASE_PATH/$service"
    print_status "נוצרה תיקיה: $service"
done

# 4. יצירת קונפיגורציית Traefik
print_status "יוצר קונפיגורציית Traefik..."

cat > "$BASE_PATH/traefik/config/traefik.yml" << 'EOF'
# Traefik Configuration
global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: true
  debug: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    swarmMode: true
    exposedByDefault: false
    network: web-overlay
    watch: true
  file:
    filename: /etc/traefik/dynamic.yml
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com  # שנה את זה לאימייל שלך!
      storage: /certificates/acme.json
      httpChallenge:
        entryPoint: web

log:
  level: INFO
  format: json

accessLog:
  format: json

metrics:
  prometheus:
    addEntryPointsLabels: true
    addServicesLabels: true
EOF

# יצירת קובץ dynamic configuration
cat > "$BASE_PATH/traefik/config/dynamic.yml" << 'EOF'
# Dynamic Configuration
http:
  middlewares:
    secure-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - OPTIONS
          - PUT
          - POST
        accessControlMaxAge: 100
        hostsProxyHeaders:
          - "X-Forwarded-Host"
        referrerPolicy: "same-origin"
        sslRedirect: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
        contentTypeNosniff: true
        browserXssFilter: true
        forceSTSHeader: true
        frameDeny: true

    auth:
      basicAuth:
        users:
          - "admin:$2y$10$H5g7Xo8U.A2Xy1.l4q5yT.K9j5gqO8nO"  # admin/admin123

    local-only:
      ipWhiteList:
        sourceRange:
          - "192.168.0.0/16"
          - "10.0.0.0/8"
          - "172.16.0.0/12"
          - "127.0.0.1/32"

tls:
  options:
    default:
      sslProtocols:
        - "TLSv1.2"
        - "TLSv1.3"
      minVersion: "VersionTLS12"
      cipherSuites:
        - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        - "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
        - "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
        - "TLS_RSA_WITH_AES_256_GCM_SHA384"
        - "TLS_RSA_WITH_AES_128_GCM_SHA256"
EOF

# קביעת הרשאות נכונות לקבצי התעודות
touch "$BASE_PATH/traefik/certificates/acme.json"
chmod 600 "$BASE_PATH/traefik/certificates/acme.json"

print_success "קונפיגורציית Traefik נוצרה"

# 5. יצירת קונפיגורציית Prometheus
print_status "יוצר קונפיגורציית Prometheus..."

cat > "$BASE_PATH/prometheus/config/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']

  - job_name: 'docker'
    static_configs:
      - targets: ['docker.for.mac.localhost:9323']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

print_success "קונפיגורציית Prometheus נוצרה"

# 6. הגדרת הרשאות נכונות
print_status "מגדיר הרשאות לתיקיות..."

# הגדרת הרשאות עבור WireGuard
chown -R $(id -u):$(id -g) "$BASE_PATH/wireguard" 2>/dev/null || true
chmod -R 755 "$BASE_PATH/wireguard"

# הגדרת הרשאות עבור Prometheus
chown -R 65534:65534 "$BASE_PATH/prometheus/data" 2>/dev/null || true

# הגדרת הרשאות עבור Grafana
chown -R 472:472 "$BASE_PATH/grafana" 2>/dev/null || true

print_success "הרשאות הוגדרו"

# 7. יצירת קונפיגורציית Homepage
print_status "יוצר קונפיגורציית Homepage..."

mkdir -p "$BASE_PATH/homepage/config"

cat > "$BASE_PATH/homepage/config/settings.yaml" << 'EOF'
title: Maor Homelab
subtitle: Personal Media & Services Hub
language: he
theme: dark

layout:
  Media:
    style: row
    columns: 3
  Downloads:
    style: row  
    columns: 3
  Management:
    style: row
    columns: 3
  AI & Tools:
    style: row
    columns: 2
EOF

cat > "$BASE_PATH/homepage/config/services.yaml" << 'EOF'
- Media:
    - Jellyfin:
        icon: jellyfin.png
        href: http://jellyfin.local
        description: Media Server
        server: my-docker
        container: homelab_jellyfin

    - Sonarr:
        icon: sonarr.png
        href: http://sonarr.local
        description: TV Shows
        server: my-docker
        container: homelab_sonarr

    - Radarr:
        icon: radarr.png
        href: http://radarr.local
        description: Movies
        server: my-docker
        container: homelab_radarr

- Downloads:
    - Transmission:
        icon: transmission.png
        href: http://transmission.local
        description: Torrents
        server: my-docker
        container: homelab_transmission

    - Prowlarr:
        icon: prowlarr.png
        href: http://prowlarr.local
        description: Indexers
        server: my-docker
        container: homelab_prowlarr

    - SoulSeek:
        icon: slskd.png
        href: http://slskd.local
        description: Music Sharing
        server: my-docker
        container: homelab_slskd

- Management:
    - Portainer:
        icon: portainer.png
        href: http://portainer.local
        description: Container Management
        server: my-docker
        container: homelab_portainer

    - Traefik:
        icon: traefik.png
        href: http://traefik.local
        description: Reverse Proxy
        server: my-docker
        container: homelab_traefik

    - AdGuard:
        icon: adguard-home.png
        href: http://adguard.local
        description: DNS & Ad Blocker
        server: my-docker
        container: homelab_adguard

- AI & Tools:
    - Open WebUI:
        icon: openai.png
        href: http://ai.local
        description: AI Chat Interface
        server: my-docker
        container: homelab_open-webui

    - WireGuard:
        icon: wireguard.png
        href: http://vpn.local
        description: VPN Server
        server: my-docker
        container: homelab_wireguard
EOF

cat > "$BASE_PATH/homepage/config/docker.yaml" << 'EOF'
my-docker:
  socket: /var/run/docker.sock
EOF

print_success "קונפיגורציית Homepage נוצרה"

# 8. יצירת רשתות Docker
print_status "יוצר רשתות Docker..."

# יצירת overlay networks אם לא קיימות
docker network create --driver overlay --attachable web-overlay 2>/dev/null || print_warning "רשת web-overlay כבר קיימת"
docker network create --driver overlay --attachable media-overlay 2>/dev/null || print_warning "רשת media-overlay כבר קיימת"
docker network create --driver overlay --attachable --encrypted management 2>/dev/null || print_warning "רשת management כבר קיימת"

print_success "רשתות נוצרו"

# 9. פריסת המערכת החדשה
print_header "🚀 פורס את המערכת החדשה"

# בדיקה אם קובץ הcompose קיים
COMPOSE_FILE="unified-compose.yml"
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "קובץ $COMPOSE_FILE לא נמצא במיקום הנוכחי"
    print_status "יוצר קובץ compose דוגמא..."
    
    # יצירת קובץ compose מקוצר לבדיקה
    cat > "$COMPOSE_FILE" << 'EOF'
version: '3.8'

networks:
  web-overlay:
    driver: overlay
    encrypted: true
    attachable: true

services:
  traefik:
    image: traefik:v3.0
    networks:
      - web-overlay
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /Volumes/WorkDrive/MacStorage/docker/traefik/config:/etc/traefik:ro
      - /Volumes/WorkDrive/MacStorage/docker/traefik/certificates:/certificates
    environment:
      - TZ=Asia/Jerusalem
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.docker.swarmmode=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.traefik.rule=Host(\`traefik.local\`)"
        - "traefik.http.routers.traefik.service=api@internal"
EOF
    
    print_warning "נוצר קובץ compose בסיסי. השתמש בקובץ המלא שלך לפריסה מלאה"
fi

print_status "פורס את Docker Stack..."
docker stack deploy -c "$COMPOSE_FILE" homelab

# המתנה לעלייה של השירותים
print_status "ממתין לעלייה של השירותים..."
sleep 30

# 10. בדיקת סטטוס השירותים
print_header "🔍 בודק סטטוס השירותים"

print_status "רשימת שירותים:"
docker service ls

print_status "בדיקת שירותים שלא עלו:"
FAILED_SERVICES=$(docker service ls --format "table {{.Name}}\t{{.Replicas}}" | grep "0/")
if [ ! -z "$FAILED_SERVICES" ]; then
    print_warning "שירותים שלא עלו:"
    echo "$FAILED_SERVICES"
    
    print_status "מציג לוגים של שירותים כושלים..."
    docker service ls --format "{{.Name}}" | while read service; do
        replicas=$(docker service ls --filter name=$service --format "{{.Replicas}}")
        if [[ $replicas == *"0/"* ]]; then
            print_warning "לוגים של $service:"
            docker service logs --tail 10 $service
        fi
    done
fi

# 11. בדיקת קישוריות
print_header "🌐 בודק קישוריות"

print_status "בדיקת פורטים פתוחים:"
netstat -tlnp 2>/dev/null | grep -E ':(80|443|8080|9443|51820)' || print_warning "חלק מהפורטים לא פתוחים"

# 12. יצירת סקריפטי עזר
print_status "יוצר סקריפטי עזר..."

# סקריפט לניטור המערכת
cat > "homelab-monitor.sh" << 'EOF'
#!/bin/bash
echo "=== Homelab Status ==="
echo "Docker Services:"
docker service ls

echo -e "\n=== Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo -e "\n=== Failed Services ==="
docker service ls --format "table {{.Name}}\t{{.Replicas}}" | grep "0/"

echo -e "\n=== Network Status ==="
docker network ls | grep overlay
EOF

chmod +x homelab-monitor.sh

# סקריפט לגיבוי
cat > "homelab-backup.sh" << 'EOF'
#!/bin/bash
BACKUP_DIR="/Volumes/WorkDrive/MacStorage/backups/docker"
DATE=$(date +%Y%m%d-%H%M%S)

echo "יוצר גיבוי מלא..."
rsync -av /Volumes/WorkDrive/MacStorage/docker/ "$BACKUP_DIR/docker-backup-$DATE/"

echo "מנקה גיבויים ישנים (מעל 7 ימים)..."
find "$BACKUP_DIR" -name "docker-backup-*" -mtime +7 -exec rm -rf {} \;

echo "גיבוי הושלם: $BACKUP_DIR/docker-backup-$DATE"
EOF

chmod +x homelab-backup.sh

# סקריפט לעדכון המערכת
cat > "homelab-update.sh" << 'EOF'
#!/bin/bash
echo "מעדכן את כל השירותים..."

# עצירת המערכת
docker stack rm homelab
sleep 30

# משיכת תמונות עדכניות
docker pull traefik:v3.0
docker pull portainer/portainer-ce:latest
docker pull adguard/adguardhome:latest
docker pull jellyfin/jellyfin:latest
docker pull ghcr.io/open-webui/open-webui:main

# הפעלה מחדש
docker stack deploy -c unified-compose.yml homelab

echo "עדכון הושלם"
EOF

chmod +x homelab-update.sh

print_success "סקריפטי עזר נוצרו"

# 13. הגדרת DNS מקומי (אופציונלי)
print_status "מכין הגדרות DNS מקומיות..."

cat > "local-dns-setup.txt" << 'EOF'
# הוספה ל/etc/hosts עבור גישה מקומית
127.0.0.1 home.local
127.0.0.1 media.local jellyfin.local
127.0.0.1 sonarr.local
127.0.0.1 radarr.local
127.0.0.1 lidarr.local
127.0.0.1 bazarr.local
127.0.0.1 prowlarr.local
127.0.0.1 transmission.local
127.0.0.1 slskd.local
127.0.0.1 ai.local chat.local
127.0.0.1 portainer.local
127.0.0.1 traefik.local
127.0.0.1 adguard.local
127.0.0.1 vpn.local

# להוספה ב-AdGuard DNS Rewrites:
home.local -> 192.168.1.191
media.local -> 192.168.1.191
traefik.local -> 192.168.1.191
# וכו...
EOF

# 14. הצגת סיכום
print_header "✅ פריסה הושלמה!"

cat << EOF
📋 סיכום הפעולות שבוצעו:
1. ✅ יצירת גיבוי של המערכת הקיימת
2. ✅ עצירת שירותים ישנים
3. ✅ יצירת מבני תיקיות חדשים
4. ✅ הגדרת קונפיגורציות Traefik
5. ✅ יצירת רשתות Docker
6. ✅ פריסת המערכת החדשה
7. ✅ יצירת סקריפטי עזר

🌐 כתובות גישה:
- Dashboard: http://home.local
- Portainer: http://portainer.local
- Traefik: http://traefik.local:8080
- Jellyfin: http://media.local
- AI Chat: http://ai.local

🔧 סקריפטים שנוצרו:
- homelab-monitor.sh - ניטור המערכת
- homelab-backup.sh - יצירת גיבויים
- homelab-update.sh - עדכון השירותים

📝 הצעדים הבאים:
1. בדוק שכל השירותים רצים: ./homelab-monitor.sh
2. הגדר DNS מקומי (ראה local-dns-setup.txt)
3. קבע את האימייל ב-traefik.yml עבור Let's Encrypt
4. הגדר AdGuard עם הכתובות המקומיות

⚠️  אם יש שירותים שלא עלו:
docker service logs <service-name>
docker service update --force <service-name>

EOF

print_success "סקריפט הפריסה הושלם בהצלחה!"