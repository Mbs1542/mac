#!/bin/bash
# Monitoring and Validation Scripts for Homelab with AI
# Run this INSIDE the Ubuntu VM after migration is complete

set -e

echo "📊 Creating Monitoring and Validation Scripts"
echo "============================================="

# Check if homelab mount exists
if [ ! -d "/mnt/homelab" ]; then
    echo "❌ Homelab mount point not found at /mnt/homelab"
    exit 1
fi

# Create monitoring directory
mkdir -p /mnt/homelab/scripts/monitoring
mkdir -p /mnt/homelab/logs

# 1. AI Services Monitor
echo "🤖 Creating AI services monitor..."

cat > /mnt/homelab/scripts/monitoring/ai-monitor.sh << 'EOF'
#!/bin/bash
# AI Services Monitor

echo "🤖 AI Services Monitor"
echo "====================="

# Check Ollama
echo "📊 Ollama Status:"
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama: Running"
    echo "📈 Loaded models:"
    ollama list 2>/dev/null | while read line; do
        echo "   $line"
    done
    echo ""
    echo "💾 Memory usage:"
    ps aux | grep ollama | grep -v grep | awk '{print "   CPU: " $3 "%, Memory: " $4 "%, RSS: " $6 "KB"}'
else
    echo "❌ Ollama: Not running"
fi

echo ""

# Check Docker AI services
echo "🐳 Docker AI Services:"
echo "Ollama Container:"
docker ps --filter "name=ollama" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.MemUsage}}" 2>/dev/null || echo "   Not running"

echo ""
echo "LocalAI Container:"
docker ps --filter "name=localai" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.MemUsage}}" 2>/dev/null || echo "   Not running"

echo ""
echo "Text Generation WebUI:"
docker ps --filter "name=textgen" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.MemUsage}}" 2>/dev/null || echo "   Not running"

echo ""
echo "Open WebUI:"
docker ps --filter "name=open-webui" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.MemUsage}}" 2>/dev/null || echo "   Not running"

echo ""

# Test AI API endpoints
echo "🔌 API Endpoint Tests:"
echo "Ollama API (localhost:11434):"
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama API: Responding"
else
    echo "❌ Ollama API: Not responding"
fi

echo "LocalAI API (localhost:8080):"
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ LocalAI API: Responding"
else
    echo "❌ LocalAI API: Not responding"
fi

echo "Text Generation WebUI (localhost:7860):"
if curl -s http://localhost:7860 > /dev/null 2>&1; then
    echo "✅ Text Generation WebUI: Responding"
else
    echo "❌ Text Generation WebUI: Not responding"
fi

echo "Open WebUI (localhost:3001):"
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "✅ Open WebUI: Responding"
else
    echo "❌ Open WebUI: Not responding"
fi
EOF

chmod +x /mnt/homelab/scripts/monitoring/ai-monitor.sh

# 2. System Performance Monitor
echo "🖥️ Creating system performance monitor..."

cat > /mnt/homelab/scripts/monitoring/system-monitor.sh << 'EOF'
#!/bin/bash
# System Performance Monitor

echo "🖥️ System Performance Monitor"
echo "============================="

# System overview
echo "📊 System Overview:"
echo "Uptime: $(uptime)"
echo "Load Average: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo ""

# CPU usage
echo "🖥️ CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print "   User: " $2 ", System: " $4 ", I/O Wait: " $10}'
echo ""

# Memory usage
echo "💾 Memory Usage:"
free -h | while read line; do
    echo "   $line"
done
echo ""

# Disk usage
echo "💿 Disk Usage:"
df -h | grep -E "(Filesystem|/mnt/homelab|/mnt/ramdisk)" | while read line; do
    echo "   $line"
done
echo ""

# External drive I/O
echo "🔌 External Drive I/O:"
iostat -x 1 1 | grep -E "(Device|sd|nvme)" | while read line; do
    echo "   $line"
done
echo ""

# Network usage
echo "🌐 Network Usage:"
cat /proc/net/dev | grep -E "(eth|ens|enp)" | head -5 | while read line; do
    echo "   $line"
done
echo ""

# Docker resource usage
echo "🐳 Docker Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null || echo "   Docker not running"
EOF

