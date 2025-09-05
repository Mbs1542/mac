#!/bin/bash

# ================================================================
# סקריפט פריסת Homelab - Docker Swarm
# מיועד לפתור את הבעיות שזוהו בניתוח המערכת
# ================================================================

set -e  # יציאה בשגיאה

# צבעים לפלט
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # ללא צבע

# פונקציות עזר
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# בדיקת דרישות מקדימות
check_prerequisites() {
    log_info "בודק דרישות מקדימות..."
    
    # בדיקת Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker לא מותקן במערכת"
        exit 1
    fi
    
    # בדיקת Docker Compose
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose לא זמין"
        exit 1
    fi
    
    # בדיקת Docker Swarm
    if ! docker node ls &> /dev/null; then
        log_warning "Docker Swarm לא מופעל. מפעיל עכשיו..."
        docker swarm init --advertise-addr $(docker info --format '{{.Swarm.NodeAddr}}' || echo "127.0.0.1")
        log_success "Docker Swarm הופעל בהצלחה"
    fi
    
    log_success "כל הדרישות מקוימות"
}

# ניקוי containers ישנים
cleanup_old_containers() {
    log_info "מנקה containers ו-resources ישנים..."
    
    # עצירת כל השירותים הקיימים
    log_info "עוצר שירותים קיימים..."
    docker service ls --format "{{.Name}}" | grep "homelab_" | xargs -r docker service rm || true
    
    # המתנה לעצירה מלאה
    sleep 10
    
    # ניקוי containers יצאו
    log_info "מנקה containers שיצאו..."
    docker container prune -f
    
    # ניקוי volumes לא בשימוש
    log_info "מנקה volumes לא בשימוש..."
    docker volume prune -f
    
    # ניקוי images לא בשימוש
    log_info "מנקה images לא בשימוש..."
    docker image prune -f
    
    # ניקוי רשתות לא בשימוש
    log_info "מנקה רשתות לא בשימוש..."
    docker network prune -f
    
    log_success "ניקוי הושלם בהצלחה"
}

# יצירת רשתות Docker
create_networks() {
    log_info "יוצר רשתות Docker..."
    
    # רשת frontend (חיצונית)
    if ! docker network ls | grep -q "frontend"; then
        docker network create --driver overlay --attachable frontend
        log_success "רשת frontend נוצרה"
    else
        log_warning "רשת frontend כבר קיימת"
    fi
    
    # רשת backend (פנימית)
    if ! docker network ls | grep -q "backend"; then
        docker network create --driver overlay --internal backend
        log_success "רשת backend נוצרה"
    else
        log_warning "רשת backend כבר קיימת"
    fi
    
    # רשת management
    if ! docker network ls | grep -q "management"; then
        docker network create --driver overlay --attachable management
        log_success "רשת management נוצרה"
    else
        log_warning "רשת management כבר קיימת"
    fi
}

