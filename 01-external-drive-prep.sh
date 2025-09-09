#!/bin/bash
# External Drive Preparation Script for Homelab Migration
# Run this on your Mac BEFORE creating the Parallels VM

set -e

# Configuration
EXTERNAL_DRIVE="/Volumes/ExternalSSD"  # Change to your drive name
VM_NAME="HomelabServer"
PROJECT_ROOT="/workspace"

echo "🚀 Starting External Drive Preparation for Homelab Migration"
echo "=============================================================="

# Check if external drive exists
if [ ! -d "$EXTERNAL_DRIVE" ]; then
    echo "❌ External drive not found at $EXTERNAL_DRIVE"
    echo "Please connect your external drive and update the EXTERNAL_DRIVE variable"
    exit 1
fi

echo "✅ External drive found at $EXTERNAL_DRIVE"

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$EXTERNAL_DRIVE/ParallelsVMs/$VM_NAME"
mkdir -p "$EXTERNAL_DRIVE/HomelabData/docker"
mkdir -p "$EXTERNAL_DRIVE/HomelabData/models"
mkdir -p "$EXTERNAL_DRIVE/HomelabData/media"
mkdir -p "$EXTERNAL_DRIVE/HomelabData/backups"
mkdir -p "$EXTERNAL_DRIVE/HomelabData/configs"

echo "✅ Directory structure created"

# Test drive speed
echo "⚡ Testing external drive speed..."
echo "This will create a 1GB test file to measure write speed..."

# Create speed test file
dd if=/dev/zero of="$EXTERNAL_DRIVE/speedtest" bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s'

# Clean up test file
rm -f "$EXTERNAL_DRIVE/speedtest"

echo "✅ Speed test completed"

# Create drive info file
echo "📊 Creating drive information file..."
cat > "$EXTERNAL_DRIVE/drive-info.txt" << EOF
External Drive Information
=========================
Drive Path: $EXTERNAL_DRIVE
VM Name: $VM_NAME
Setup Date: $(date)
Expected Speed: ~158MB/s
Purpose: Homelab with 31 services + Local AI models

Directory Structure:
- ParallelsVMs/$VM_NAME/     # VM files
- HomelabData/docker/        # Docker volumes
- HomelabData/models/        # AI models (Ollama, LocalAI)
- HomelabData/media/         # Media files
- HomelabData/backups/       # Backup storage
- HomelabData/configs/       # Configuration files

Performance Expectations:
- VM Boot: 2-3 minutes
- 7B Model Load: 30-40 seconds
- 13B Model Load: 60-90 seconds
- Mixtral 8x7B Load: 3-4 minutes
- Container Starts: +20-30% slower

Next Steps:
1. Create Parallels VM with custom location
2. Run Ubuntu setup script
3. Configure AI services
4. Migrate data
EOF

echo "✅ Drive information file created"

# Create migration checklist
echo "📋 Creating migration checklist..."
cat > "$EXTERNAL_DRIVE/migration-checklist.md" << 'EOF'
# Homelab Migration Checklist

## Pre-Migration
- [ ] External drive prepared and tested
- [ ] Parallels VM created on external drive
- [ ] Ubuntu Server 22.04.3 LTS installed
- [ ] VM configured with 58GB RAM, 12-16 cores

## Phase 1: System Setup
- [ ] Ubuntu updated and configured
- [ ] Docker installed and configured
- [ ] External drive mounted at /mnt/homelab
- [ ] System optimized for external drive

## Phase 2: AI Stack Installation
- [ ] Ollama installed and configured
- [ ] LocalAI installed
- [ ] Text Generation WebUI installed
- [ ] AI models downloaded and tested

## Phase 3: Service Migration
- [ ] Core infrastructure services running
- [ ] Database services running
- [ ] AI services running
- [ ] All 31 services migrated and running

## Phase 4: Validation
- [ ] All services accessible
- [ ] AI models responding
- [ ] Performance within expected ranges
- [ ] Backup strategy implemented

## Performance Validation
- [ ] VM boot time < 3 minutes
- [ ] 7B model load time < 40 seconds
- [ ] All services start successfully
- [ ] No critical errors in logs
EOF

echo "✅ Migration checklist created"

# Create README for the external drive
cat > "$EXTERNAL_DRIVE/README.md" << 'EOF'
# Homelab External Drive

This external drive contains your homelab VM and all associated data.

## Important Notes

⚠️ **CRITICAL**: This drive must be connected before starting the VM
⚠️ **PERFORMANCE**: Expect slower boot times and model loading due to USB 3.0 speed
⚠️ **BACKUP**: Regular backups recommended due to external drive usage

## Directory Structure

- `ParallelsVMs/HomelabServer/` - VM files
- `HomelabData/docker/` - Docker volumes and data
- `HomelabData/models/` - AI models (Ollama, LocalAI)
- `HomelabData/media/` - Media files
- `HomelabData/backups/` - Backup storage
- `HomelabData/configs/` - Configuration files

## Quick Start

1. Connect external drive to Mac
2. Start Parallels Desktop
3. Open VM from external drive location
4. Follow migration checklist

## Troubleshooting

- If VM won't start: Check drive connection and permissions
- If slow performance: Normal for external drive setup
- If models won't load: Check available RAM (need 58GB)
EOF

echo "✅ README created"

echo ""
echo "🎉 External drive preparation completed!"
echo "=============================================================="
echo "Next steps:"
echo "1. Create Parallels VM with custom location: $EXTERNAL_DRIVE/ParallelsVMs/"
echo "2. Install Ubuntu Server 22.04.3 LTS"
echo "3. Run the Ubuntu setup script inside the VM"
echo ""
echo "Drive location: $EXTERNAL_DRIVE"
echo "VM will be located at: $EXTERNAL_DRIVE/ParallelsVMs/$VM_NAME"
echo ""
echo "⚠️  Remember: VM must be on external drive for this setup to work!"