## macOS Homelab on External Drive (Docker Desktop + Traefik)

This repo contains a working configuration for running your homelab on macOS using Docker Desktop with data on an external drive mounted at `/Volumes/WorkDrive/MacStorage/docker/`.

### Prerequisites
- macOS with Docker Desktop installed
- External drive mounted at `/Volumes/WorkDrive`
- Cloudflare account and API token for DNS-01 ACME

### Layout
- `docker-compose.yml` — services with Mac paths
- `traefik/config/traefik.yml` and `traefik/config/dynamic.yml`
- `.env.example` — copy to `.env` and fill in values
- `mac-setup-sync.sh` — creates directories and sets permissions
- `health-check.sh` — quick status script
  - Checks: traefik, nextcloud, jellyfin, vaultwarden, authelia, homeassistant, portainer, grafana, sonarr, radarr, qbittorrent, adguardhome

### Step-by-step
1) Verify mount and list data directory:
```
mount | grep WorkDrive
ls -la /Volumes/WorkDrive/MacStorage/docker/
```

2) Enable Docker Desktop File Sharing:
- Docker Desktop → Settings → Resources → File Sharing
- Add:
  - `/Volumes/WorkDrive`
  - `/Volumes/WorkDrive/MacStorage`
- Apply & Restart

3) Prepare directories and permissions:
```
bash mac-setup-sync.sh
```

4) Set critical permissions and ownership (if needed):
```
chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
chmod 755 /Volumes/WorkDrive/MacStorage/docker/traefik/config
sudo chown -R $(whoami):staff /Volumes/WorkDrive/MacStorage/docker/
```

5) Copy `.env.example` to `.env` and fill:
```
cp .env.example .env
```
Fill `CF_API_EMAIL`, `CF_DNS_API_TOKEN`, `NEXTCLOUD_DB_PASSWORD`, `TZ`.

6) Networks and firewall:
```
docker network create proxy || true
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Docker.app
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /Applications/Docker.app
```

7) Startup sequence:
```
docker compose down || docker-compose down
docker system prune -f

docker compose up -d traefik || docker-compose up -d traefik
sleep 10
docker logs traefik

open http://localhost:8080/dashboard/

docker compose up -d nextcloud-db nextcloud-redis || docker-compose up -d nextcloud-db nextcloud-redis
sleep 10
docker compose up -d nextcloud || docker-compose up -d nextcloud

docker compose up -d || docker-compose up -d

# Optionally verify running services
bash mac-setup-sync.sh
```

8) Verification:
```
curl -I http://localhost
curl -I https://localhost -k
nslookup mbs-home.ddns.net
ping mbs-home.ddns.net
bash health-check.sh
```

### Router and Cloudflare
- Forward external ports 80 and 443 to the Mac host
- In Cloudflare DNS, set records to DNS only (gray cloud)
- Ensure `mbs-home.ddns.net` resolves to your public IP

### Troubleshooting
- If 404 from Traefik:
  - Check labels and rules in `docker-compose.yml`
  - Confirm `proxy` network exists and Traefik is attached
  - Verify file-sharing includes `/Volumes/WorkDrive` paths
  - Inspect Traefik dashboard for routers/services
- Reset Docker Desktop (last resort):
```
killall Docker
rm -rf ~/Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw
open -a Docker
```

## Post-Deployment Verification

After running `./mac-setup.sh`, verify everything works:

### Local Tests
```
curl -I http://localhost:80
curl -I http://localhost:443
docker exec traefik wget -qO- http://nextcloud:80 | head -n 5
docker exec traefik wget -qO- http://jellyfin:8096 | head -n 5
nslookup mbs-home.ddns.net
```

### Critical Services Check
```
curl -I https://vault.mbs-home.ddns.net
curl -I https://mbs-home.ddns.net
curl -I http://localhost:8123
curl -I https://jellyfin.mbs-home.ddns.net
```

## Important Reminders
- Ensure `/Volumes/WorkDrive` is in Docker Desktop File Sharing and restart Docker if needed
- Router forwards: 80, 443, and 51820/udp to Mac IP
- Cloudflare DNS is set to DNS only (gray cloud), and `mbs-home.ddns.net` points to your public IP

## To Deploy
```
cd ~/mac
git pull
cat docker-compose.yml | grep volumes

cp .env.example .env
nano .env

chmod +x mac-setup.sh rollback.sh
./mac-setup.sh

docker compose logs -f traefik || docker-compose logs -f traefik
```