chmod +x /mnt/homelab/scripts/monitoring/system-monitor.sh

# 3. Service Health Monitor
echo "⚙️ Creating service health monitor..."

cat > /mnt/homelab/scripts/monitoring/service-monitor.sh << 'EOF'
#!/bin/bash
# Service Health Monitor

echo "⚙️ Service Health Monitor"
echo "========================"

# Check system services
echo "🔧 System Services:"
systemctl list-units --type=service --state=running | grep -E "(docker|ollama|traefik)" | while read line; do
    echo "   $line"
done
echo ""

# Check Docker services
echo "🐳 Docker Services:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.CreatedAt}}" | while read line; do
    echo "   $line"
done
echo ""

# Check service health endpoints
echo "🔌 Service Health Checks:"
echo "Traefik Dashboard:"
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Traefik: Responding"
else
    echo "❌ Traefik: Not responding"
fi

echo "AdGuard Home:"
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ AdGuard: Responding"
else
    echo "❌ AdGuard: Not responding"
fi

echo "Nextcloud:"
if curl -s http://localhost:8081 > /dev/null 2>&1; then
    echo "✅ Nextcloud: Responding"
else
    echo "❌ Nextcloud: Not responding"
fi

echo "Jellyfin:"
if curl -s http://localhost:8096 > /dev/null 2>&1; then
    echo "✅ Jellyfin: Responding"
else
    echo "❌ Jellyfin: Not responding"
fi

echo "Portainer:"
if curl -s http://localhost:9000 > /dev/null 2>&1; then
    echo "✅ Portainer: Responding"
else
    echo "❌ Portainer: Not responding"
fi

echo "Prometheus:"
if curl -s http://localhost:9090 > /dev/null 2>&1; then
    echo "✅ Prometheus: Responding"
else
    echo "❌ Prometheus: Not responding"
fi

echo "Grafana:"
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Grafana: Responding"
else
    echo "❌ Grafana: Not responding"
fi
EOF

chmod +x /mnt/homelab/scripts/monitoring/service-monitor.sh

# 4. AI Model Performance Test
echo "🧪 Creating AI model performance test..."

cat > /mnt/homelab/scripts/monitoring/ai-performance-test.sh << 'EOF'
#!/bin/bash
# AI Model Performance Test

echo "🧪 AI Model Performance Test"
echo "============================"

# Test Ollama model loading and inference
echo "🤖 Testing Ollama Performance:"
if systemctl is-active --quiet ollama; then
    echo "Loading Llama2 7B model..."
    start_time=$(date +%s)
    ollama run llama2:7b "Hello, this is a performance test. Please respond with a short message." > /dev/null 2>&1
    end_time=$(date +%s)
    load_time=$((end_time - start_time))
    echo "✅ Model load and inference time: ${load_time} seconds"
    
    # Test inference speed
    echo "Testing inference speed..."
    start_time=$(date +%s)
    ollama run llama2:7b "What is 2+2?" > /dev/null 2>&1
    end_time=$(date +%s)
    inference_time=$((end_time - start_time))
    echo "✅ Inference time: ${inference_time} seconds"
else
    echo "❌ Ollama not running, skipping test"
fi

echo ""

# Test Docker AI services
echo "🐳 Testing Docker AI Services:"
echo "LocalAI Health Check:"
if curl -s http://localhost:8080/health > /dev/null 2>&1; then
    echo "✅ LocalAI: Healthy"
else
    echo "❌ LocalAI: Not responding"
fi

echo "Text Generation WebUI Health Check:"
if curl -s http://localhost:7860 > /dev/null 2>&1; then
    echo "✅ Text Generation WebUI: Responding"
else
    echo "❌ Text Generation WebUI: Not responding"
fi

echo "Open WebUI Health Check:"
if curl -s http://localhost:3001 > /dev/null 2>&1; then
    echo "✅ Open WebUI: Responding"
else
    echo "❌ Open WebUI: Not responding"
fi

echo ""

# Test external drive performance
echo "💿 Testing External Drive Performance:"
echo "Write Speed Test:"
dd if=/dev/zero of=/mnt/homelab/speedtest bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s' | while read speed; do
    echo "✅ Write Speed: $speed"
