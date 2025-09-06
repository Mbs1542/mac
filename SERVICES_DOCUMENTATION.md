# 📚 Homelab Services Documentation

## 🏠 Complete Service Directory

### 🔧 Core Infrastructure

#### Traefik
- **URL**: https://traefik.mbs-home.ddns.net
- **Purpose**: Reverse proxy and SSL termination
- **Container**: traefik
- **Critical**: Yes
- **Features**:
  - Automatic SSL certificates via Let's Encrypt
  - Dynamic service discovery
  - Load balancing
  - Middleware support

#### Portainer
- **URL**: https://portainer.mbs-home.ddns.net
- **Purpose**: Docker container management
- **Container**: portainer
- **Critical**: Yes
- **Features**:
  - Visual container management
  - Stack deployment
  - Resource monitoring
  - Multi-endpoint support

#### AdGuard Home
- **URL**: https://dns.mbs-home.ddns.net
- **Purpose**: Network-wide ad blocking and DNS management
- **Container**: adguard-home
- **Critical**: Yes
- **Features**:
  - DNS filtering
  - Parental controls
  - DHCP server
  - Query logging

### 🔐 Security & Authentication

#### WireGuard
- **URL**: https://vpn.mbs-home.ddns.net
- **Purpose**: VPN server for secure remote access
- **Container**: wireguard
- **Critical**: Yes
- **Configuration**:
  ```
  Network: 10.8.0.0/24
  DNS: 192.168.1.191
  Port: 51820/udp
  ```

#### Authelia
- **URL**: https://auth.mbs-home.ddns.net
- **Purpose**: Single Sign-On and 2FA authentication
- **Container**: authelia
- **Critical**: Yes
- **Features**:
  - TOTP/WebAuthn support
  - Session management
  - Access control policies
  - Integration with Traefik

#### Vaultwarden
- **URL**: https://vault.mbs-home.ddns.net
- **Purpose**: Password manager (Bitwarden compatible)
- **Container**: vaultwarden
- **Features**:
  - End-to-end encryption
  - Mobile app support
  - Secure sharing
  - TOTP generator

### 💻 Remote Access & Development

#### Code-Server
- **URL**: https://code.mbs-home.ddns.net
- **Purpose**: VS Code in the browser
- **Container**: code-server
- **Default Password**: CodeServer2024!
- **Features**:
  - Full VS Code experience
  - Extension support
  - Terminal access
  - Git integration

#### NoMachine
- **URL**: https://remote.mbs-home.ddns.net
- **Purpose**: High-performance remote desktop
- **Container**: nomachine
- **Default Credentials**: admin / NoMachine2024!
- **Ports**: 4000, 4080, 4443
- **Features**:
  - Low-latency desktop access
  - File transfer
  - Audio streaming
  - Multi-platform support

#### File Browser
- **URL**: https://files.mbs-home.ddns.net
- **Purpose**: Web-based file management
- **Container**: filebrowser
- **Default Credentials**: admin / admin
- **Features**:
  - File upload/download
  - In-browser editing
  - Share links
  - User management

#### WebSSH
- **URL**: https://ssh.mbs-home.ddns.net
- **Purpose**: Browser-based SSH terminal
- **Container**: webssh
- **Features**:
  - SSH client in browser
  - Session management
  - Key authentication
  - Multiple connections

### 💰 Financial Management

#### Firefly III
- **URL**: https://money.mbs-home.ddns.net
- **Purpose**: Personal finance and expense tracking
- **Container**: firefly-iii
- **Database**: firefly-db (PostgreSQL)
- **Features**:
  - Shared expense tracking
  - Budget management
  - Bill reminders
  - Financial reports
  - Rule-based automation
  - Mobile app support

**Quick Start Guide**:
1. Create accounts for both partners
2. Set up expense categories:
   - Housing (Rent, Utilities)
   - Food (Groceries, Restaurants)
   - Transportation
   - Entertainment
   - Personal
3. Add shared asset accounts (joint bank accounts)
4. Configure recurring transactions
5. Set up rules for auto-categorization

### 🎬 Media Services

#### Jellyfin
- **URL**: https://media.mbs-home.ddns.net
- **Purpose**: Media streaming server
- **Container**: jellyfin
- **Features**:
  - Movie/TV streaming
  - Music library
  - Mobile apps
  - Transcoding
  - User management

#### Sonarr
- **URL**: https://sonarr.mbs-home.ddns.net
- **Purpose**: TV series management
- **Container**: sonarr
- **API Integration**: Prowlarr, Transmission

#### Radarr
- **URL**: https://radarr.mbs-home.ddns.net
- **Purpose**: Movie management
- **Container**: radarr
- **API Integration**: Prowlarr, Transmission

#### Lidarr
- **URL**: https://lidarr.mbs-home.ddns.net
- **Purpose**: Music management
- **Container**: lidarr
- **API Integration**: Prowlarr, Transmission

#### Bazarr
- **URL**: https://bazarr.mbs-home.ddns.net
- **Purpose**: Subtitle management
- **Container**: bazarr
- **Integration**: Sonarr, Radarr

#### Prowlarr
- **URL**: https://prowlarr.mbs-home.ddns.net
- **Purpose**: Indexer management
- **Container**: prowlarr
- **Features**: Centralized indexer configuration

### 📥 Download Clients

#### Transmission
- **URL**: https://transmission.mbs-home.ddns.net
- **Purpose**: BitTorrent client
- **Container**: transmission
- **Ports**: 51413/tcp, 51413/udp

