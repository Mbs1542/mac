#!/bin/bash
# בדיקת תקינות שירותים (גרסה מתוקנת)

echo "🏥 בדיקת תקינות שירותים..."

# Added the /ping path to the Traefik check
services=(
    "traefik-gateway:8080/ping" 
    "jellyfin:8096" 
    "sonarr:8989" 
    "radarr:7878" 
    "lidarr:8686" 
    "homepage:3030"
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