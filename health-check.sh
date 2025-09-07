#!/bin/bash
set -euo pipefail

echo "=== Homelab Health Check ==="
echo "Date: $(date)"
echo ""

echo "Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "Disk Usage:"
df -h /Volumes/WorkDrive || true
echo ""

echo "Service Availability:"
services=("mbs-home.ddns.net" "nextcloud.mbs-home.ddns.net" "jellyfin.mbs-home.ddns.net" "vault.mbs-home.ddns.net" "auth.mbs-home.ddns.net")
for service in "${services[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" https://"$service" || true)
  echo "$service: HTTP ${code:-N/A}"
done

#!/bin/bash
# בדיקת תקינות שירותים (גרסה מתוקנת)

echo "🏥 בדיקת תקינות שירותים..."

# Added the /ping path to the Traefik check
services=(
    "traefik-gateway:8080/api/rawdata" 
    "jellyfin:8096" 
    "sonarr:8989" 
    "radarr:7878" 
    "lidarr:8686" 
    "homepage:3000"
)

for service in "${services[@]}"; do
    # This logic correctly separates the name from the address (port and path)
    name=$(echo $service | cut -d: -f1)
    address=$(echo $service | cut -d: -f2-)
    
    if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$address" | grep -q "200\|302\|401"; then
        echo "✅ $name - תקין"
    else
        echo "❌ $name - לא תקין או לא זמין"
    fi
done