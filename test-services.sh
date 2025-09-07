#!/usr/bin/env bash
set -euo pipefail

echo "Testing service connectivity..."

declare -A services=(
  ["Traefik"]="http://localhost:8080"
  ["Nextcloud"]="http://localhost:80"
  ["Jellyfin"]="http://localhost:8096"
  ["Vaultwarden"]="http://localhost:80"
  ["Home Assistant"]="http://localhost:8123"
  ["Portainer"]="http://localhost:9000"
)

for name in "${!services[@]}"; do
  url=${services[$name]}
  if curl -s -o /dev/null -w "%{http_code}" "$url" | grep -q "200\|301\|302"; then
    echo "✅ $name is responding"
  else
    echo "❌ $name is not responding"
  fi
done

