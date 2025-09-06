#!/bin/bash

# Test script for daily health report
echo "Testing Daily Health Report System..."
echo "====================================="
echo

# Test Prometheus connectivity
echo "Testing Prometheus connectivity..."
curl -s -f http://localhost:9090/api/v1/query?query=up >/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Prometheus is accessible"
else
    echo "❌ Prometheus is not accessible"
fi

# Test Grafana connectivity  
echo "Testing Grafana connectivity..."
curl -s -f http://localhost:3000/api/health >/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Grafana is accessible"
else
    echo "❌ Grafana is not accessible"
fi

echo
echo "Running daily health report generation..."
echo "========================================"

# Run the Python script
python3 /Volumes/WorkDrive/MacStorage/docker/scripts/daily-health-report.py

echo
echo "Test completed. Check /var/log/homelab-reports/ for output."
