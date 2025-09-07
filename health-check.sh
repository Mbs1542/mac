#!/bin/bash
# בדיקת תקינות שירותים (גרסה מתוקנת)

echo "🏥 בדיקת תקינות שירותים..."

# בדיקה אם Docker Swarm פעיל
if ! docker node ls > /dev/null 2>&1; then
    echo "❌ Docker Swarm לא פעיל"
    exit 1
fi

# בדיקת שירותים ב-Docker Swarm
echo "📊 בדיקת שירותי Docker Swarm:"
docker service ls --format "table {{.Name}}\t{{.Replicas}}\t{{.Image}}"

echo ""
echo "🔍 בדיקת סטטוס מפורט:"

services=(
    "homelab_traefik"
    "homelab_homepage" 
    "homelab_authelia"
    "homelab_portainer"
    "homelab_jellyfin"
    "homelab_sonarr"
    "homelab_radarr"
    "homelab_lidarr"
    "homelab_bazarr"
    "homelab_prowlarr"
    "homelab_transmission"
    "homelab_slskd"
    "homelab_open-webui"
    "homelab_wireguard"
    "homelab_adguard"
)

for service in "${services[@]}"; do
    if docker service ls --filter name=$service --format "{{.Name}}" | grep -q $service; then
        replicas=$(docker service ls --filter name=$service --format "{{.Replicas}}")
        if [[ $replicas == *"1/1"* ]] || [[ $replicas == *"1/1"* ]]; then
            echo "✅ $service - תקין ($replicas)"
        else
            echo "⚠️  $service - חלקי ($replicas)"
        fi
    else
        echo "❌ $service - לא נמצא"
    fi
done

echo ""
echo "🌐 בדיקת נגישות HTTP:"

# בדיקת נגישות HTTP (רק אם השירותים פועלים)
http_services=(
    "traefik:8080"
    "homepage:3000"
    "authelia:9091"
    "portainer:9000"
    "jellyfin:8096"
)

for service in "${http_services[@]}"; do
    name=$(echo $service | cut -d: -f1)
    port=$(echo $service | cut -d: -f2)
    
    if timeout 5 curl -s -o /dev/null -w "%{http_code}" "http://localhost:$port" | grep -q "200\|302\|401\|404"; then
        echo "✅ $name - נגיש ב-HTTP"
    else
        echo "❌ $name - לא נגיש ב-HTTP"
    fi
done

echo ""
echo "📋 סיכום:"
echo "   - בדוק את הלוגים של שירותים בעייתיים:"
echo "     docker service logs homelab_<service-name>"
echo "   - בדוק את סטטוס הרשתות:"
echo "     docker network ls"
echo "   - בדוק את הנפחים:"
echo "     docker volume ls"