#### Slskd
- **URL**: https://slskd.mbs-home.ddns.net
- **Purpose**: Soulseek client
- **Container**: slskd
- **Port**: 50300/tcp

### ☁️ Cloud & Productivity

#### Nextcloud
- **URL**: https://nextcloud.mbs-home.ddns.net
- **Purpose**: Personal cloud storage
- **Container**: nextcloud
- **Database**: nextcloud-db (PostgreSQL)
- **Cache**: nextcloud-redis
- **Features**:
  - File sync
  - Calendar/Contacts
  - Document editing
  - Photo backup

### 🤖 AI & Automation

#### Open WebUI
- **URL**: https://ai.mbs-home.ddns.net
- **Purpose**: AI chat interface
- **Container**: open-webui
- **Features**:
  - Multiple AI models
  - Chat history
  - Custom prompts

#### Home Assistant
- **URL**: https://home.mbs-home.ddns.net
- **Purpose**: Home automation platform
- **Container**: homeassistant
- **Features**:
  - Device control
  - Automations
  - Energy monitoring
  - Mobile app

### 📊 Monitoring & Analytics

#### Grafana
- **URL**: https://monitor.mbs-home.ddns.net
- **Purpose**: Metrics visualization
- **Container**: grafana
- **Default Credentials**: admin / grafana-admin-secure-2024

#### Prometheus
- **URL**: https://prometheus.mbs-home.ddns.net
- **Purpose**: Metrics collection
- **Container**: prometheus
- **Retention**: 30 days

#### Dozzle
- **URL**: https://logs.mbs-home.ddns.net
- **Purpose**: Container log viewer
- **Container**: dozzle

### 🔧 System Monitoring

#### Node Exporter
- **Purpose**: System metrics exporter
- **Container**: node-exporter
- **Metrics**: CPU, Memory, Disk, Network

#### cAdvisor
- **Purpose**: Container metrics
- **Container**: cadvisor
- **Metrics**: Container resource usage

#### Blackbox Exporter
- **Purpose**: Endpoint monitoring
- **Container**: blackbox-exporter
- **Features**: HTTP/HTTPS probing, SSL certificate monitoring

### 🔄 Automation

#### Watchtower
- **Purpose**: Automatic container updates
- **Container**: watchtower
- **Schedule**: Daily at 3 AM

## 🚀 Quick Access Guide

### Essential URLs
```
Main Dashboard:     https://mbs-home.ddns.net
Media Server:       https://media.mbs-home.ddns.net
Finance Tracker:    https://money.mbs-home.ddns.net
Password Manager:   https://vault.mbs-home.ddns.net
Cloud Storage:      https://nextcloud.mbs-home.ddns.net
Remote Desktop:     https://remote.mbs-home.ddns.net
Code Editor:        https://code.mbs-home.ddns.net
```

### Mobile Apps
- **Jellyfin**: iOS/Android app for media streaming
- **Nextcloud**: Auto-upload photos and file sync
- **Home Assistant**: Control smart home devices
- **Vaultwarden**: Bitwarden compatible password manager
- **WireGuard**: VPN connection
- **Firefly III**: Expense tracking on-the-go

## 🛠️ Maintenance Procedures

### Daily Tasks
- Automated health checks (3 AM)
- Container updates via Watchtower
- Backup critical data

### Weekly Tasks
- Review Firefly III reports
- Check system resource usage
- Update media library

### Monthly Tasks
- Security audit
- SSL certificate renewal check
- Clean old logs and backups

## 🆘 Troubleshooting

### Service Won't Start
```bash
# Check container logs
docker logs [container-name]

# Restart service
docker-compose restart [service-name]

# Check resource usage
docker stats
```

### Can't Access Service
1. Verify WireGuard VPN connection
2. Check Traefik routing: https://traefik.mbs-home.ddns.net
3. Verify Authelia authentication
4. Check service health in Portainer

### Performance Issues
1. Check Grafana dashboards for resource usage
2. Review container limits in docker-compose.yml
3. Check disk space: `df -h`
4. Monitor network traffic in AdGuard

## 📞 Support Contacts

- **System Admin**: admin@mbs-home.ddns.net
- **Backup Admin**: backup@mbs-home.ddns.net
- **Emergency**: Use Portainer for immediate container management

## 🔐 Security Best Practices

1. **Always use VPN**: Never expose services directly to internet
2. **Strong passwords**: Use Vaultwarden to generate and store
3. **2FA enabled**: Configure in Authelia for all critical services
4. **Regular updates**: Watchtower handles automatically
5. **Backup encryption**: All backups are encrypted at rest
6. **Access logs**: Review regularly in Dozzle

## 📈 Performance Optimization

### Resource Allocation
- **High Priority**: Jellyfin (4GB RAM), Nextcloud (1GB RAM)
- **Medium Priority**: Firefly III, Code-Server (1GB RAM each)
- **Low Priority**: Monitoring tools (128-256MB RAM)

### Network Optimization
- Internal networks for database connections
- Bridge networks for service communication
- Separate networks for different service categories

## 🎯 Success Metrics

- **Uptime Target**: 99.9% for critical services
- **Response Time**: <2 seconds for all web services
- **Backup Success**: 100% daily backup completion
- **Security Score**: No critical vulnerabilities
- **Resource Usage**: <80% CPU, <90% Memory

---

*Last Updated: 2024*
*Version: 2.0 - Enhanced with Remote Access & Financial Tracking*