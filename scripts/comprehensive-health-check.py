#!/usr/bin/env python3
"""
Comprehensive Homelab Health Check & Validation Script
Validates all services, generates reports, and monitors system health
"""

import json
import subprocess
import datetime
import os
import sys
import time
import requests
from typing import Dict, List, Tuple
import yaml
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from tabulate import tabulate

# Service definitions with health check endpoints
SERVICES = {
    # Core Infrastructure
    'traefik': {
        'url': 'http://localhost:8080/ping',
        'container': 'traefik',
        'critical': True,
        'category': 'Infrastructure'
    },
    'portainer': {
        'url': 'http://localhost:9000',
        'container': 'portainer',
        'critical': True,
        'category': 'Infrastructure'
    },
    'adguard': {
        'url': 'http://localhost:3000',
        'container': 'adguard-home',
        'critical': True,
        'category': 'Infrastructure'
    },
    
    # Security & Access
    'wireguard': {
        'container': 'wireguard',
        'critical': True,
        'category': 'Security',
        'custom_check': 'check_wireguard'
    },
    'authelia': {
        'url': 'http://localhost:9091/api/health',
        'container': 'authelia',
        'critical': True,
        'category': 'Security'
    },
    'vaultwarden': {
        'url': 'http://localhost:80/alive',
        'container': 'vaultwarden',
        'critical': False,
        'category': 'Security'
    },
    
    # Remote Access & Development
    'code-server': {
        'url': 'http://localhost:8443',
        'container': 'code-server',
        'critical': False,
        'category': 'Development'
    },
    'nomachine': {
        'container': 'nomachine',
        'critical': False,
        'category': 'Remote Access',
        'custom_check': 'check_nomachine'
    },
    'filebrowser': {
        'url': 'http://localhost:80/health',
        'container': 'filebrowser',
        'critical': False,
        'category': 'Remote Access'
    },
    'webssh': {
        'url': 'http://localhost:5032',
        'container': 'webssh',
        'critical': False,
        'category': 'Remote Access'
    },
    
    # Financial Management
    'firefly-iii': {
        'url': 'http://localhost:8080/api/v1/about',
        'container': 'firefly-iii',
        'critical': False,
        'category': 'Finance'
    },
    'firefly-db': {
        'container': 'firefly-db',
        'critical': False,
        'category': 'Finance',
        'custom_check': 'check_postgres'
    },
    
    # Media Services
    'jellyfin': {
        'url': 'http://localhost:8096/health',
        'container': 'jellyfin',
        'critical': False,
        'category': 'Media'
    },
    'sonarr': {
        'url': 'http://localhost:8989/api/v3/system/status',
        'container': 'sonarr',
        'critical': False,
        'category': 'Media'
    },
    'radarr': {
        'url': 'http://localhost:7878/api/v3/system/status',
        'container': 'radarr',
        'critical': False,
        'category': 'Media'
    },
    'lidarr': {
        'url': 'http://localhost:8686/api/v1/system/status',
        'container': 'lidarr',
        'critical': False,
        'category': 'Media'
    },
    'bazarr': {
        'url': 'http://localhost:6767',
        'container': 'bazarr',
        'critical': False,
        'category': 'Media'
    },
    'prowlarr': {
        'url': 'http://localhost:9696',
        'container': 'prowlarr',
        'critical': False,
        'category': 'Media'
    },
    
    # Download Clients
    'transmission': {
        'url': 'http://localhost:9091',
        'container': 'transmission',
        'critical': False,
        'category': 'Downloads'
    },
    'slskd': {
        'url': 'http://localhost:5030',
        'container': 'slskd',
        'critical': False,
        'category': 'Downloads'
    },
    
    # Cloud & Productivity
    'nextcloud': {
        'url': 'http://localhost:80/status.php',
        'container': 'nextcloud',
        'critical': False,
        'category': 'Cloud'
    },
    'nextcloud-db': {
        'container': 'nextcloud-db',
        'critical': False,
        'category': 'Cloud',
        'custom_check': 'check_postgres'
    },
    
    # AI & Automation
    'open-webui': {
        'url': 'http://localhost:8080/health',
        'container': 'open-webui',
        'critical': False,
        'category': 'AI'
    },
    'homeassistant': {
        'url': 'http://localhost:8123',
        'container': 'homeassistant',
        'critical': False,
        'category': 'Automation'
    },
    
    # Monitoring
    'prometheus': {
        'url': 'http://localhost:9090/-/ready',
        'container': 'prometheus',
        'critical': True,
        'category': 'Monitoring'
    },
    'grafana': {
        'url': 'http://localhost:3000/api/health',
        'container': 'grafana',
        'critical': False,
        'category': 'Monitoring'
    },
    'dozzle': {
        'url': 'http://localhost:8080',
        'container': 'dozzle',
        'critical': False,
        'category': 'Monitoring'
    }
}

