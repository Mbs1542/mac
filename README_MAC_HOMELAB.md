# 🏠 Mac Homelab External Drive Setup

## 🚀 Quick Fix for mbs-home.ddns.net 404 Error

This repository contains a complete solution for setting up a Mac homelab with external drive storage, specifically designed to resolve the 404 error issue with `mbs-home.ddns.net`.

## 📁 Files Overview

| File | Purpose |
|------|---------|
| `mac-homelab-setup.sh` | Initial setup script - run this first |
| `deploy-mac-homelab.sh` | Deploy all services |
| `test-mac-setup.sh` | Test setup without starting services |
| `health-check-mac.sh` | Comprehensive health check |
| `docker-compose-mac.yml` | Mac-optimized Docker Compose |
| `.env.mac` | Environment variables template |
| `traefik/config/traefik-mac.yml` | Traefik configuration for Mac |
| `traefik/config/dynamic-mac.yml` | Dynamic Traefik configuration |
| `MAC_HOMELAB_SETUP.md` | Detailed setup guide |

## 🎯 Root Cause Analysis

The 404 error with `mbs-home.ddns.net` is caused by:

1. **Docker Desktop File Sharing**: Not configured for external drive
2. **File Permissions**: Incorrect permissions on critical files
3. **Network Configuration**: Docker networks not properly set up
4. **Traefik Configuration**: Missing or incorrect SSL/TLS setup
5. **Router Port Forwarding**: Ports 80/443 not forwarded to Mac

## ⚡ Quick Start (5 Minutes)

```bash
# 1. Run setup script
./mac-homelab-setup.sh

# 2. Configure environment
cp .env.mac .env
nano .env  # Edit with your values

# 3. Deploy services
./deploy-mac-homelab.sh

# 4. Configure router (ports 80,443 → Mac IP)
# 5. Configure Cloudflare DNS (DNS only, not proxied)
```

## 🔧 Key Features

- ✅ **External Drive Storage**: All data stored on `/Volumes/WorkDrive/MacStorage/docker/`
- ✅ **Mac-Optimized Paths**: Correct paths for macOS with Docker Desktop
- ✅ **Cloudflare DNS Challenge**: Automatic SSL certificate management
- ✅ **Proper Permissions**: Mac-compatible file ownership and permissions
- ✅ **Health Monitoring**: Comprehensive health check and monitoring
- ✅ **Mobile Compatible**: Jellyfin and other services work on mobile
- ✅ **Security**: Authelia authentication and secure headers

## 🌐 Service URLs

Once configured:

- **Main Dashboard**: https://mbs-home.ddns.net
- **Nextcloud**: https://nextcloud.mbs-home.ddns.net
- **Jellyfin**: https://jellyfin.mbs-home.ddns.net
- **Vaultwarden**: https://vault.mbs-home.ddns.net
- **Portainer**: https://portainer.mbs-home.ddns.net
- **Traefik Dashboard**: https://traefik.mbs-home.ddns.net

## 🛠️ Troubleshooting

### Common Issues

1. **404 Error Still Occurs**
   ```bash
   # Check Docker file sharing
   docker run --rm -v /Volumes/WorkDrive/MacStorage/docker:/data alpine ls -la /data
   
   # Check router port forwarding
   ipconfig getifaddr en0  # Get Mac IP
   
   # Check Cloudflare DNS (must be DNS only, not proxied)
   ```

2. **Services Not Starting**
   ```bash
   # Run health check
   ./health-check-mac.sh
   
   # Check logs
   docker logs traefik
   docker logs nextcloud
   ```

3. **Permission Issues**
   ```bash
   # Fix ownership
   sudo chown -R $(whoami):staff /Volumes/WorkDrive/MacStorage/docker/
   
   # Fix acme.json permissions
   chmod 600 /Volumes/WorkDrive/MacStorage/docker/traefik/certificates/acme.json
   ```

## 📊 System Requirements

- **macOS**: Any recent version with Docker Desktop
- **External Drive**: Mounted at `/Volumes/WorkDrive`
- **RAM**: 8GB+ recommended
- **Storage**: 100GB+ on external drive
- **Network**: Router with port forwarding capability
- **DNS**: Cloudflare account with API token

## 🔒 Security Features

- **SSL/TLS**: Automatic certificate management with Let's Encrypt
- **Authentication**: Authelia for secure access
- **Headers**: Security headers for all services
- **Network Isolation**: Internal networks for databases
- **Rate Limiting**: Protection against abuse

## 📈 Monitoring

```bash
# Health check
./health-check-mac.sh

# Service status
docker ps

# Resource usage
docker stats

# Logs
docker-compose -f docker-compose-mac.yml logs -f
```

## 🚨 Important Notes

1. **Docker Desktop File Sharing**: Must include `/Volumes/WorkDrive`
2. **Cloudflare DNS**: Use "DNS only" (gray cloud), NOT proxied (orange cloud)
3. **Router Configuration**: Forward ports 80 and 443 to your Mac's IP
4. **File Permissions**: acme.json must have 600 permissions
5. **External Drive**: Must be mounted before starting services

## 🎉 Expected Results

After successful setup:

- ✅ `mbs-home.ddns.net` returns Nextcloud/Homepage (not 404)
- ✅ All services accessible with HTTPS
- ✅ SSL certificates automatically managed
- ✅ External drive storage working
- ✅ Mobile apps can connect to services
- ✅ Comprehensive monitoring and health checks

## 📞 Support

If you encounter issues:

1. Run `./test-mac-setup.sh` to verify prerequisites
2. Run `./health-check-mac.sh` for comprehensive diagnostics
3. Check the detailed guide: `MAC_HOMELAB_SETUP.md`
4. Verify Docker Desktop file sharing settings
5. Confirm router port forwarding configuration

---

**This setup is specifically designed for macOS with Docker Desktop and external drive storage. The configuration addresses all common issues that cause 404 errors in Mac homelab environments.**