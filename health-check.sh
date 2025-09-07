#!/bin/bash
# בדיקת תקינות שירותים (גרסה מתוקנת)

echo "🏥 בדיקת תקינות שירותים..."

# בדיקות ברירת מחדל דרך Traefik ופורטים פנימיים ידועים
checks=(
  # Traefik ping endpoint
  "Traefik:http://localhost:8080/ping"
  # Homepage דרך Traefik (Host header)
  "Homepage:https://mbs-home.ddns.net"
  # Media apps (ייתכן שרצים רק ברשת פנימית ולכן הבדיקה דרך Traefik)
  "Jellyfin:https://media.mbs-home.ddns.net"
  "Sonarr:https://sonarr.mbs-home.ddns.net"
  "Radarr:https://radarr.mbs-home.ddns.net"
  "Lidarr:https://lidarr.mbs-home.ddns.net"
)

for item in "${checks[@]}"; do
  name="${item%%:*}"
  url="${item#*:}"

  # אם זו כתובת HTTPS מקומית מאחורי Traefik, נרכך אימות TLS (לבדיקות מקומיות בלבד)
  if echo "$url" | grep -q "^https://"; then
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 -k "$url")
  else
    code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "$url")
  fi

  if echo "$code" | grep -qE "^(200|301|302|307|308|401)$"; then
    echo "✅ $name - תקין ($code)"
  else
    echo "❌ $name - לא תקין או לא זמין ($code)"
  fi
done