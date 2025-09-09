# Homelab Migration to External Drive with Local AI Models

## Complete Documentation and Troubleshooting Guide

### Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Installation Guide](#installation-guide)
4. [Configuration](#configuration)
5. [AI Services Setup](#ai-services-setup)
6. [Performance Optimization](#performance-optimization)
7. [Monitoring and Maintenance](#monitoring-and-maintenance)
8. [Troubleshooting](#troubleshooting)
9. [Performance Expectations](#performance-expectations)
10. [Backup and Recovery](#backup-and-recovery)

## Overview

This guide provides a complete solution for migrating a homelab with 31 services to an external drive while adding local AI models (Ollama, LocalAI, Text Generation WebUI) for offline AI inference.

### Key Features
- **31 Services**: Complete homelab stack including Nextcloud, Jellyfin, monitoring, etc.
- **Local AI Models**: Ollama, LocalAI, Text Generation WebUI, Open WebUI
- **External Drive**: Optimized for USB 3.0 external drive (158MB/s)
- **58GB RAM**: Dedicated for AI model inference
- **Performance Monitoring**: Comprehensive monitoring and alerting

### Architecture
```
Mac with Parallels Desktop
├── External Drive (USB 3.0)
│   ├── ParallelsVMs/HomelabServer/
│   └── HomelabData/
│       ├── docker/          # Docker volumes
│       ├── models/          # AI models
│       ├── media/           # Media files
│       ├── configs/         # Configurations
│       └── backups/         # Backups
└── Ubuntu Server 22.04.3 LTS
    ├── 58GB RAM
    ├── 12-16 CPU cores
    └── AI Services
        ├── Ollama
        ├── LocalAI
        ├── Text Generation WebUI
        └── Open WebUI
```

## Prerequisites

### Hardware Requirements
- **Mac**: With Parallels Desktop (Licensed)
- **External Drive**: USB 3.0, minimum 500GB, recommended 1TB+
- **RAM**: 58GB allocated to VM
- **CPU**: 12-16 cores for parallel AI inference
- **Network**: Stable internet connection for initial setup

### Software Requirements
- **Parallels Desktop**: Latest version
- **Ubuntu Server**: 22.04.3 LTS
- **Docker**: Latest version
- **Docker Compose**: Latest version

### External Drive Specifications
- **Speed**: ~158MB/s (USB 3.0)
- **Format**: ext4 (recommended)
- **Space**: 500GB+ available
- **Health**: No bad sectors

## Installation Guide

### Phase 1: External Drive Preparation

1. **Connect External Drive**
   ```bash
   # Check drive is recognized
   diskutil list
   ```

2. **Format Drive** (if needed)
   ```bash
   # Format as exFAT for Mac compatibility
   diskutil eraseDisk exFAT "ExternalSSD" /dev/diskX
   ```

3. **Run Preparation Script**
   ```bash
   chmod +x 01-external-drive-prep.sh
   ./01-external-drive-prep.sh
   ```

### Phase 2: Parallels VM Creation

1. **Create New VM**
   - Open Parallels Desktop
   - New → Install Windows or another OS
   - Choose Ubuntu Server 22.04.3 LTS

2. **Configure VM Location**
   - **CRITICAL**: Click "Configure" before creation
   - Location: Browse → Select external drive
   - Path: `/Volumes/ExternalSSD/ParallelsVMs/HomelabServer`

3. **Hardware Configuration**
   - CPU: 12-16 cores
   - RAM: 58GB
   - Storage: 500GB expanding disk
   - Network: Bridged Ethernet

4. **Install Ubuntu**
   - Follow Ubuntu installation wizard
   - Set static IP (recommended)
   - Enable SSH for remote access

### Phase 3: Ubuntu Setup

1. **Run Ubuntu Setup Script**
   ```bash
   chmod +x 03-ubuntu-ai-setup.sh
   ./03-ubuntu-ai-setup.sh
   ```

2. **Verify Installation**
   ```bash
   # Check Docker
   docker --version
   docker-compose --version
   
   # Check Ollama
   ollama --version
   
   # Check external drive mount
   df -h /mnt/homelab
   ```

### Phase 4: AI Services Configuration

1. **Download AI Models**
   ```bash
   /mnt/homelab/scripts/download-models.sh /mnt/homelab/models/ollama
   ```

2. **Configure Docker Compose**
   ```bash
   # Copy docker-compose file
   cp 04-docker-compose-ai.yml /mnt/homelab/docker/compose/docker-compose.yml
   ```

3. **Start Services**
   ```bash
   cd /mnt/homelab/docker/compose
   docker compose up -d
   ```

### Phase 5: Data Migration

1. **Run Migration Script**
   ```bash
   chmod +x 06-data-migration.sh
   ./06-data-migration.sh
   ```

2. **Verify Migration**
   ```bash
   /mnt/homelab/scripts/validate-migration.sh
   ```

## Configuration

### Docker Configuration

The Docker daemon is configured for external drive optimization:

```json
{
  "data-root": "/mnt/homelab/docker",
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "registry-mirrors": ["https://mirror.gcr.io"]
}
```

### System Optimizations

Applied system-level optimizations for external drive:

```bash
# External drive optimizations
vm.swappiness=10
vm.vfs_cache_pressure=50
vm.dirty_ratio=15
vm.dirty_background_ratio=5
vm.dirty_expire_centisecs=3000
vm.dirty_writeback_centisecs=500

# AI model optimizations
vm.max_map_count=262144
kernel.shmmax=68719476736
kernel.shmall=4294967296
```

### Network Configuration

Recommended network setup:

```yaml
# /etc/netplan/00-installer-config.yaml
network:
  version: 2
  ethernets:
    ens33:  # or your interface name
      dhcp4: false
      addresses: [192.168.1.100/24]  # Your desired IP
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

## AI Services Setup

### Ollama Configuration

```bash
# Environment variables
export OLLAMA_MODELS=/mnt/homelab/models/ollama
export OLLAMA_HOST=0.0.0.0
export OLLAMA_KEEP_ALIVE=24h
export OLLAMA_MAX_LOADED_MODELS=2
```

### Available AI Models

| Model | Size | RAM Required | Use Case |
|-------|------|--------------|----------|
| llama2:7b | 3.8GB | 8GB | General purpose |
| codellama:13b | 7.3GB | 16GB | Code generation |
| mistral:7b | 4.1GB | 8GB | Fast inference |
| mixtral:8x7b | 26GB | 32GB | High quality |
| llava:7b | 4.5GB | 8GB | Vision tasks |

### AI Service Endpoints

- **Ollama API**: `http://localhost:11434`
- **LocalAI**: `http://localhost:8080`
- **Text Generation WebUI**: `http://localhost:7860`
- **Open WebUI**: `http://localhost:3001`

## Performance Optimization

### External Drive Optimizations

1. **Mount Options**
   ```bash
   # Optimized mount options
   defaults,noatime,nodiratime,relatime
   ```

2. **RAM Disk for Caching**
   ```bash
   # 8GB RAM disk for temporary files
   tmpfs /mnt/ramdisk tmpfs defaults,size=8G,noatime 0 0
   ```

3. **Docker Optimization**
   - Data root on external drive
   - Optimized storage driver
   - Reduced log retention

### AI Model Optimization

1. **Model Loading Strategy**
   - Pre-load frequently used models
   - Use model quantization when possible
   - Implement model caching

2. **Memory Management**
   - Reserve 20GB for Ollama
   - Use memory limits for containers
   - Monitor memory usage

3. **Inference Optimization**
   - Use appropriate thread counts
   - Enable GPU acceleration if available
   - Optimize context sizes

## Monitoring and Maintenance

### Monitoring Scripts

1. **AI Services Monitor**
   ```bash
   /mnt/homelab/scripts/monitoring/ai-monitor.sh
   ```

2. **System Performance Monitor**
   ```bash
   /mnt/homelab/scripts/monitoring/system-monitor.sh
   ```

3. **Service Health Monitor**
   ```bash
   /mnt/homelab/scripts/monitoring/service-monitor.sh
   ```

4. **Comprehensive Health Check**
   ```bash
   /mnt/homelab/scripts/monitoring/health-check.sh
   ```

### Automated Monitoring

Cron jobs are set up for automated monitoring:

- **Health Check**: Every 5 minutes
- **AI Monitor**: Every 10 minutes
- **System Monitor**: Every 15 minutes
- **Alerting**: Every 6 hours
- **Performance Test**: Daily

### Maintenance Tasks

1. **Daily Maintenance**
   ```bash
   /mnt/homelab/scripts/maintenance.sh
   ```

2. **Weekly Backup**
   ```bash
   /mnt/homelab/scripts/backup-homelab.sh /mnt/homelab/backups /mnt/homelab
   ```

3. **Monthly Updates**
   ```bash
   sudo apt update && sudo apt upgrade -y
   docker compose pull
   docker compose up -d
   ```

## Troubleshooting

### Common Issues

#### 1. VM Won't Start
**Symptoms**: Parallels VM fails to start
**Causes**: External drive not connected, permissions, disk space
**Solutions**:
```bash
# Check external drive connection
diskutil list

# Check permissions
ls -la /Volumes/ExternalSSD/ParallelsVMs/

# Check disk space
df -h /Volumes/ExternalSSD/
```

#### 2. Slow Performance
**Symptoms**: Slow boot, slow model loading, slow container starts
**Causes**: External drive speed, insufficient RAM, I/O bottlenecks
**Solutions**:
```bash
# Check external drive speed
dd if=/dev/zero of=/mnt/homelab/speedtest bs=1024k count=1024

# Check I/O statistics
iostat -x 1 5

# Check memory usage
free -h
```

#### 3. AI Models Won't Load
**Symptoms**: Ollama fails to load models, out of memory errors
**Causes**: Insufficient RAM, disk space, model corruption
**Solutions**:
```bash
# Check available memory
free -h

# Check disk space
df -h /mnt/homelab/models

# Restart Ollama
sudo systemctl restart ollama

# Check model status
ollama list
```

#### 4. Docker Containers Failing
**Symptoms**: Containers won't start, health check failures
**Causes**: Resource limits, port conflicts, volume issues
**Solutions**:
```bash
# Check container logs
docker logs <container_name>

# Check resource usage
docker stats

# Check port conflicts
netstat -tulpn | grep :<port>

# Restart Docker
sudo systemctl restart docker
```

#### 5. Network Connectivity Issues
**Symptoms**: Services not accessible, API calls failing
**Causes**: Firewall, port conflicts, DNS issues
**Solutions**:
```bash
# Check firewall
sudo ufw status

# Check port accessibility
telnet localhost 11434

# Check DNS
nslookup google.com

# Check network configuration
ip addr show
```

### Performance Issues

#### 1. Slow Model Loading
**Expected**: 7B model loads in 30-40 seconds
**Actual**: Taking longer
**Solutions**:
- Check external drive speed
- Verify RAM allocation
- Check for I/O errors
- Use RAM disk for temporary files

#### 2. High Memory Usage
**Expected**: 58GB RAM for services + AI
**Actual**: Running out of memory
**Solutions**:
- Reduce model count
- Optimize container limits
- Check for memory leaks
- Use model quantization

#### 3. Slow Container Starts
**Expected**: +20-30% slower than internal drive
**Actual**: Much slower
**Solutions**:
- Check external drive health
- Optimize Docker configuration
- Use startup order script
- Check for I/O bottlenecks

### Recovery Procedures

#### 1. Service Recovery
```bash
# Restart all services
cd /mnt/homelab/docker/compose
docker compose down
docker compose up -d

# Restart AI services
sudo systemctl restart ollama
docker compose up -d ollama localai text-generation-webui open-webui
```

#### 2. Data Recovery
```bash
# Check external drive mount
mount | grep homelab

# Remount if needed
sudo mount -a

# Check data integrity
fsck /dev/sdX
```

#### 3. Model Recovery
```bash
# Re-download models
ollama pull llama2:7b
ollama pull mistral:7b

# Check model integrity
ollama list
```

## Performance Expectations

### Boot Times
- **VM Boot**: 2-3 minutes (external drive overhead)
- **Service Startup**: +20-30% slower than internal drive
- **AI Model Loading**: 30-90 seconds depending on model size

### AI Model Performance
- **7B Model Load**: 30-40 seconds
- **13B Model Load**: 60-90 seconds
- **Mixtral 8x7B Load**: 3-4 minutes
- **Inference Speed**: Near-native once loaded in RAM

### I/O Performance
- **Write Speed**: ~158MB/s (USB 3.0)
- **Read Speed**: ~158MB/s (USB 3.0)
- **Random I/O**: Slower than internal drive
- **Sequential I/O**: Near USB 3.0 limits

### Resource Usage
- **RAM**: 58GB total (40GB services + 18GB AI)
- **CPU**: 12-16 cores for parallel processing
- **Disk**: 500GB+ for all services and models
- **Network**: Standard Ethernet speeds

## Backup and Recovery

### Backup Strategy

1. **Daily Backups**
   ```bash
   /mnt/homelab/scripts/backup-homelab.sh /mnt/homelab/backups /mnt/homelab
   ```

2. **Model Backups**
   ```bash
   # Backup AI models
   tar -czf /mnt/homelab/backups/models-$(date +%Y%m%d).tar.gz -C /mnt/homelab models/
   ```

3. **Configuration Backups**
   ```bash
   # Backup configurations
   tar -czf /mnt/homelab/backups/configs-$(date +%Y%m%d).tar.gz -C /mnt/homelab configs/
   ```

### Recovery Procedures

1. **Full System Recovery**
   ```bash
   # Restore from backup
   tar -xzf /mnt/homelab/backups/homelab-backup-YYYYMMDD.tar.gz -C /mnt/homelab/
   ```

2. **Service Recovery**
   ```bash
   # Restart services
   cd /mnt/homelab/docker/compose
   docker compose up -d
   ```

3. **Model Recovery**
   ```bash
   # Restore models
   tar -xzf /mnt/homelab/backups/models-YYYYMMDD.tar.gz -C /mnt/homelab/
   ```

### Disaster Recovery

1. **External Drive Failure**
   - Have backup drive ready
   - Restore from latest backup
   - Recreate VM with same configuration

2. **VM Corruption**
   - Recreate VM from scratch
   - Restore data from backup
   - Reconfigure services

3. **Data Loss**
   - Check backup integrity
   - Restore from latest good backup
   - Verify service functionality

## Conclusion

This comprehensive guide provides everything needed to successfully migrate a homelab to an external drive while adding local AI capabilities. The setup is optimized for external drive performance and includes robust monitoring, maintenance, and recovery procedures.

### Key Success Factors
1. **Proper Hardware**: Adequate RAM and external drive speed
2. **Correct Configuration**: Optimized for external drive performance
3. **Regular Monitoring**: Automated monitoring and alerting
4. **Backup Strategy**: Regular backups and recovery procedures
5. **Performance Expectations**: Realistic expectations for external drive setup

### Support and Maintenance
- Monitor performance regularly
- Keep backups up to date
- Update services and models
- Check logs for issues
- Optimize based on usage patterns

For additional support or questions, refer to the troubleshooting section or check the monitoring logs for specific error messages.