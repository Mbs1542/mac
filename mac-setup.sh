#!/usr/bin/env bash
set -euo pipefail

# Safety backup
BACKUP_DIR="/Volumes/WorkDrive/MacStorage/docker_backup_$(date +%Y%m%d_%H%M%S)"
echo "Creating safety backup at $BACKUP_DIR..."
cp -R /Volumes/WorkDrive/MacStorage/docker "$BACKUP_DIR"
echo "Backup completed. Original data safe at: $BACKUP_DIR"

echo "=== CHECKING EXISTING DATA ==="
CRITICAL_DATA=(
  "/Volumes/WorkDrive/MacStorage/docker/vaultwarden/db.sqlite3"
  "/Volumes/WorkDrive/MacStorage/docker/nextcloud/config/config.php"
  "/Volumes/WorkDrive/MacStorage/docker/jellyfin/config/system.xml"
  "/Volumes/WorkDrive/MacStorage/docker/homeassistant/configuration.yaml"
  "/Volumes/WorkDrive/MacStorage/docker/authelia/configuration.yml"
)

echo "Checking critical data files..."
for file in "${CRITICAL_DATA[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ Found: $file"
  else
    echo "⚠️  Missing: $file (will be created on first run)"
  fi
done

echo -e "\nChecking docker directories..."
for dir in /Volumes/WorkDrive/MacStorage/docker/*/; do
  if [ -d "$dir" ]; then
    echo "✅ Directory exists: $dir"
    du -sh "$dir" 2>/dev/null | head -1
  fi
done

echo "Starting services in safe order..."
docker compose up -d traefik || docker-compose up -d traefik
sleep 5
docker compose up -d nextcloud-db nextcloud-redis firefly-db || docker-compose up -d nextcloud-db nextcloud-redis firefly-db
sleep 10

echo "Waiting for databases to be ready..."
until docker exec nextcloud-db pg_isready >/dev/null 2>&1; do
  echo "Waiting for PostgreSQL..."
  sleep 2
done

docker compose up -d nextcloud vaultwarden authelia || docker-compose up -d nextcloud vaultwarden authelia
docker compose up -d || docker-compose up -d

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

