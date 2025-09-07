#!/usr/bin/env bash
set -euo pipefail

ROOT="/Volumes/WorkDrive/MacStorage/docker"

echo "Creating directory structure under $ROOT ..."
mkdir -p "$ROOT/traefik/config" "$ROOT/traefik/certificates" \
         "$ROOT/nextcloud/html" "$ROOT/nextcloud/config" "$ROOT/nextcloud/data" "$ROOT/nextcloud/postgres" \
         "$ROOT/jellyfin/config" "$ROOT/jellyfin/cache" \
         "$ROOT/authelia" \
         "$ROOT/vaultwarden" \
         "$ROOT/adguard/work" "$ROOT/adguard/conf" \
         "$ROOT/homeassistant" \
         "$ROOT/portainer" \
         "$ROOT/prometheus/config" "$ROOT/prometheus/data" \
         "$ROOT/grafana/data" "$ROOT/grafana/config" \
         "$ROOT/sonarr/config" "$ROOT/radarr/config" "$ROOT/qbittorrent/config"

# Media and downloads directories (outside docker root)
mkdir -p \
  "/Volumes/WorkDrive/MacStorage/media/tv" \
  "/Volumes/WorkDrive/MacStorage/media/movies" \
  "/Volumes/WorkDrive/MacStorage/downloads"

echo "Ensuring acme.json exists with correct permissions ..."
touch "$ROOT/traefik/certificates/acme.json"
chmod 600 "$ROOT/traefik/certificates/acme.json"

echo "Setting Traefik config permissions ..."
chmod 755 "$ROOT/traefik/config" || true

echo "Copying config files ..."
cp -f traefik/config/traefik.yml "$ROOT/traefik/config/traefik.yml"
cp -f traefik/config/dynamic.yml "$ROOT/traefik/config/dynamic.yml"

echo "Verifying services (if running) ..."
services=(traefik nextcloud jellyfin vaultwarden homeassistant portainer grafana sonarr radarr qbittorrent adguardhome authelia)
for service in "${services[@]}"; do
  if docker ps --format '{{.Names}}' | grep -q "^$service$"; then
    echo "✓ $service is running"
  else
    echo "✗ $service is NOT running"
  fi
done

echo "Reminder: In Docker Desktop → Settings → Resources → File Sharing, add:"
echo "  - /Volumes/WorkDrive"
echo "  - /Volumes/WorkDrive/MacStorage"
echo "Then click 'Apply & Restart'"

echo "Done. Place docker-compose.yml and .env in the project directory you will run from."

