#!/bin/bash

# ===================================================================
# Docker Homelab Deployment Script
# אוטומציה מלאה לפריסת כל השירותים
# ===================================================================

set -e  # עצור בשגיאה

# צבעים לפלט
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}🚀 Docker Homelab Deployment Script${NC}"
echo -e "${GREEN}=====================================${NC}"

# בדיקה אם Docker Swarm פעיל
check_swarm() {
    echo -e "\n${YELLOW}🔍 בודק Docker Swarm...${NC}"
    if ! docker info | grep -q "Swarm: active"; then
        echo -e "${YELLOW}⚡ מפעיל Docker Swarm...${NC}"
        docker swarm init
        echo -e "${GREEN}✅ Docker Swarm הופעל${NC}"
    else
        echo -e "${GREEN}✅ Docker Swarm כבר פעיל${NC}"
    fi
}

# יצירת רשתות overlay
create_networks() {
    echo -e "\n${YELLOW}🌐 יוצר רשתות...${NC}"
    
    networks=("web-overlay" "media-overlay" "management")
    
    for network in "${networks[@]}"; do
        if docker network ls | grep -q "$network"; then
            echo -e "${GREEN}✅ רשת $network כבר קיימת${NC}"
        else
            docker network create --driver overlay --attachable "$network"
            echo -e "${GREEN}✅ רשת $network נוצרה${NC}"
        fi
    done
}