done

echo "Read Speed Test:"
dd if=/mnt/homelab/speedtest of=/dev/null bs=1024k 2>&1 | grep -o '[0-9.]* MB/s' | while read speed; do
    echo "✅ Read Speed: $speed"
done

# Clean up test file
rm -f /mnt/homelab/speedtest

echo ""
echo "✅ Performance test completed"
EOF

chmod +x /mnt/homelab/scripts/monitoring/ai-performance-test.sh

# 5. Comprehensive Health Check
echo "🏥 Creating comprehensive health check..."

cat > /mnt/homelab/scripts/monitoring/health-check.sh << 'EOF'
#!/bin/bash
# Comprehensive Health Check

echo "🏥 Homelab Health Check"
echo "======================="

# Overall system health
echo "🖥️ System Health:"
echo "Uptime: $(uptime)"
echo "Load: $(cat /proc/loadavg | awk '{print $1}')"
echo "Memory: $(free | grep Mem | awk '{printf "%.1f%% used", $3/$2 * 100.0}')"
echo "Disk: $(df /mnt/homelab | tail -1 | awk '{printf "%.1f%% used", $5}')"
echo ""

# Service status
echo "⚙️ Service Status:"
services=("docker" "ollama" "traefik")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
    fi
done
echo ""

# Docker containers
echo "🐳 Docker Containers:"
running_containers=$(docker ps --format "{{.Names}}" | wc -l)
total_containers=$(docker ps -a --format "{{.Names}}" | wc -l)
echo "Running: $running_containers / $total_containers"

# Check for unhealthy containers
unhealthy=$(docker ps --filter "health=unhealthy" --format "{{.Names}}" | wc -l)
if [ "$unhealthy" -gt 0 ]; then
    echo "⚠️ Unhealthy containers: $unhealthy"
    docker ps --filter "health=unhealthy" --format "{{.Names}}"
else
    echo "✅ All containers healthy"
fi
echo ""

# AI services
echo "🤖 AI Services:"
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama: Running"
    models=$(ollama list 2>/dev/null | wc -l)
    echo "   Models available: $models"
else
    echo "❌ Ollama: Not running"
fi

# Check AI Docker services
ai_services=("ollama" "localai" "textgen" "open-webui")
for service in "${ai_services[@]}"; do
    if docker ps --filter "name=$service" --format "{{.Names}}" | grep -q "$service"; then
        echo "✅ $service: Running"
    else
        echo "❌ $service: Not running"
    fi
done
echo ""

# Network connectivity
echo "🌐 Network Connectivity:"
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet: Connected"
else
    echo "❌ Internet: Not connected"
fi

# Check local services
local_services=("localhost:11434" "localhost:8080" "localhost:7860" "localhost:3001")
for service in "${local_services[@]}"; do
    if curl -s "http://$service" > /dev/null 2>&1; then
        echo "✅ $service: Responding"
    else
        echo "❌ $service: Not responding"
    fi
done
echo ""

# External drive health
echo "💿 External Drive Health:"
if [ -d "/mnt/homelab" ]; then
    echo "✅ Mounted: /mnt/homelab"
    usage=$(df /mnt/homelab | tail -1 | awk '{print $5}')
    echo "   Usage: $usage"
    
    # Check for I/O errors
    io_errors=$(dmesg | grep -i "i/o error" | wc -l)
    if [ "$io_errors" -gt 0 ]; then
        echo "⚠️ I/O Errors: $io_errors"
    else
        echo "✅ No I/O errors"
    fi
else
    echo "❌ External drive not mounted"
fi
echo ""

# Performance summary
echo "📊 Performance Summary:"
echo "Expected vs Actual:"
echo "- VM Boot: 2-3 minutes (check uptime)"
echo "- 7B Model Load: 30-40 seconds"
echo "- External Drive Speed: ~158MB/s"
echo "- Container Starts: +20-30% slower than internal"

echo ""
echo "✅ Health check completed"
EOF

chmod +x /mnt/homelab/scripts/monitoring/health-check.sh

# 6. Alerting Script
echo "🚨 Creating alerting script..."

cat > /mnt/homelab/scripts/monitoring/alerting.sh << 'EOF'
#!/bin/bash
# Alerting Script for Homelab

