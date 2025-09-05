# 🔍 Comprehensive Docker Homelab Audit Report

**Date:** $(date +%Y-%m-%d)  
**Environment:** Self-hosted Docker Stack  
**Primary Domain:** mbs-home.ddns.net  
**Infrastructure:** Docker Swarm Mode

---

## 📋 Executive Summary

This audit report provides a comprehensive analysis of your self-hosted Docker environment. The system review identified several critical areas requiring immediate attention, particularly around authentication integration, service configuration consistency, and monitoring setup.

### Key Findings:
- ✅ **Traefik** is properly configured as the main reverse proxy
- ⚠️ **Authelia SSO** is configured but NOT integrated with any services in homelab-compose.yml
- ⚠️ **Multiple compose files** with inconsistent configurations (simple-compose.yml has Authelia, homelab-compose.yml doesn't)
- ✅ **System resources** are adequate (15GB RAM, 110GB available disk space)
- ⚠️ **Monitoring stack** (Prometheus/Grafana) lacks proper service discovery
- ⚠️ **Security concerns** with hardcoded passwords and exposed credentials

---

## 🏗️ Current System Architecture

### Active Services Identified:

#### 🌐 **Network & Security Layer**
- **Traefik v3.0** - Reverse proxy and SSL termination
- **AdGuard Home** - DNS filtering and ad blocking
- **WireGuard** - VPN server with web UI
- **Authelia** - SSO authentication (configured but not fully integrated)

#### 📦 **Container Management**
- **Portainer CE** - Docker management UI
- **Homepage** - Service dashboard
- **Watchtower** - Automated container updates
- **Dozzle** - Real-time log viewer

#### 🎬 **Media Stack**
- **Jellyfin** - Media server
- **Sonarr** - TV show management
- **Radarr** - Movie management
- **Lidarr** - Music management
- **Bazarr** - Subtitle management
- **Prowlarr** - Indexer management
- **Transmission** - BitTorrent client
- **Slskd** - Soulseek client

#### 🤖 **Additional Services**
- **Open WebUI** - AI chat interface
- **Vaultwarden** - Password manager
- **Home Assistant** - Home automation
- **Mailserver** - Email server

#### 📊 **Monitoring Stack**
- **Prometheus** - Metrics collection
- **Grafana** - Metrics visualization

---

## 🚨 Critical Issues Identified

### 1. **Authelia SSO Not Integrated (CRITICAL)**

**Issue:** While Authelia is configured in `simple-compose.yml`, the main `homelab-compose.yml` does NOT have any services protected by Authelia middleware.

**Impact:** All services are publicly accessible without authentication when using homelab-compose.yml.

**Evidence:**
- No `middlewares=authelia@file` labels found in homelab-compose.yml
- Authelia service itself is missing from homelab-compose.yml
- Dynamic middleware configuration exists but is not referenced

### 2. **Multiple Conflicting Compose Files**

**Issue:** Three different compose files with varying configurations:
- `homelab-compose.yml` - Main stack without Authelia
- `simple-compose.yml` - Has Authelia integration
- `minimal-compose.yml` - Basic setup

**Impact:** Confusion about which configuration is active and security inconsistencies.

### 3. **Hardcoded Credentials**

**Issue:** Multiple hardcoded passwords found:
- WireGuard password: `Mbs212471387!`
- Vaultwarden admin token: `Mbs212471387!`
- Authelia secrets in configuration.yml
- Default passwords in users_database.yml

**Impact:** Security vulnerability if repository is exposed.

### 4. **Incomplete Monitoring Configuration**

**Issue:** Prometheus is not properly configured to scrape all services.

**Current targets:**
- prometheus (self)
- traefik
- docker (incorrect endpoint)
- node-exporter (not deployed)

**Missing targets:** All application services

### 5. **Network Configuration Issues**

**Issue:** Inconsistent network naming and configuration:
- homelab-compose.yml uses: frontend, backend, management
- simple-compose.yml uses: homelab, media, management
- Services have different network memberships across files

---

## ✅ Action Plan

### Phase 1: Immediate Security Fixes (Priority: CRITICAL)

#### 1.1 Integrate Authelia SSO into homelab-compose.yml

Add Authelia service to homelab-compose.yml:

```yaml
  authelia:
    image: authelia/authelia:latest
    hostname: authelia
    networks:
      - frontend
      - management
    volumes:
      - /Volumes/WorkDrive/MacStorage/docker/authelia:/config
    environment:
      - TZ=Asia/Jerusalem
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--spider", "http://localhost:9091/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    deploy:
      restart_policy:
        condition: on-failure
        delay: 10s
        max_attempts: 3
      replicas: 1
      resources:
        limits:
          memory: 256M
          cpus: '0.3'
        reservations:
          memory: 128M
          cpus: '0.1'
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.authelia.rule=Host(`auth.mbs-home.ddns.net`)"
        - "traefik.http.routers.authelia.entrypoints=websecure"
        - "traefik.http.routers.authelia.tls=true"
        - "traefik.http.routers.authelia.tls.certresolver=letsencrypt"
        - "traefik.http.services.authelia.loadbalancer.server.port=9091"
        - "traefik.docker.network=frontend"
```

#### 1.2 Add Authelia Middleware to All Services

For each service in homelab-compose.yml, add the middleware label:

```yaml
- "traefik.http.routers.<service-name>.middlewares=authelia@file"
```

Services requiring protection:
- Traefik Dashboard
- Portainer
- Homepage
- All *arr services (Sonarr, Radarr, Lidarr, Bazarr, Prowlarr)
- Transmission
- Slskd
- Jellyfin (optional - you may want public access)
- Grafana
- Prometheus
- Dozzle

#### 1.3 Update Traefik Dynamic Configuration

Ensure `/workspace/traefik/config/dynamic.yml` includes:

```yaml
http:
  middlewares:
    authelia:
      forwardAuth:
        address: http://authelia:9091/api/verify?rd=https://auth.mbs-home.ddns.net/
        trustForwardHeader: true
        authResponseHeaders:
          - Remote-User
          - Remote-Groups
          - Remote-Name
          - Remote-Email
```

### Phase 2: Environment Security (Priority: HIGH)

#### 2.1 Move Credentials to Environment Variables

Create `.env` file:

```bash
# Authelia
AUTHELIA_JWT_SECRET=<generate-secure-secret>
AUTHELIA_SESSION_SECRET=<generate-secure-secret>
AUTHELIA_STORAGE_ENCRYPTION_KEY=<generate-secure-secret>

# WireGuard
WG_PASSWORD=<new-secure-password>

# Vaultwarden
VAULTWARDEN_ADMIN_TOKEN=<generate-secure-token>

# Database Passwords
POSTGRES_PASSWORD=<generate-secure-password>
MYSQL_ROOT_PASSWORD=<generate-secure-password>
```

Update compose files to use environment variables:

```yaml
environment:
  - PASSWORD=${WG_PASSWORD}
  - ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN}
```

#### 2.2 Update User Passwords

Generate new password hashes for Authelia users:

```bash
docker run authelia/authelia:latest authelia crypto hash generate argon2 --password 'YourNewSecurePassword'
```

Update `/workspace/authelia/users_database.yml` with new hashes.

### Phase 3: Monitoring Enhancement (Priority: MEDIUM)

#### 3.1 Deploy Node Exporter

Add to homelab-compose.yml:

```yaml
  node-exporter:
    image: prom/node-exporter:latest
    hostname: node-exporter
    networks:
      - management
    command:
      - '--path.rootfs=/host'
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/host:ro,rslave
    deploy:
      mode: global
      resources:
        limits:
          memory: 128M
          cpus: '0.1'
```

#### 3.2 Update Prometheus Configuration

Update `/workspace/prometheus/config/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']

  - job_name: 'docker'
    static_configs:
      - targets: ['172.17.0.1:9323']

  # Application metrics
  - job_name: 'jellyfin'
    static_configs:
      - targets: ['jellyfin:8096']
    metrics_path: '/metrics'

  - job_name: 'sonarr'
    static_configs:
      - targets: ['sonarr:8989']
    metrics_path: '/metrics'

  - job_name: 'radarr'
    static_configs:
      - targets: ['radarr:7878']
    metrics_path: '/metrics'
```

#### 3.3 Create Grafana Dashboards

Import these dashboard IDs in Grafana:
- **Docker Monitoring**: 1229
- **Node Exporter Full**: 1860
- **Traefik 2**: 11462

### Phase 4: Best Practices Implementation (Priority: MEDIUM)

#### 4.1 Consolidate Compose Files

Choose one primary compose file and archive others:

```bash
# Backup current files
mkdir -p /workspace/compose-archive
cp simple-compose.yml compose-archive/simple-compose.yml.bak
cp minimal-compose.yml compose-archive/minimal-compose.yml.bak

# Use homelab-compose.yml as primary after adding Authelia
```

#### 4.2 Implement Proper Backup Strategy

Create automated backup script:

```bash
#!/bin/bash
# /workspace/scripts/backup-docker-volumes.sh

BACKUP_DIR="/Volumes/WorkDrive/MacStorage/Backups/docker-volumes"
DATE=$(date +%Y%m%d-%H%M%S)

# Critical volumes to backup
VOLUMES=(
  "authelia"
  "portainer"
  "vaultwarden"
  "grafana/data"
  "prometheus/data"
  "sonarr/config"
  "radarr/config"
  "jellyfin/config"
)

for volume in "${VOLUMES[@]}"; do
  echo "Backing up $volume..."
  tar -czf "$BACKUP_DIR/${volume//\//-}-$DATE.tar.gz" \
    -C "/Volumes/WorkDrive/MacStorage/docker" "$volume"
done

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
```

Add to cron:

```bash
0 2 * * * /workspace/scripts/backup-docker-volumes.sh
```

#### 4.3 Configure Watchtower Properly

Update Watchtower configuration:

```yaml
environment:
  - WATCHTOWER_CLEANUP=true
  - WATCHTOWER_POLL_INTERVAL=86400
  - WATCHTOWER_LABEL_ENABLE=true
  - WATCHTOWER_INCLUDE_STOPPED=false
  - WATCHTOWER_INCLUDE_RESTARTING=false
  - WATCHTOWER_NO_PULL=false
  - WATCHTOWER_MONITOR_ONLY=false
  - WATCHTOWER_NOTIFICATIONS=email
  - WATCHTOWER_NOTIFICATION_EMAIL_FROM=watchtower@mbs-home.ddns.net
  - WATCHTOWER_NOTIFICATION_EMAIL_TO=admin@mbs-home.ddns.net
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER=mailserver
  - WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=25
```

Add label to services you want auto-updated:

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=true"
```

### Phase 5: User Management Guide

#### 5.1 Adding a New User

1. **Generate password hash:**
```bash
docker exec -it authelia authelia crypto hash generate argon2 --password 'UserPassword'
```

2. **Edit users_database.yml:**
```yaml
users:
  newuser:
    displayname: "New User Name"
    password: "$argon2id$v=19$m=65536,t=3,p=4$..."  # Generated hash
    email: newuser@mbs-home.ddns.net
    groups:
      - users  # or admins for full access
```

3. **Define access rules in configuration.yml:**
```yaml
access_control:
  rules:
    # Allow specific services for users group
    - domain: "jellyfin.mbs-home.ddns.net"
      policy: one_factor
      subject:
        - "group:users"
    
    # Admin-only services
    - domain: "*.mbs-home.ddns.net"
      policy: two_factor
      subject:
        - "group:admins"
```

4. **Restart Authelia:**
```bash
docker service update --force homelab_authelia
```

#### 5.2 Managing Permissions

Create groups in `configuration.yml`:

```yaml
# Example groups:
# - admins: Full access to all services
# - users: Access to media services only
# - family: Access to Jellyfin and Vaultwarden
# - developers: Access to development tools

access_control:
  rules:
    # Media services for all authenticated users
    - domain: 
        - "jellyfin.mbs-home.ddns.net"
        - "request.mbs-home.ddns.net"
      policy: one_factor
      subject:
        - "group:users"
        - "group:family"
    
    # Admin services
    - domain:
        - "portainer.mbs-home.ddns.net"
        - "traefik.mbs-home.ddns.net"
        - "prometheus.mbs-home.ddns.net"
      policy: two_factor
      subject:
        - "group:admins"
```

---

## 📊 System Health Summary

### Resource Usage
- **CPU:** 4 Intel Xeon cores available
- **Memory:** 15GB total, ~1.1GB used (7% utilization) ✅
- **Disk:** 126GB total, 110GB free (9% used) ✅
- **Swap:** Not configured (consider adding for stability)

### Service Health Indicators
Monitor these key metrics in Grafana:

1. **Container Health:**
   - Container restart count
   - Container CPU usage
   - Container memory usage
   - Container network I/O

2. **Traefik Metrics:**
   - Request rate per service
   - Error rate (4xx, 5xx)
   - Request duration
   - Active connections

3. **System Metrics:**
   - CPU usage and load average
   - Memory usage and available
   - Disk I/O and usage
   - Network throughput

---

## 🛡️ Security Checklist

- [ ] Integrate Authelia with all services in homelab-compose.yml
- [ ] Move all hardcoded credentials to environment variables
- [ ] Update all default passwords
- [ ] Enable 2FA for admin accounts in Authelia
- [ ] Configure fail2ban for Authelia
- [ ] Set up SSL certificates for local domains
- [ ] Implement network segmentation (frontend/backend/management)
- [ ] Configure firewall rules for exposed ports
- [ ] Enable Traefik access logs with anonymization
- [ ] Set up automated backups with encryption

---

## 🚀 Next Steps Priority Order

1. **Immediate (Within 24 hours):**
   - Add Authelia to homelab-compose.yml
   - Add middleware labels to all services
   - Change all default passwords

2. **Short-term (Within 1 week):**
   - Implement environment variables for secrets
   - Configure monitoring stack properly
   - Set up automated backups

3. **Long-term (Within 1 month):**
   - Implement network policies
   - Set up centralized logging
   - Configure alerting rules
   - Document disaster recovery procedures

---

## 📝 Final Recommendations

1. **Use a single compose file** - Maintain homelab-compose.yml as the primary configuration
2. **Implement GitOps** - Store configurations in Git with secrets excluded
3. **Regular updates** - Schedule monthly maintenance windows for updates
4. **Monitor actively** - Set up alerts for service failures and resource constraints
5. **Document everything** - Maintain runbooks for common operations

---

## 🎯 Conclusion

Your Docker homelab has a solid foundation with good service selection and adequate resources. The primary concern is the lack of authentication middleware in the main compose file, leaving services exposed. By implementing the recommendations in this report, particularly the Authelia integration, you'll have a secure, well-monitored, and maintainable homelab environment.

**Estimated time to implement all recommendations:** 8-12 hours

**Risk level without fixes:** HIGH ⚠️  
**Risk level after implementing Phase 1:** LOW ✅

---

*Generated on: $(date)*  
*Report Version: 1.0*