class HomelabHealthChecker:
    def __init__(self):
        self.results = {}
        self.start_time = datetime.datetime.now()
        self.critical_failures = []
        
    def run_command(self, command: List[str]) -> Tuple[int, str, str]:
        """Execute a shell command and return the result"""
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", "Command timed out"
        except Exception as e:
            return 1, "", str(e)
    
    def check_container_status(self, container_name: str) -> Dict:
        """Check if a Docker container is running"""
        cmd = ['docker', 'inspect', container_name, '--format', '{{json .State}}']
        returncode, stdout, stderr = self.run_command(cmd)
        
        if returncode != 0:
            return {
                'running': False,
                'status': 'not_found',
                'health': 'unknown',
                'uptime': 'N/A'
            }
        
        try:
            state = json.loads(stdout)
            return {
                'running': state.get('Running', False),
                'status': state.get('Status', 'unknown'),
                'health': state.get('Health', {}).get('Status', 'none'),
                'uptime': self.calculate_uptime(state.get('StartedAt', ''))
            }
        except json.JSONDecodeError:
            return {
                'running': False,
                'status': 'error',
                'health': 'unknown',
                'uptime': 'N/A'
            }
    
    def calculate_uptime(self, started_at: str) -> str:
        """Calculate container uptime"""
        try:
            if not started_at:
                return 'N/A'
            start_time = datetime.datetime.fromisoformat(started_at.replace('Z', '+00:00'))
            uptime = datetime.datetime.now(datetime.timezone.utc) - start_time
            days = uptime.days
            hours = uptime.seconds // 3600
            minutes = (uptime.seconds % 3600) // 60
            return f"{days}d {hours}h {minutes}m"
        except:
            return 'N/A'
    
    def check_http_endpoint(self, url: str, timeout: int = 5) -> bool:
        """Check if an HTTP endpoint is responding"""
        try:
            response = requests.get(url, timeout=timeout)
            return response.status_code < 500
        except:
            return False
    
    def check_wireguard(self) -> bool:
        """Custom check for WireGuard"""
        cmd = ['docker', 'exec', 'wireguard', 'wg', 'show']
        returncode, stdout, stderr = self.run_command(cmd)
        return returncode == 0
    
    def check_nomachine(self) -> bool:
        """Custom check for NoMachine"""
        cmd = ['docker', 'exec', 'nomachine', 'pgrep', 'nxserver']
        returncode, stdout, stderr = self.run_command(cmd)
        return returncode == 0
    
    def check_postgres(self, container_name: str) -> bool:
        """Custom check for PostgreSQL containers"""
        cmd = ['docker', 'exec', container_name, 'pg_isready']
        returncode, stdout, stderr = self.run_command(cmd)
        return returncode == 0
    
    def get_container_stats(self, container_name: str) -> Dict:
        """Get container resource usage statistics"""
        cmd = ['docker', 'stats', container_name, '--no-stream', '--format', 
               '{{json .}}']
        returncode, stdout, stderr = self.run_command(cmd)
        
        if returncode != 0:
            return {
                'cpu': 'N/A',
                'memory': 'N/A',
                'memory_percent': 'N/A',
                'network_io': 'N/A'
            }
        
        try:
            stats = json.loads(stdout)
            return {
                'cpu': stats.get('CPUPerc', 'N/A'),
                'memory': stats.get('MemUsage', 'N/A'),
                'memory_percent': stats.get('MemPerc', 'N/A'),
                'network_io': f"{stats.get('NetIO', 'N/A')}"
            }
        except json.JSONDecodeError:
            return {
                'cpu': 'N/A',
                'memory': 'N/A',
                'memory_percent': 'N/A',
                'network_io': 'N/A'
            }
    
    def check_service(self, name: str, config: Dict) -> Dict:
        """Comprehensive check for a single service"""
        result = {
            'name': name,
            'category': config.get('category', 'Unknown'),
            'critical': config.get('critical', False),
            'container_status': {},
            'endpoint_status': None,
            'custom_check': None,
            'stats': {},
            'health_score': 0,
            'issues': []
        }
        
        # Check container status
        container_name = config.get('container')
        if container_name:
            result['container_status'] = self.check_container_status(container_name)
            if not result['container_status']['running']:
                result['issues'].append(f"Container {container_name} is not running")
                if config.get('critical'):
                    self.critical_failures.append(name)
            
            # Get container stats
            if result['container_status']['running']:
                result['stats'] = self.get_container_stats(container_name)
        
        # Check HTTP endpoint
        if 'url' in config:
            result['endpoint_status'] = self.check_http_endpoint(config['url'])
            if not result['endpoint_status']:
                result['issues'].append(f"Endpoint {config['url']} is not responding")
        
        # Run custom checks
        if 'custom_check' in config:
            check_method = getattr(self, config['custom_check'])
            if config['custom_check'] == 'check_postgres':
                result['custom_check'] = check_method(container_name)
            else:
                result['custom_check'] = check_method()
            
            if not result['custom_check']:
                result['issues'].append(f"Custom check {config['custom_check']} failed")
        
        # Calculate health score
        score = 0
        total = 0
        
        if result['container_status']:
            total += 40
            if result['container_status'].get('running'):
                score += 40
        
        if result['endpoint_status'] is not None:
            total += 40
            if result['endpoint_status']:
                score += 40
        
        if result['custom_check'] is not None:
            total += 20
            if result['custom_check']:
                score += 20
        
        if total > 0:
            result['health_score'] = (score / total) * 100
        else:
            result['health_score'] = 0
        
        return result
    
    def check_all_services(self):
        """Check all defined services"""
        print("🔍 Starting comprehensive health check...")
        print("-" * 60)
        
        for name, config in SERVICES.items():
            print(f"Checking {name}...", end=" ")
            self.results[name] = self.check_service(name, config)
            
            if self.results[name]['health_score'] >= 95:
                print("✅ Healthy")
            elif self.results[name]['health_score'] >= 70:
                print("⚠️  Warning")
            else:
                print("❌ Critical")
        
        print("-" * 60)
    
    def generate_report(self) -> str:
        """Generate a comprehensive health report"""
        report = []
        report.append("=" * 80)
        report.append("HOMELAB COMPREHENSIVE HEALTH REPORT")
        report.append("=" * 80)
        report.append(f"Generated: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"Scan Duration: {(datetime.datetime.now() - self.start_time).total_seconds():.2f} seconds")
        report.append("")
        
        # Executive Summary
        total_services = len(self.results)
        healthy_services = sum(1 for r in self.results.values() if r['health_score'] >= 95)
        warning_services = sum(1 for r in self.results.values() if 70 <= r['health_score'] < 95)
        critical_services = sum(1 for r in self.results.values() if r['health_score'] < 70)
        
        report.append("📊 EXECUTIVE SUMMARY")
        report.append("-" * 40)
        report.append(f"Total Services: {total_services}")
        report.append(f"✅ Healthy: {healthy_services} ({healthy_services/total_services*100:.1f}%)")
        report.append(f"⚠️  Warning: {warning_services} ({warning_services/total_services*100:.1f}%)")
        report.append(f"❌ Critical: {critical_services} ({critical_services/total_services*100:.1f}%)")
        
        if self.critical_failures:
            report.append(f"\n🚨 CRITICAL SERVICES DOWN: {', '.join(self.critical_failures)}")
        
        report.append("")
        
        # Service Status Matrix
        report.append("📋 SERVICE STATUS MATRIX")
        report.append("-" * 40)
        
        # Group by category
        categories = {}
        for name, result in self.results.items():
            category = result['category']
            if category not in categories:
                categories[category] = []
            categories[category].append(result)
        
        for category, services in sorted(categories.items()):
            report.append(f"\n{category}:")
            
            table_data = []
            for service in services:
                status_icon = "✅" if service['health_score'] >= 95 else "⚠️" if service['health_score'] >= 70 else "❌"
                
                table_data.append([
                    service['name'],
                    status_icon,
                    f"{service['health_score']:.0f}%",
                    service['container_status'].get('uptime', 'N/A'),
                    service['stats'].get('cpu', 'N/A'),
                    service['stats'].get('memory_percent', 'N/A')
                ])
            
            headers = ['Service', 'Status', 'Health', 'Uptime', 'CPU', 'Memory']
            report.append(tabulate(table_data, headers=headers, tablefmt='grid'))
        
        # Issues and Recommendations
        report.append("\n⚠️  ISSUES & RECOMMENDATIONS")
        report.append("-" * 40)
        
        has_issues = False
        for name, result in self.results.items():
            if result['issues']:
                has_issues = True
                report.append(f"\n{name}:")
                for issue in result['issues']:
                    report.append(f"  - {issue}")
        
        if not has_issues:
            report.append("No issues detected! All systems operational.")
        
        # Performance Metrics
        report.append("\n📈 PERFORMANCE METRICS")
        report.append("-" * 40)
        
        # Calculate average response times (simplified)
        report.append("Average Health Score: {:.1f}%".format(
            sum(r['health_score'] for r in self.results.values()) / len(self.results)
        ))
        
        # System recommendations
        report.append("\n💡 RECOMMENDATIONS")
        report.append("-" * 40)
        
        if critical_services > 0:
            report.append("1. URGENT: Address critical service failures immediately")
        if warning_services > 0:
            report.append("2. Review and resolve warning-level services")
        report.append("3. Consider implementing automated recovery for failed services")
        report.append("4. Review resource allocation for high-usage containers")
        report.append("5. Ensure all critical services have backup configurations")
        
        report.append("\n" + "=" * 80)
        report.append("END OF REPORT")
        report.append("=" * 80)
        
        return "\n".join(report)
    
    def save_report(self, report: str, filename: str = None):
        """Save report to file"""
        if not filename:
            timestamp = self.start_time.strftime('%Y%m%d_%H%M%S')
            filename = f"health_report_{timestamp}.txt"
        
        os.makedirs("reports", exist_ok=True)
        filepath = os.path.join("reports", filename)
        
        with open(filepath, 'w') as f:
            f.write(report)
        
        print(f"\n📄 Report saved to: {filepath}")
        return filepath
    
    def send_email_report(self, report: str, config: Dict):
        """Send email report (requires SMTP configuration)"""
        try:
            msg = MIMEMultipart()
            msg['From'] = config['from_email']
            msg['To'] = config['to_email']
            msg['Subject'] = f"Homelab Health Report - {self.start_time.strftime('%Y-%m-%d')}"
            
            msg.attach(MIMEText(report, 'plain'))
            
            with smtplib.SMTP(config['smtp_host'], config['smtp_port']) as server:
                if config.get('smtp_tls'):
                    server.starttls()
                if config.get('smtp_user') and config.get('smtp_password'):
                    server.login(config['smtp_user'], config['smtp_password'])
                server.send_message(msg)
            
            print(f"📧 Email report sent to {config['to_email']}")
            return True
        except Exception as e:
            print(f"❌ Failed to send email: {e}")
            return False

def main():
    """Main execution function"""
    checker = HomelabHealthChecker()
    
    # Run health checks
    checker.check_all_services()
    
    # Generate report
    report = checker.generate_report()
    
    # Display report
    print("\n" + report)
    
    # Save report
    checker.save_report(report)
    
    # Check for critical failures
    if checker.critical_failures:
        print("\n🚨 CRITICAL FAILURES DETECTED!")
        print(f"Failed services: {', '.join(checker.critical_failures)}")
        sys.exit(1)
    else:
        print("\n✅ All critical services operational!")
        sys.exit(0)

if __name__ == "__main__":
    main()