echo "🚨 Homelab Alerting System"
echo "========================="

# Check critical services
critical_services=("docker" "ollama")
for service in "${critical_services[@]}"; do
    if ! systemctl is-active --quiet "$service"; then
        echo "🚨 ALERT: $service is not running!"
        # Here you could add email notifications, webhooks, etc.
    fi
done

# Check disk space
usage=$(df /mnt/homelab | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$usage" -gt 90 ]; then
    echo "🚨 ALERT: Disk usage is ${usage}% - running out of space!"
fi

# Check memory usage
memory_usage=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
if [ "$memory_usage" -gt 90 ]; then
    echo "🚨 ALERT: Memory usage is ${memory_usage}% - high memory usage!"
fi

# Check for I/O errors
io_errors=$(dmesg | grep -i "i/o error" | wc -l)
if [ "$io_errors" -gt 0 ]; then
    echo "🚨 ALERT: $io_errors I/O errors detected on external drive!"
fi

# Check Docker containers
unhealthy=$(docker ps --filter "health=unhealthy" --format "{{.Names}}" | wc -l)
if [ "$unhealthy" -gt 0 ]; then
    echo "🚨 ALERT: $unhealthy unhealthy Docker containers!"
fi

echo "✅ Alerting check completed"
EOF

chmod +x /mnt/homelab/scripts/monitoring/alerting.sh

# 7. Create monitoring dashboard script
echo "📊 Creating monitoring dashboard..."

cat > /mnt/homelab/scripts/monitoring/dashboard.sh << 'EOF'
#!/bin/bash
# Monitoring Dashboard

echo "📊 Homelab Monitoring Dashboard"
echo "==============================="
echo ""

# System overview
echo "🖥️ System Overview:"
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime | awk '{print $3, $4}' | sed 's/,//')"
echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo ""

# Resource usage
echo "💾 Resource Usage:"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2 " (" $3/$2*100 "%)"}')"
echo "Disk: $(df -h /mnt/homelab | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"
echo ""

# Services status
echo "⚙️ Services Status:"
echo "Docker: $(systemctl is-active docker 2>/dev/null || echo "unknown")"
echo "Ollama: $(systemctl is-active ollama 2>/dev/null || echo "unknown")"
echo "Traefik: $(systemctl is-active traefik 2>/dev/null || echo "unknown")"
echo ""

# Docker containers
echo "🐳 Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | head -10
echo ""

# AI services
echo "🤖 AI Services:"
if systemctl is-active --quiet ollama; then
    echo "Ollama: Running ($(ollama list 2>/dev/null | wc -l) models)"
else
    echo "Ollama: Not running"
fi

# Check AI Docker services
ai_services=("ollama" "localai" "textgen" "open-webui")
for service in "${ai_services[@]}"; do
    status=$(docker ps --filter "name=$service" --format "{{.Status}}" 2>/dev/null || echo "Not running")
    echo "$service: $status"
done
echo ""

# Network status
echo "🌐 Network Status:"
echo "Internet: $(ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "Connected" || echo "Disconnected")"
echo "Local Services:"
local_services=("11434:Ollama" "8080:LocalAI" "7860:TextGen" "3001:OpenWebUI")
for service in "${local_services[@]}"; do
    port=$(echo $service | cut -d: -f1)
    name=$(echo $service | cut -d: -f2)
    if curl -s "http://localhost:$port" > /dev/null 2>&1; then
        echo "  $name: ✅"
    else
        echo "  $name: ❌"
    fi
done
echo ""

# External drive status
echo "💿 External Drive:"
if [ -d "/mnt/homelab" ]; then
    echo "Status: Mounted"
    echo "Usage: $(df -h /mnt/homelab | tail -1 | awk '{print $5}')"
    echo "Speed: $(dd if=/dev/zero of=/mnt/homelab/speedtest bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s' | head -1)"
    rm -f /mnt/homelab/speedtest
else
    echo "Status: Not mounted"
fi
echo ""

# Recent logs
echo "📝 Recent Logs:"
echo "Docker logs (last 5 lines):"
docker logs $(docker ps -q | head -1) 2>/dev/null | tail -5 || echo "No logs available"
echo ""