# יצירת תיקיות נדרשות
create_directories() {
    echo -e "\n${YELLOW}📁 יוצר תיקיות...${NC}"
    
    base_path="/Volumes/WorkDrive/MacStorage"
    
    # רשימת תיקיות
    directories=(
        "$base_path/docker/traefik/config"
        "$base_path/docker/traefik/certificates"
        "$base_path/docker/adguard/work"
        "$base_path/docker/adguard/conf"
        "$base_path/docker/wireguard/config"
        "$base_path/docker/portainer"
        "$base_path/docker/homepage/config"
        "$base_path/docker/jellyfin/config"
        "$base_path/docker/jellyfin/cache"
        "$base_path/docker/sonarr/config"
        "$base_path/docker/radarr/config"
        "$base_path/docker/lidarr/config"
        "$base_path/docker/bazarr/config"
        "$base_path/docker/prowlarr/config"
        "$base_path/docker/transmission/config"
        "$base_path/docker/slskd/config"
        "$base_path/docker/ai-local/open-webui"
        "$base_path/Downloads/slskd"
        "$base_path/Downloads/watch"
        "$base_path/Media/Movies"
        "$base_path/Media/TV"
        "$base_path/Media/Music"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✅ תיקייה נוצרה: $dir${NC}"
        else
            echo -e "   תיקייה קיימת: $dir"
        fi
    done
}

# הגדרת permissions
set_permissions() {
    echo -e "\n${YELLOW}🔐 מגדיר הרשאות...${NC}"
    
    # הגדר PUID ו-PGID
    PUID=1000
    PGID=1000
    
    # תיקיות שצריכות הרשאות
    permission_dirs=(
        "/Volumes/WorkDrive/MacStorage/docker"
        "/Volumes/WorkDrive/MacStorage/Downloads"
        "/Volumes/WorkDrive/MacStorage/Media"
    )
    
    for dir in "${permission_dirs[@]}"; do
        if [ -d "$dir" ]; then
            chown -R $PUID:$PGID "$dir" 2>/dev/null || true
            echo -e "${GREEN}✅ הרשאות הוגדרו ל: $dir${NC}"
        fi
    done
}

# ניקוי containers ישנים
cleanup_old() {
    echo -e "\n${YELLOW}🧹 מנקה containers ישנים...${NC}"
    
    # עצור containers רצים
    if [ "$(docker ps -q)" ]; then
        echo -e "${YELLOW}   עוצר containers...${NC}"
        docker stop $(docker ps -q) 2>/dev/null || true
    fi
    
    # הסר containers מופסקים
    if [ "$(docker ps -aq)" ]; then
        echo -e "${YELLOW}   מסיר containers...${NC}"
        docker rm $(docker ps -aq) 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ ניקוי הושלם${NC}"
}

# פריסת ה-Stack
deploy_stack() {
    echo -e "\n${YELLOW}🚀 פורס את ה-Stack...${NC}"
    
    if [ ! -f "unified-compose-final.yml" ]; then
        echo -e "${RED}❌ קובץ unified-compose-final.yml לא נמצא!${NC}"
        exit 1
    fi
    
    # הסר stack קיים אם יש
    if docker stack ls | grep -q "homelab"; then
        echo -e "${YELLOW}   מסיר stack קיים...${NC}"
        docker stack rm homelab
        sleep 10
    fi
    
    # פרוס את ה-stack
    docker stack deploy -c unified-compose-final.yml homelab
    
    echo -e "${GREEN}✅ Stack נפרס בהצלחה!${NC}"
}

# בדיקת סטטוס
check_status() {
    echo -e "\n${YELLOW}📊 בודק סטטוס...${NC}"
    
    sleep 5
    
    echo -e "\n${GREEN}שירותים רצים:${NC}"
    docker stack services homelab
    
    echo -e "\n${GREEN}Containers:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# הצג URLs
show_urls() {
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}🌐 URLs לגישה לשירותים:${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${YELLOW}🏠 דשבורד ראשי:${NC}"
    echo -e "   Homepage: http://mbs-home.ddns.net"
    echo -e "   Homepage (local): http://dashboard.local"
    
    echo -e "\n${YELLOW}🔧 ניהול:${NC}"
    echo -e "   Traefik: https://traefik.mbs-home.ddns.net"
    echo -e "   Portainer: https://portainer.mbs-home.ddns.net"
    echo -e "   AdGuard: http://192.168.1.191:3000"
    echo -e "   WireGuard: https://vpn.mbs-home.ddns.net"
    
    echo -e "\n${YELLOW}🎬 מדיה:${NC}"
    echo -e "   Jellyfin: https://media.mbs-home.ddns.net"
    echo -e "   Sonarr: https://sonarr.mbs-home.ddns.net"
    echo -e "   Radarr: https://radarr.mbs-home.ddns.net"
    echo -e "   Lidarr: https://lidarr.mbs-home.ddns.net"
    echo -e "   Bazarr: https://bazarr.mbs-home.ddns.net"
    echo -e "   Prowlarr: https://prowlarr.mbs-home.ddns.net"
    
    echo -e "\n${YELLOW}📥 הורדות:${NC}"
    echo -e "   Transmission: https://transmission.mbs-home.ddns.net"
    echo -e "   Slskd: https://slskd.mbs-home.ddns.net"
    
    echo -e "\n${YELLOW}🤖 AI:${NC}"
    echo -e "   Open WebUI: https://ai.mbs-home.ddns.net"
}

# פונקציה ראשית
main() {
    echo -e "${YELLOW}האם לנקות containers ישנים? (y/n)${NC}"
    read -r clean_choice
    
    if [[ $clean_choice == "y" ]]; then
        cleanup_old
    fi
    
    check_swarm
    create_networks
    create_directories
    set_permissions
    deploy_stack
    check_status
    show_urls
    
    echo -e "\n${GREEN}=====================================${NC}"
    echo -e "${GREEN}✅ הפריסה הושלמה בהצלחה!${NC}"
    echo -e "${GREEN}=====================================${NC}"
    
    echo -e "\n${YELLOW}💡 טיפים:${NC}"
    echo -e "   • צפה בלוגים: docker service logs homelab_traefik -f"
    echo -e "   • בדוק סטטוס: docker stack ps homelab"
    echo -e "   • עדכן שירות: docker service update homelab_jellyfin --force"
    echo -e "   • הסר הכל: docker stack rm homelab"
}

# הרץ את הפונקציה הראשית
main