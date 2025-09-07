# Mac Homelab External Drive Setup Guide

## 🚀 Quick Start

This guide will help you set up a complete homelab on macOS with external drive storage, resolving the 404 error issue with `mbs-home.ddns.net`.

### Prerequisites

- macOS with Docker Desktop installed
- External drive mounted at `/Volumes/WorkDrive`
- Cloudflare account with API token
- Router with port forwarding capabilities

## 📋 Step-by-Step Setup

### 1. Initial Setup

```bash
# Run the setup script
./mac-homelab-setup.sh
```

This script will:
- ✅ Create directory structure on external drive
- ✅ Set proper file permissions
- ✅ Create Docker networks
- ✅ Configure Mac firewall
- ✅ Test Docker access to external drive

### 2. Configure Environment Variables

```bash
# Copy the template
cp .env.mac .env

# Edit with your values
nano .env
```

**Required values:**
- `CF_API_EMAIL`: Your email address
- `CF_DNS_API_TOKEN`: Cloudflare API token
- `NEXTCLOUD_DB_PASSWORD`: Secure database password
- `AUTHELIA_SESSION_SECRET`: Generate with `openssl rand -base64 32`
- `AUTHELIA_STORAGE_ENCRYPTION_KEY`: Generate with `openssl rand -base64 32`
- `AUTHELIA_JWT_SECRET`: Generate with `openssl rand -base64 32`
- `VAULTWARDEN_ADMIN_TOKEN`: Generate with `openssl rand -base64 32`

### 3. Deploy Services

```bash
# Deploy the homelab
./deploy-mac-homelab.sh
```

### 4. Configure Router Port Forwarding

Forward these ports to your Mac's IP address:
- **Port 80** → Mac IP (HTTP)
- **Port 443** → Mac IP (HTTPS)

### 5. Configure Cloudflare DNS

1. Go to Cloudflare Dashboard
2. Add DNS record: `A` record `mbs-home` → Your public IP
3. **IMPORTANT**: Set to "DNS only" (gray cloud), NOT proxied (orange cloud)
4. Add wildcard: `CNAME` record `*.mbs-home` → `mbs-home.ddns.net`

## 🔧 Troubleshooting

### Common Issues

#### 1. External Drive Not Accessible

```bash
# Check if drive is mounted
mount | grep WorkDrive

# Check Docker file sharing
# Open Docker Desktop → Settings → Resources → File Sharing
# Add: /Volumes/WorkDrive
# Add: /Volumes/WorkDrive/MacStorage
```

#### 2. Services Return 404

**Check these in order:**

1. **Docker Desktop File Sharing**
   ```bash
   # Test Docker access
   docker run --rm -v /Volumes/WorkDrive/MacStorage/docker:/data alpine ls -la /data
   ```

2. **Router Port Forwarding**
   ```bash
   # Get Mac's IP
   ipconfig getifaddr en0  # WiFi
   ipconfig getifaddr en1  # Ethernet
   ```

3. **Cloudflare DNS Settings**
   - Ensure DNS records are "DNS only" (gray cloud)
   - Not proxied (orange cloud)

4. **Service Health**
   ```bash
   # Run health check
   ./health-check-mac.sh
   
   # Check specific service
   docker logs traefik
   docker logs nextcloud
   ```

#### 3. SSL Certificate Issues

```bash
# Check acme.json permissions
ls -la /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
# Should be: -rw------- (600)

# Fix permissions if needed
chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
```

#### 4. Permission Issues

```bash
# Fix ownership
sudo chown -R $(whoami):staff /Volumes/WorkDrive/MacStorage/docker/

# Fix permissions
chmod 755 /Volumes/WorkDrive/MacStorage/docker/traefik/config
chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
```

## 📊 Service URLs

Once configured, access your services at:

| Service | URL | Description |
|---------|-----|-------------|
| **Homepage** | https://mbs-home.ddns.net | Main dashboard |
| **Nextcloud** | https://nextcloud.mbs-home.ddns.net | File storage |
| **Jellyfin** | https://jellyfin.mbs-home.ddns.net | Media server |
| **Vaultwarden** | https://vault.mbs-home.ddns.net | Password manager |
| **Authelia** | https://auth.mbs-home.ddns.net | Authentication |
| **Traefik** | https://traefik.mbs-home.ddns.net | Reverse proxy |
| **Portainer** | https://portainer.mbs-home.ddns.net | Container management |
| **AdGuard** | https://dns.mbs-home.ddns.net | DNS server |

## 🔍 Monitoring & Maintenance

### Health Check

```bash
# Run comprehensive health check
./health-check-mac.sh
```

### Service Management

```bash
# Start all services
docker-compose -f docker-compose-mac.yml up -d

# Stop all services
docker-compose -f docker-compose-mac.yml down

# View logs
docker-compose -f docker-compose-mac.yml logs -f

# Restart specific service
docker-compose -f docker-compose-mac.yml restart nextcloud
```

### Backup

```bash
# Backup configuration
tar -czf homelab-backup-$(date +%Y%m%d).tar.gz /Volumes/WorkDrive/MacStorage/docker/

# Backup data only
tar -czf homelab-data-$(date +%Y%m%d).tar.gz /Volumes/WorkDrive/MacStorage/docker/nextcloud/data
```

## 🛠️ Advanced Configuration

### Custom Domains

To use custom domains, update the Traefik labels in `docker-compose-mac.yml`:

```yaml
labels:
  - "traefik.http.routers.nextcloud.rule=Host(`your-domain.com`)"
```

### Additional Services

To add more services:

1. Add service definition to `docker-compose-mac.yml`
2. Use external drive paths: `/Volumes/WorkDrive/MacStorage/docker/service-name`
3. Add Traefik labels for routing
4. Update health check script

### Security Hardening

1. **Change default passwords** in `.env`
2. **Enable Authelia** for additional services
3. **Use strong secrets** (32+ characters)
4. **Regular updates**: `docker-compose -f docker-compose-mac.yml pull && docker-compose -f docker-compose-mac.yml up -d`

## 📞 Support

If you encounter issues:

1. Run `./health-check-mac.sh`
2. Check service logs: `docker logs <service-name>`
3. Verify external drive mount: `mount | grep WorkDrive`
4. Test Docker access: `docker run --rm -v /Volumes/WorkDrive/MacStorage/docker:/data alpine ls -la /data`

## 🎯 Expected Results

After successful setup:

- ✅ `mbs-home.ddns.net` → Nextcloud/Homepage
- ✅ `jellyfin.mbs-home.ddns.net` → Jellyfin
- ✅ `vault.mbs-home.ddns.net` → Vaultwarden
- ✅ All services accessible with HTTPS
- ✅ SSL certificates automatically managed
- ✅ External drive storage working
- ✅ Mobile app compatibility

---

**Note**: This setup is optimized for macOS with Docker Desktop. The external drive configuration ensures your data persists and is accessible even if you move the drive between Macs.