echo "✅ Dashboard updated at $(date)"
EOF

chmod +x /mnt/homelab/scripts/monitoring/dashboard.sh

# 8. Create monitoring cron jobs
echo "⏰ Setting up monitoring cron jobs..."

cat > /mnt/homelab/scripts/monitoring/setup-monitoring.sh << 'EOF'
#!/bin/bash
# Setup Monitoring Cron Jobs

echo "⏰ Setting up monitoring cron jobs..."

# Create log directory
mkdir -p /mnt/homelab/logs

# Add monitoring cron jobs
(crontab -l 2>/dev/null; echo "# Homelab Monitoring") | crontab -
(crontab -l 2>/dev/null; echo "*/5 * * * * /mnt/homelab/scripts/monitoring/health-check.sh >> /mnt/homelab/logs/health-check.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/10 * * * * /mnt/homelab/scripts/monitoring/ai-monitor.sh >> /mnt/homelab/logs/ai-monitor.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "*/15 * * * * /mnt/homelab/scripts/monitoring/system-monitor.sh >> /mnt/homelab/logs/system-monitor.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 */6 * * * /mnt/homelab/scripts/monitoring/alerting.sh >> /mnt/homelab/logs/alerting.log 2>&1") | crontab -
(crontab -l 2>/dev/null; echo "0 0 * * * /mnt/homelab/scripts/monitoring/ai-performance-test.sh >> /mnt/homelab/logs/performance-test.log 2>&1") | crontab -

echo "✅ Monitoring cron jobs set up"
echo "Logs will be saved to: /mnt/homelab/logs/"
EOF

chmod +x /mnt/homelab/scripts/monitoring/setup-monitoring.sh

# Run monitoring setup
/mnt/homelab/scripts/monitoring/setup-monitoring.sh

# 9. Create validation script
echo "✅ Creating validation script..."

cat > /mnt/homelab/scripts/validate-migration.sh << 'EOF'
#!/bin/bash
# Migration Validation Script

echo "✅ Homelab Migration Validation"
echo "==============================="

# Check if all required directories exist
echo "📁 Checking directory structure..."
required_dirs=("/mnt/homelab/docker" "/mnt/homelab/models" "/mnt/homelab/media" "/mnt/homelab/configs" "/mnt/homelab/backups")
for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir missing"
    fi
done
echo ""

# Check if all required scripts exist
echo "📜 Checking scripts..."
required_scripts=("/mnt/homelab/scripts/monitor-ai.sh" "/mnt/homelab/scripts/manage-services.sh" "/mnt/homelab/scripts/backup-homelab.sh")
for script in "${required_scripts[@]}"; do
    if [ -f "$script" ]; then
        echo "✅ $script exists"
    else
        echo "❌ $script missing"
    fi
done
echo ""

# Check Docker services
echo "🐳 Checking Docker services..."
if docker ps > /dev/null 2>&1; then
    echo "✅ Docker is running"
    container_count=$(docker ps --format "{{.Names}}" | wc -l)
    echo "   Containers running: $container_count"
else
    echo "❌ Docker is not running"
fi
echo ""

# Check AI services
echo "🤖 Checking AI services..."
if systemctl is-active --quiet ollama; then
    echo "✅ Ollama is running"
    model_count=$(ollama list 2>/dev/null | wc -l)
    echo "   Models available: $model_count"
else
    echo "❌ Ollama is not running"
fi
echo ""

# Check external drive performance
echo "💿 Checking external drive performance..."
if [ -d "/mnt/homelab" ]; then
    echo "✅ External drive is mounted"
    write_speed=$(dd if=/dev/zero of=/mnt/homelab/speedtest bs=1024k count=1024 2>&1 | grep -o '[0-9.]* MB/s' | head -1)
    echo "   Write speed: $write_speed"
    rm -f /mnt/homelab/speedtest
else
    echo "❌ External drive is not mounted"
fi
echo ""

# Check network connectivity
echo "🌐 Checking network connectivity..."
if ping -c 1 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet connectivity: OK"
else
    echo "❌ Internet connectivity: Failed"
fi
echo ""

# Check service endpoints
echo "🔌 Checking service endpoints..."
endpoints=("localhost:11434:Ollama" "localhost:8080:LocalAI" "localhost:7860:TextGen" "localhost:3001:OpenWebUI")
for endpoint in "${endpoints[@]}"; do
    url=$(echo $endpoint | cut -d: -f1-2)
    name=$(echo $endpoint | cut -d: -f3)
    if curl -s "http://$url" > /dev/null 2>&1; then
        echo "✅ $name: Responding"
    else
        echo "❌ $name: Not responding"
    fi
done
echo ""

# Performance validation
echo "📊 Performance validation..."
echo "Expected vs Actual:"
echo "- VM Boot: 2-3 minutes (actual: check uptime)"
echo "- 7B Model Load: 30-40 seconds"
echo "- External Drive Speed: ~158MB/s"
echo "- Container Starts: +20-30% slower than internal"
echo ""

# Overall validation result
echo "🎯 Overall Validation Result:"
if [ -d "/mnt/homelab" ] && systemctl is-active --quiet docker && systemctl is-active --quiet ollama; then
    echo "✅ Migration validation: PASSED"
    echo "Your homelab with AI services is ready to use!"
else
    echo "❌ Migration validation: FAILED"
    echo "Please check the issues above and resolve them."
fi
EOF

chmod +x /mnt/homelab/scripts/validate-migration.sh

# 10. Create quick status script
echo "⚡ Creating quick status script..."

cat > /mnt/homelab/scripts/quick-status.sh << 'EOF'
#!/bin/bash
# Quick Status Script

echo "⚡ Homelab Quick Status"
echo "======================"

# System status
echo "🖥️ System: $(uptime | awk '{print $3, $4}' | sed 's/,//')"
echo "💾 Memory: $(free | grep Mem | awk '{printf "%.1f%%", $3/$2 * 100.0}')"
echo "💿 Disk: $(df /mnt/homelab | tail -1 | awk '{print $5}')"

# Services status
echo "🐳 Docker: $(systemctl is-active docker 2>/dev/null || echo "stopped")"
echo "🤖 Ollama: $(systemctl is-active ollama 2>/dev/null || echo "stopped")"
echo "🌐 Internet: $(ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "OK" || echo "FAIL")"

# Container count
containers=$(docker ps --format "{{.Names}}" | wc -l)
echo "📦 Containers: $containers running"

# AI models
if systemctl is-active --quiet ollama; then
    models=$(ollama list 2>/dev/null | wc -l)
    echo "🧠 AI Models: $models available"
else
    echo "🧠 AI Models: Ollama not running"
fi

echo ""
echo "✅ Status check completed at $(date)"
EOF

chmod +x /mnt/homelab/scripts/quick-status.sh

echo ""
echo "🎉 Monitoring and Validation Scripts Created!"
echo "============================================="
echo ""
echo "Available monitoring scripts:"
echo "- /mnt/homelab/scripts/monitoring/ai-monitor.sh: AI services monitor"
echo "- /mnt/homelab/scripts/monitoring/system-monitor.sh: System performance monitor"
echo "- /mnt/homelab/scripts/monitoring/service-monitor.sh: Service health monitor"
echo "- /mnt/homelab/scripts/monitoring/ai-performance-test.sh: AI performance test"
echo "- /mnt/homelab/scripts/monitoring/health-check.sh: Comprehensive health check"
echo "- /mnt/homelab/scripts/monitoring/alerting.sh: Alerting system"
echo "- /mnt/homelab/scripts/monitoring/dashboard.sh: Monitoring dashboard"
echo "- /mnt/homelab/scripts/validate-migration.sh: Migration validation"
echo "- /mnt/homelab/scripts/quick-status.sh: Quick status check"
echo ""
echo "Monitoring is now set up with cron jobs running every 5-15 minutes"
echo "Logs are saved to: /mnt/homelab/logs/"
echo ""
echo "Next steps:"
echo "1. Run validation: /mnt/homelab/scripts/validate-migration.sh"
echo "2. Check quick status: /mnt/homelab/scripts/quick-status.sh"
echo "3. View dashboard: /mnt/homelab/scripts/monitoring/dashboard.sh"
echo "4. Test AI performance: /mnt/homelab/scripts/monitoring/ai-performance-test.sh"