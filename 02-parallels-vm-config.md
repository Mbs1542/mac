# Parallels VM Configuration Guide

## CRITICAL: VM Location on External Drive

This guide ensures your Parallels VM is created on the external drive for optimal homelab performance with AI models.

## Step-by-Step VM Creation

### 1. Open Parallels Desktop
- Launch Parallels Desktop on your Mac
- Click "New" or "+" to create a new VM

### 2. Choose Installation Method
- Select "Install Windows or another OS from a DVD or image file"
- Choose "Download Ubuntu Server 22.04.3 LTS" (recommended)
- Or use your own Ubuntu Server 22.04.3 LTS ISO

### 3. CRITICAL: Configure Before Creation
**⚠️ DO NOT click "Continue" yet!**

Before proceeding, click **"Configure"** button to access advanced settings:

#### Location Settings
- **Location**: Click "Browse" and navigate to your external drive
- **Path**: `/Volumes/ExternalSSD/ParallelsVMs/HomelabServer`
- **Name**: `HomelabServer`

#### Hardware Configuration
- **CPU**: 12-16 cores (for parallel AI inference)
- **RAM**: 58GB (40GB for services + 18GB for LLMs)
- **Storage**: 500GB expanding disk
- **Network**: Bridged Ethernet (for homelab access)

#### Advanced Settings
- **Enable nested virtualization**: Yes (for Docker)
- **Optimization**: "Faster virtual machine"
- **Hardware**: Enable all available features

### 4. Create VM
- Click "Continue" to create the VM
- Wait for Ubuntu Server to download and install
- **Installation time**: 15-30 minutes (external drive will be slower)

## Post-Installation Configuration

### 1. Initial Ubuntu Setup
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl wget git vim htop iotop nethogs

# Set hostname
sudo hostnamectl set-hostname homelab-server
```

### 2. Network Configuration
```bash
# Configure static IP (recommended for homelab)
sudo nano /etc/netplan/00-installer-config.yaml

# Add your network configuration:
# network:
#   version: 2
#   ethernets:
#     ens33:  # or your interface name
#       dhcp4: false
#       addresses: [192.168.1.100/24]  # Your desired IP
#       gateway4: 192.168.1.1
#       nameservers:
#         addresses: [8.8.8.8, 1.1.1.1]

sudo netplan apply
```

### 3. Mount External Drive Data
```bash
# Create mount point
sudo mkdir -p /mnt/homelab

# Find your external drive UUID
sudo blkid

# Add to fstab (replace UUID with actual UUID)
echo "UUID=YOUR_EXTERNAL_UUID /mnt/homelab ext4 defaults,noatime 0 2" | sudo tee -a /etc/fstab

# Mount the drive
sudo mount -a

# Verify mount
df -h /mnt/homelab
```

## Performance Optimization for External Drive

### 1. System Optimizations
```bash
# Optimize for external drive
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio=15" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio=5" | sudo tee -a /etc/sysctl.conf

# Apply changes
sudo sysctl -p
```

### 2. Create RAM Disk for AI Model Caching
```bash
# Create 8GB RAM disk for temporary AI model caching
sudo mkdir -p /mnt/ramdisk
echo "tmpfs /mnt/ramdisk tmpfs defaults,size=8G,noatime 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Verify RAM disk
df -h /mnt/ramdisk
```

### 3. Docker Optimization
```bash
# Create Docker data directory on external drive
sudo mkdir -p /mnt/homelab/docker

# Configure Docker daemon
sudo tee /etc/docker/daemon.json << 'EOF'
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
  "registry-mirrors": ["https://mirror.gcr.io"],
  "default-ulimits": {
    "memlock": {
      "Hard": -1,
      "Name": "memlock",
      "Soft": -1
    }
  }
}
EOF

# Restart Docker
sudo systemctl restart docker
```

## Validation Checklist

- [ ] VM created on external drive
- [ ] Ubuntu Server 22.04.3 LTS installed
- [ ] 58GB RAM allocated
- [ ] 12-16 CPU cores allocated
- [ ] External drive mounted at `/mnt/homelab`
- [ ] Network configured (static IP recommended)
- [ ] Docker installed and configured
- [ ] System optimizations applied
- [ ] RAM disk created for AI model caching

## Troubleshooting

### VM Won't Start
- Check external drive connection
- Verify Parallels has permission to access external drive
- Check available disk space on external drive

### Slow Performance
- Normal for external drive setup
- Ensure USB 3.0 connection
- Check for disk errors: `sudo fsck /dev/sdX`

### Network Issues
- Verify bridged network configuration
- Check router settings for static IP
- Test connectivity: `ping 8.8.8.8`

## Next Steps

After VM configuration is complete:
1. Run the Ubuntu setup script (`03-ubuntu-ai-setup.sh`)
2. Configure AI services
3. Migrate your homelab services
4. Validate all services are running

## Performance Expectations

| Operation | Expected Time | Notes |
|-----------|---------------|-------|
| VM Boot | 2-3 minutes | External drive overhead |
| Ubuntu Install | 15-30 minutes | Slower than internal drive |
| Docker Image Pull | +20-30% slower | External I/O bottleneck |
| AI Model Load | 30-90 seconds | Depends on model size |

Remember: Once models are loaded into RAM, inference speed will be near-native performance!