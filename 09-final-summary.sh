#!/bin/bash
# Final Summary and Setup Validation Script

echo "🎉 Homelab Migration to External Drive with AI - Final Summary"
echo "=============================================================="

# Check if all required files exist
echo "📋 Checking required files..."

required_files=(
    "01-external-drive-prep.sh"
    "02-parallels-vm-config.md"
    "03-ubuntu-ai-setup.sh"
    "04-docker-compose-ai.yml"
    "05-external-drive-optimization.sh"
    "06-data-migration.sh"
    "07-monitoring-validation.sh"
    "08-comprehensive-documentation.md"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MISSING"
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo ""
    echo "❌ Missing files detected. Please ensure all files are present."
    exit 1
fi

echo ""
echo "✅ All required files present!"

# Make all scripts executable
echo ""
echo "🔧 Making scripts executable..."
chmod +x *.sh

# Create project summary
echo ""
echo "📊 Project Summary:"
echo "=================="
echo "Total Files Created: ${#required_files[@]}"
echo "Scripts: 6"
echo "Documentation: 2"
echo "Configuration: 1"
echo ""

# Create usage guide
echo "📖 Usage Guide:"
echo "=============="
echo ""
echo "1. EXTERNAL DRIVE PREPARATION (Run on Mac):"
echo "   ./01-external-drive-prep.sh"
echo ""
echo "2. PARALLELS VM CREATION:"
echo "   - Follow 02-parallels-vm-config.md"
echo "   - Create VM on external drive"
echo "   - Install Ubuntu Server 22.04.3 LTS"
echo ""
echo "3. UBUNTU SETUP (Run inside VM):"
echo "   ./03-ubuntu-ai-setup.sh"
echo ""
echo "4. EXTERNAL DRIVE OPTIMIZATION (Run inside VM):"
echo "   ./05-external-drive-optimization.sh"
echo ""
echo "5. DATA MIGRATION (Run inside VM):"
echo "   ./06-data-migration.sh"
echo ""
echo "6. MONITORING SETUP (Run inside VM):"
echo "   ./07-monitoring-validation.sh"
echo ""
echo "7. VALIDATION (Run inside VM):"
echo "   /mnt/homelab/scripts/validate-migration.sh"
echo ""

# Create quick reference
echo "⚡ Quick Reference:"
echo "=================="
echo ""
echo "Key Commands (after setup):"
echo "- homelab-status: Check AI services status"
echo "- homelab-start: Start all services"
echo "- homelab-stop: Stop all services"
echo "- homelab-restart: Restart all services"
echo "- homelab-backup: Create backup"
echo "- homelab-info: Show system information"
echo ""

echo "Monitoring Scripts:"
echo "- /mnt/homelab/scripts/monitoring/ai-monitor.sh"
echo "- /mnt/homelab/scripts/monitoring/system-monitor.sh"
echo "- /mnt/homelab/scripts/monitoring/health-check.sh"
echo "- /mnt/homelab/scripts/monitoring/dashboard.sh"
echo ""

echo "Service Endpoints:"
echo "- Ollama API: http://localhost:11434"
echo "- LocalAI: http://localhost:8080"
echo "- Text Generation WebUI: http://localhost:7860"
echo "- Open WebUI: http://localhost:3001"
echo ""

# Create performance expectations
echo "📈 Performance Expectations:"
echo "============================"
echo ""
echo "External Drive Setup (158MB/s):"
echo "- VM Boot: 2-3 minutes"
echo "- 7B Model Load: 30-40 seconds"
echo "- 13B Model Load: 60-90 seconds"
echo "- Mixtral 8x7B Load: 3-4 minutes"
echo "- Container Starts: +20-30% slower"
echo ""

echo "Resource Requirements:"
echo "- RAM: 58GB (40GB services + 18GB AI)"
echo "- CPU: 12-16 cores"
echo "- Storage: 500GB+"
echo "- Network: Ethernet (bridged)"
echo ""

# Create troubleshooting quick reference
echo "🔧 Troubleshooting Quick Reference:"
echo "==================================="
echo ""
echo "Common Issues:"
echo "1. VM won't start: Check external drive connection"
echo "2. Slow performance: Normal for external drive setup"
echo "3. AI models won't load: Check RAM allocation"
echo "4. Services failing: Check Docker logs"
echo "5. Network issues: Check firewall and ports"
echo ""

echo "Useful Commands:"
echo "- Check system status: /mnt/homelab/scripts/quick-status.sh"
echo "- Monitor performance: /mnt/homelab/scripts/monitoring/dashboard.sh"
echo "- Test AI performance: /mnt/homelab/scripts/monitoring/ai-performance-test.sh"
echo "- Check logs: docker compose logs"
echo ""

# Create next steps
echo "🚀 Next Steps:"
echo "============="
echo ""
echo "1. Review 08-comprehensive-documentation.md for detailed information"
echo "2. Follow the installation guide step by step"
echo "3. Test all services after migration"
echo "4. Set up monitoring and alerting"
echo "5. Create regular backup schedule"
echo "6. Monitor performance and optimize as needed"
echo ""

# Create success criteria
echo "✅ Success Criteria:"
echo "==================="
echo ""
echo "Migration is successful when:"
echo "- All 31 services are running"
echo "- AI models are loaded and responding"
echo "- Performance is within expected ranges"
echo "- Monitoring is active and working"
echo "- Backups are configured and tested"
echo ""

# Create final checklist
echo "📋 Final Checklist:"
echo "=================="
echo ""
echo "Before starting:"
echo "- [ ] External drive connected and formatted"
echo "- [ ] Parallels Desktop installed and licensed"
echo "- [ ] 58GB RAM available for VM"
echo "- [ ] Ubuntu Server 22.04.3 LTS ISO ready"
echo "- [ ] Source data location identified"
echo ""
echo "After migration:"
echo "- [ ] All services running"
echo "- [ ] AI models responding"
echo "- [ ] Performance acceptable"
echo "- [ ] Monitoring active"
echo "- [ ] Backups working"
echo ""

echo "🎉 Setup Complete!"
echo "=================="
echo ""
echo "Your homelab migration to external drive with AI is ready to begin!"
echo "Follow the usage guide above to get started."
echo ""
echo "For detailed information, see: 08-comprehensive-documentation.md"
echo "For troubleshooting, see the troubleshooting section in the documentation."
echo ""
echo "Good luck with your homelab migration! 🚀"