# יצירת תיקיות נדרשות
create_directories() {
    log_info "יוצר תיקיות נדרשות..."
    
    BASE_PATH="/Volumes/WorkDrive/MacStorage/docker"
    
    # רשימת תיקיות נדרשות
    directories=(
        "$BASE_PATH/traefik/config"
        "$BASE_PATH/traefik/certificates"
        "$BASE_PATH/adguard/work"
        "$BASE_PATH/adguard/conf"
        "$BASE_PATH/portainer"
        "$BASE_PATH/homepage/config"
        "$BASE_PATH/jellyfin/config"
        "$BASE_PATH/jellyfin/cache"
        "$BASE_PATH/sonarr/config"
        "$BASE_PATH/radarr/config"
        "$BASE_PATH/lidarr/config"
        "$BASE_PATH/bazarr/config"
        "$BASE_PATH/prowlarr/config"
        "$BASE_PATH/transmission/config"
        "$BASE_PATH/wireguard/config"
        "$BASE_PATH/slskd/config"
        "$BASE_PATH/ai-local/open-webui"
        "/Volumes/WorkDrive/MacStorage/Downloads/watch"
        "/Volumes/WorkDrive/MacStorage/Downloads/slskd"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            # הגדרת הרשאות מתאימות
            chmod 755 "$dir"
            log_success "תיקייה נוצרה: $dir"
        else
            log_warning "תיקייה כבר קיימת: $dir"
        fi
    done
}

# יצירת קובצי קונפיגורציה בסיסיים
create_configs() {
    log_info "יוצר קובצי קונפיגורציה בסיסיים..."
    
    TRAEFIK_CONFIG="/Volumes/WorkDrive/MacStorage/docker/traefik/config"
    
    # Traefik static config
    cat > "$TRAEFIK_CONFIG/traefik.yml" << 'EOF'
# Static configuration
global:
  checkNewVersion: false
  sendAnonymousUsage: false

api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entryPoint:
          to: websecure
          scheme: https
          permanent: true
  websecure:
    address: ":443"

providers:
  docker:
    swarmMode: true
    exposedByDefault: false
    network: frontend
    endpoint: "unix:///var/run/docker.sock"

certificatesResolvers:
  letsencrypt:
    acme:
      httpChallenge:
        entryPoint: web
      email: admin@mbs-home.ddns.net
      storage: /certificates/acme.json

log:
  level: INFO
  format: common

accessLog:
  format: common
EOF
    
    # הגדרת הרשאות מתאימות לקובץ ACME
    touch "$TRAEFIK_CONFIG/../certificates/acme.json"
    chmod 600 "$TRAEFIK_CONFIG/../certificates/acme.json"
    
    log_success "קובצי קונפיגורציה נוצרו"
}

# בדיקת חיבור לאינטרנט
check_internet() {
    log_info "בודק חיבור לאינטרנט..."
    
    if ! ping -c 1 google.com &> /dev/null; then
        log_error "אין חיבור לאינטרנט. נדרש לעדכון images"
        exit 1
    fi
    
    log_success "חיבור לאינטרנט תקין"
}

# הורדת Docker images מראש
pull_images() {
    log_info "מוריד Docker images נדרשים..."
    
    images=(
        "traefik:v3.0"
        "adguard/adguardhome:latest"
        "weejewel/wg-easy:latest"
        "portainer/portainer-ce:latest"
        "ghcr.io/gethomepage/homepage:latest"
        "jellyfin/jellyfin:latest"
        "lscr.io/linuxserver/sonarr:latest"
        "lscr.io/linuxserver/radarr:latest"
        "ghcr.io/hotio/lidarr:pr-plugins-1c21412"
        "lscr.io/linuxserver/bazarr:latest"
        "lscr.io/linuxserver/prowlarr:latest"
        "ghcr.io/flaresolverr/flaresolverr:latest"
        "lscr.io/linuxserver/transmission:latest"
        "slskd/slskd:latest"
        "ghcr.io/open-webui/open-webui:main"
        "containrrr/watchtower:latest"
        "amir20/dozzle:latest"
    )
    
    for image in "${images[@]}"; do
        log_info "מוריד: $image"
        docker pull "$image"
    done
    
    log_success "כל ה-images הורדו בהצלחה"
}

# פריסת השירותים
deploy_stack() {
    log_info "מפריס את ה-homelab stack..."
    
    if [ ! -f "homelab-compose.yml" ]; then
        log_error "קובץ homelab-compose.yml לא נמצא"
        exit 1
    fi
    
    # פריסה עם Docker Stack
    docker stack deploy -c homelab-compose.yml homelab
    
    log_success "Stack נפרס בהצלחה!"
}

# המתנה לשירותים
wait_for_services() {
    log_info "ממתין להעלת השירותים..."
    
    # המתנה לטעינה ראשונית
    sleep 30
    
    # בדיקת סטטוס שירותים
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local running_services=$(docker service ls --filter "label=com.docker.stack.namespace=homelab" --format "{{.Replicas}}" | grep -c "1/1" || echo 0)
        local total_services=$(docker service ls --filter "label=com.docker.stack.namespace=homelab" | wc -l | tr -d ' ')
        total_services=$((total_services - 1))  # הסרת כותרת
        
        if [ $running_services -eq $total_services ] && [ $total_services -gt 0 ]; then
            log_success "כל השירותים פועלים תקין!"
            break
        fi
        
        log_info "ממתין... ($running_services/$total_services שירותים מוכנים) - ניסיון $attempt/$max_attempts"
        sleep 10
        attempt=$((attempt + 1))
    done
    
    if [ $attempt -gt $max_attempts ]; then
        log_warning "חלק מהשירותים עדיין לא מוכנים. בדוק ידנית עם 'docker service ls'"
    fi
}

# הצגת מידע על השירותים
show_services_info() {
    log_info "מידע על השירותים:"
    echo "================================"
    
    cat << 'EOF'
🌐 כתובות הגישה:
- Dashboard: https://mbs-home.ddns.net (או http://dashboard.local)
- Traefik: https://traefik.mbs-home.ddns.net
- Portainer: https://portainer.mbs-home.ddns.net
- AdGuard: https://dns.mbs-home.ddns.net
- VPN: https://vpn.mbs-home.ddns.net
- Media: https://media.mbs-home.ddns.net
- Logs: https://logs.mbs-home.ddns.net

📱 Media Management:
- Sonarr: https://sonarr.mbs-home.ddns.net
- Radarr: https://radarr.mbs-home.ddns.net  
- Lidarr: https://lidarr.mbs-home.ddns.net
- Bazarr: https://bazarr.mbs-home.ddns.net
- Prowlarr: https://prowlarr.mbs-home.ddns.net
- Transmission: https://transmission.mbs-home.ddns.net

🤖 AI Tools:
- Open-WebUI: https://ai.mbs-home.ddns.net

📊 ניטור:
- Docker service ls
- docker stack ps homelab
- docker service logs homelab_[service_name]
EOF
    
    echo "================================"
    log_success "פריסה הושלמה בהצלחה!"
}

# פונקציה עיקרית
main() {
    log_info "מתחיל פריסת Homelab Docker Stack..."
    echo "===================================="
    
    # בדיקת אם המשתמש רוצה לנקות
    if [[ "${1:-}" == "--clean" ]]; then
        log_warning "מצב ניקוי מופעל - ימחק את כל השירותים הקיימים!"
        read -p "האם אתה בטוח? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "פעולה בוטלה"
            exit 0
        fi
        cleanup_old_containers
    fi
    
    # ביצוע שלבי הפריסה
    check_prerequisites
    check_internet
    create_networks
    create_directories
    create_configs
    pull_images
    deploy_stack
    wait_for_services
    show_services_info
    
    log_success "הכל הושלם בהצלחה! 🎉"
}

# הפעלת הסקריפט
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi