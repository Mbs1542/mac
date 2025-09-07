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

echo "Public URL Availability:"
urls=(
  "mbs-home.ddns.net"
  "nextcloud.mbs-home.ddns.net"
  "jellyfin.mbs-home.ddns.net"
  "vault.mbs-home.ddns.net"
  "auth.mbs-home.ddns.net"
  "home.mbs-home.ddns.net"
  "manage.mbs-home.ddns.net"
  "monitor.mbs-home.ddns.net"
  "sonarr.mbs-home.ddns.net"
  "radarr.mbs-home.ddns.net"
  "torrent.mbs-home.ddns.net"
  "dns.mbs-home.ddns.net"
)
for host in "${urls[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" https://"$host" || true)
  echo "$host: HTTP ${code:-N/A}"
done