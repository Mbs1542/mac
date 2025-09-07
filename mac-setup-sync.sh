#!/usr/bin/env bash
set -euo pipefail

ROOT="/Volumes/WorkDrive/MacStorage/docker"

echo "Creating directory structure under $ROOT ..."
mkdir -p "$ROOT/traefik/config" "$ROOT/traefik/certificates" \
         "$ROOT/nextcloud/html" "$ROOT/nextcloud/config" "$ROOT/nextcloud/data" "$ROOT/nextcloud/postgres" \
         "$ROOT/jellyfin/config" "$ROOT/jellyfin/cache" "$ROOT/media" \
         "$ROOT/authelia" \
         "$ROOT/vaultwarden" \
         "$ROOT/adguard/work" "$ROOT/adguard/conf"

echo "Ensuring acme.json exists with correct permissions ..."
touch "$ROOT/traefik/certificates/acme.json"
chmod 600 "$ROOT/traefik/certificates/acme.json"

echo "Setting Traefik config permissions ..."
chmod 755 "$ROOT/traefik/config" || true

echo "Copying config files ..."
cp -f traefik/config/traefik.yml "$ROOT/traefik/config/traefik.yml"
cp -f traefik/config/dynamic.yml "$ROOT/traefik/config/dynamic.yml"

echo "Reminder: In Docker Desktop → Settings → Resources → File Sharing, add:"
echo "  - /Volumes/WorkDrive"
echo "  - /Volumes/WorkDrive/MacStorage"
echo "Then click 'Apply & Restart'"

echo "Done. Place docker-compose.yml and .env in the project directory you will run from."

