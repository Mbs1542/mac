#!/usr/bin/env bash
set -euo pipefail

echo "⚠️  EMERGENCY ROLLBACK"
echo "This will stop all containers and restore from backup"
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
  docker compose down || docker-compose down

  echo "Available backups:"
  ls -la /Volumes/WorkDrive/MacStorage/ | grep docker_backup_ || true

  read -p "Enter backup directory name to restore (e.g., docker_backup_YYYYMMDD_HHMMSS): " backup_dir

  if [ -d "/Volumes/WorkDrive/MacStorage/$backup_dir" ]; then
    mv /Volumes/WorkDrive/MacStorage/docker /Volumes/WorkDrive/MacStorage/docker_broken_$(date +%Y%m%d_%H%M%S)
    cp -R "/Volumes/WorkDrive/MacStorage/$backup_dir" /Volumes/WorkDrive/MacStorage/docker
    echo "Restored from backup: $backup_dir"
  else
    echo "Backup directory not found: $backup_dir"
    exit 1
  fi
fi

