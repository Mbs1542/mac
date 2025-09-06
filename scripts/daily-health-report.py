#!/usr/bin/env python3
"""
Homelab Daily Health Report Generator
Generates comprehensive daily reports from Prometheus metrics
"""

import requests
import json
import smtplib
import ssl
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.image import MIMEImage
from datetime import datetime, timedelta
import os
import logging
import matplotlib.pyplot as plt
import io
import base64
from typing import Dict, List, Tuple, Any

# Configuration
PROMETHEUS_URL = "http://prometheus:9090"
GRAFANA_URL = "http://grafana:3000"
SMTP_SERVER = "localhost"
SMTP_PORT = 587
FROM_EMAIL = "homelab@mbs-home.ddns.net"
TO_EMAIL = "admin@mbs-home.ddns.net"
REPORT_TITLE = "Homelab Daily Health Report"

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class PrometheusClient:
    """Client for querying Prometheus metrics"""
    
    def __init__(self, url: str):
        self.url = url
        self.session = requests.Session()
        self.session.timeout = 30
    
    def query(self, query: str) -> Dict[str, Any]:
        """Execute a PromQL query"""
        try:
            response = self.session.get(
                f"{self.url}/api/v1/query",
                params={'query': query}
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Prometheus query failed: {query} - {e}")
            return {'status': 'error', 'data': {'result': []}}
    
    def query_range(self, query: str, start: datetime, end: datetime, step: str = '1h') -> Dict[str, Any]:
        """Execute a PromQL range query"""
        try:
            response = self.session.get(
                f"{self.url}/api/v1/query_range",
                params={
                    'query': query,
                    'start': start.isoformat(),
                    'end': end.isoformat(),
                    'step': step
                }
            )
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Prometheus range query failed: {query} - {e}")
            return {'status': 'error', 'data': {'result': []}}

class HealthReportGenerator:
    """Generates comprehensive health reports"""
    
    def __init__(self, prometheus_url: str):
        self.prom = PrometheusClient(prometheus_url)
        self.report_time = datetime.now()
        self.yesterday = self.report_time - timedelta(days=1)
        
    def get_service_availability(self) -> Dict[str, float]:
        """Get 24-hour service availability metrics"""
        query = "avg_over_time(up[24h])"
        result = self.prom.query(query)
        
        availability = {}
        if result['status'] == 'success':
            for item in result['data']['result']:
                service = item['metric'].get('job', 'unknown')
                availability[service] = float(item['value'][1]) * 100
        
        return availability
    
    def get_resource_usage(self) -> Dict[str, Dict[str, float]]:
        """Get current resource usage metrics"""
        metrics = {
            'cpu': self.prom.query('100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)'),
            'memory': self.prom.query('(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100'),
            'disk': self.prom.query('100 - ((node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes{mountpoint="/"}) * 100)')
        }
        
        usage = {}
        for metric_name, result in metrics.items():
            if result['status'] == 'success' and result['data']['result']:
                usage[metric_name] = float(result['data']['result'][0]['value'][1])
            else:
                usage[metric_name] = 0.0
                
        return {'system': usage}
    
    def get_container_status(self) -> Dict[str, Dict[str, Any]]:
        """Get container status and health"""
        # Container uptime
        uptime_result = self.prom.query('up{job!="prometheus"}')
        
        # Container restarts in last 24h
        restarts_result = self.prom.query('increase(container_restart_count{container_label_com_docker_compose_project="docker"}[24h])')
        
        containers = {}
        
        # Process uptime
        if uptime_result['status'] == 'success':
            for item in uptime_result['data']['result']:
                service = item['metric'].get('job', 'unknown')
                containers[service] = {
                    'status': 'up' if float(item['value'][1]) == 1 else 'down',
                    'uptime': float(item['value'][1]) * 100,
                    'restarts': 0
                }
        
        # Process restarts
        if restarts_result['status'] == 'success':
            for item in restarts_result['data']['result']:
                service = item['metric'].get('container_label_com_docker_compose_service', 'unknown')
                if service in containers:
                    containers[service]['restarts'] = int(float(item['value'][1]))
        
        return containers
    
    def get_ssl_certificate_status(self) -> Dict[str, Dict[str, Any]]:
        """Get SSL certificate expiration status"""
        query = 'probe_ssl_earliest_cert_expiry{job="ssl-expiry"}'
        result = self.prom.query(query)
        
        certificates = {}
        if result['status'] == 'success':
            for item in result['data']['result']:
                domain = item['metric'].get('instance', 'unknown')
                expiry_timestamp = float(item['value'][1])
                expiry_date = datetime.fromtimestamp(expiry_timestamp)
                days_until_expiry = (expiry_date - self.report_time).days
                
                certificates[domain] = {
                    'expiry_date': expiry_date.strftime('%Y-%m-%d %H:%M:%S'),
                    'days_until_expiry': days_until_expiry,
                    'status': 'critical' if days_until_expiry < 7 else 'warning' if days_until_expiry < 30 else 'ok'
                }
        
        return certificates
    
    def get_alerts(self) -> List[Dict[str, Any]]:
        """Get current active alerts"""
        query = 'ALERTS{alertstate="firing"}'
        result = self.prom.query(query)
        
        alerts = []
        if result['status'] == 'success':
            for item in result['data']['result']:
                alerts.append({
                    'name': item['metric'].get('alertname', 'Unknown'),
                    'severity': item['metric'].get('severity', 'unknown'),
                    'instance': item['metric'].get('instance', 'N/A'),
                    'description': item['metric'].get('description', 'No description'),
                    'value': item['value'][1]
                })
        
        return alerts
    
    def get_performance_metrics(self) -> Dict[str, Any]:
        """Get performance trend metrics"""
        now = self.report_time
        yesterday = now - timedelta(days=1)
        
        queries = {
            'avg_response_time': 'avg(probe_duration_seconds{job="blackbox"})',
            'total_requests': 'sum(increase(traefik_requests_total[24h]))',
            'error_rate': 'sum(rate(traefik_requests_total{code=~"5.."}[24h])) / sum(rate(traefik_requests_total[24h])) * 100'
        }
        
        metrics = {}
        for name, query in queries.items():
            result = self.prom.query(query)
            if result['status'] == 'success' and result['data']['result']:
                metrics[name] = float(result['data']['result'][0]['value'][1])
            else:
                metrics[name] = 0.0
        
        return metrics
    
    def create_availability_chart(self, availability_data: Dict[str, float]) -> str:
        """Create availability chart and return base64 encoded image"""
        services = list(availability_data.keys())
        availability_scores = list(availability_data.values())
        
        plt.figure(figsize=(10, 6))
        colors = ['green' if score > 99 else 'orange' if score > 95 else 'red' for score in availability_scores]
        
        bars = plt.bar(services, availability_scores, color=colors, alpha=0.7)
        plt.title('24-Hour Service Availability', fontsize=16, fontweight='bold')
        plt.ylabel('Availability %', fontsize=12)
        plt.xlabel('Services', fontsize=12)
        plt.ylim(0, 100)
        plt.xticks(rotation=45, ha='right')
        
        # Add value labels on bars
        for bar, score in zip(bars, availability_scores):
            plt.text(bar.get_x() + bar.get_width()/2, bar.get_height() + 1, 
                    f'{score:.1f}%', ha='center', va='bottom', fontweight='bold')
        
        # Add SLA line
        plt.axhline(y=99.9, color='red', linestyle='--', alpha=0.7, label='SLA Target (99.9%)')
        plt.legend()
        
        plt.tight_layout()
        
        # Convert to base64
        img_buffer = io.BytesIO()
        plt.savefig(img_buffer, format='png', dpi=150, bbox_inches='tight')
        img_buffer.seek(0)
        img_data = base64.b64encode(img_buffer.getvalue()).decode()
        plt.close()
        
        return img_data

class EmailReporter:
    """Email report sender"""
    
    def __init__(self, smtp_server: str, smtp_port: int, from_email: str):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.from_email = from_email
    
    def generate_html_report(self, 
                           availability: Dict[str, float],
                           resources: Dict[str, Dict[str, float]],
                           containers: Dict[str, Dict[str, Any]],
                           certificates: Dict[str, Dict[str, Any]],
                           alerts: List[Dict[str, Any]],
                           performance: Dict[str, Any],
                           chart_data: str) -> str:
        """Generate HTML email report"""
        
        # Calculate overall health score
        avg_availability = sum(availability.values()) / len(availability) if availability else 0
        critical_services_down = sum(1 for s, a in availability.items() if a < 99 and s in ['traefik', 'jellyfin', 'authelia'])
        active_critical_alerts = sum(1 for a in alerts if a['severity'] == 'critical')
        
        health_score = max(0, min(100, avg_availability - (critical_services_down * 10) - (active_critical_alerts * 15)))
        health_status = 'EXCELLENT' if health_score > 95 else 'GOOD' if health_score > 85 else 'WARNING' if health_score > 70 else 'CRITICAL'
        health_color = '#28a745' if health_score > 95 else '#ffc107' if health_score > 85 else '#fd7e14' if health_score > 70 else '#dc3545'
        
        html = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <title>{REPORT_TITLE}</title>
            <style>
                body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f8f9fa; }}
                .container {{ max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 20px rgba(0,0,0,0.1); }}
                .header {{ text-align: center; margin-bottom: 30px; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 10px; }}
                .health-score {{ font-size: 3em; font-weight: bold; color: {health_color}; }}
                .health-status {{ font-size: 1.5em; color: {health_color}; margin-top: 10px; }}
                .section {{ margin: 25px 0; padding: 20px; border-radius: 8px; background: #f8f9fa; }}
                .section h2 {{ color: #495057; border-bottom: 2px solid #dee2e6; padding-bottom: 10px; }}
                .metrics-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }}
                .metric-card {{ padding: 15px; background: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }}
                .metric-value {{ font-size: 2em; font-weight: bold; color: #495057; }}
                .metric-label {{ color: #6c757d; font-size: 0.9em; }}
                .status-up {{ color: #28a745; font-weight: bold; }}
                .status-down {{ color: #dc3545; font-weight: bold; }}
                .status-warning {{ color: #ffc107; font-weight: bold; }}
                .status-critical {{ color: #dc3545; font-weight: bold; }}
                .status-ok {{ color: #28a745; }}
                table {{ width: 100%; border-collapse: collapse; margin: 15px 0; }}
                th, td {{ padding: 12px; text-align: left; border-bottom: 1px solid #dee2e6; }}
                th {{ background-color: #e9ecef; font-weight: 600; }}
                .chart {{ text-align: center; margin: 20px 0; }}
                .footer {{ text-align: center; margin-top: 30px; padding: 20px; background: #e9ecef; border-radius: 8px; color: #6c757d; }}
                .alert-critical {{ background: #f8d7da; border-left: 4px solid #dc3545; padding: 10px; margin: 5px 0; }}
                .alert-warning {{ background: #fff3cd; border-left: 4px solid #ffc107; padding: 10px; margin: 5px 0; }}
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>{REPORT_TITLE}</h1>
                    <p>{datetime.now().strftime('%B %d, %Y at %H:%M:%S')}</p>
                    <div class="health-score">{health_score:.0f}/100</div>
                    <div class="health-status">{health_status}</div>
                </div>
                
                <div class="section">
                    <h2>🏥 System Health Overview</h2>
                    <div class="metrics-grid">
                        <div class="metric-card">
                            <div class="metric-value">{len([s for s, a in availability.items() if a > 99])}/{len(availability)}</div>
                            <div class="metric-label">Services at 99%+ uptime</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-value">{len(alerts)}</div>
                            <div class="metric-label">Active Alerts</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-value">{resources['system']['cpu']:.1f}%</div>
                            <div class="metric-label">CPU Usage</div>
                        </div>
                        <div class="metric-card">
                            <div class="metric-value">{resources['system']['memory']:.1f}%</div>
                            <div class="metric-label">Memory Usage</div>
                        </div>
                    </div>
                </div>
        """
        
        # Service Availability Section
        if availability:
            html += """
                <div class="section">
                    <h2>🔄 Service Availability (24h)</h2>
                    <div class="chart">
                        <img src="data:image/png;base64,{}" alt="Availability Chart" style="max-width: 100%; height: auto;">
                    </div>
                    <table>
                        <tr><th>Service</th><th>Availability</th><th>Status</th></tr>
            """.format(chart_data)
            
            for service, uptime in sorted(availability.items(), key=lambda x: x[1], reverse=True):
                status_class = 'status-up' if uptime > 99 else 'status-warning' if uptime > 95 else 'status-down'
                html += f'<tr><td>{service}</td><td>{uptime:.2f}%</td><td class="{status_class}">{"🟢 Excellent" if uptime > 99 else "🟡 Warning" if uptime > 95 else "🔴 Critical"}</td></tr>'
            
            html += "</table></div>"
        
        # Container Status Section
        if containers:
            html += """
                <div class="section">
                    <h2>📦 Container Status</h2>
                    <table>
                        <tr><th>Container</th><th>Status</th><th>Restarts (24h)</th></tr>
            """
            
            for container, status in containers.items():
                status_class = 'status-up' if status['status'] == 'up' else 'status-down'
                restart_class = 'status-ok' if status['restarts'] == 0 else 'status-warning' if status['restarts'] < 5 else 'status-critical'
                html += f"""<tr>
                    <td>{container}</td>
                    <td class="{status_class}">{status['status'].upper()}</td>
                    <td class="{restart_class}">{status['restarts']}</td>
                </tr>"""
            
            html += "</table></div>"
        
        # SSL Certificates Section
        if certificates:
            html += """
                <div class="section">
                    <h2>🔐 SSL Certificates</h2>
                    <table>
                        <tr><th>Domain</th><th>Expiry Date</th><th>Days Left</th><th>Status</th></tr>
            """
            
            for domain, cert_info in certificates.items():
                status_class = f"status-{cert_info['status']}"
                status_icon = "🔴 Critical" if cert_info['status'] == 'critical' else "🟡 Warning" if cert_info['status'] == 'warning' else "🟢 OK"
                html += f"""<tr>
                    <td>{domain}</td>
                    <td>{cert_info['expiry_date']}</td>
                    <td>{cert_info['days_until_expiry']}</td>
                    <td class="{status_class}">{status_icon}</td>
                </tr>"""
            
            html += "</table></div>"
        
        # Active Alerts Section
        if alerts:
            html += """
                <div class="section">
                    <h2>🚨 Active Alerts</h2>
            """
            
            for alert in alerts:
                alert_class = f"alert-{alert['severity']}"
                html += f"""<div class="{alert_class}">
                    <strong>{alert['name']}</strong> ({alert['severity'].upper()})<br>
                    <small>Instance: {alert['instance']}</small><br>
                    {alert['description']}
                </div>"""
            
            html += "</div>"
        else:
            html += """
                <div class="section">
                    <h2>🚨 Active Alerts</h2>
                    <p style="color: #28a745; font-weight: bold;">✅ No active alerts - All systems operating normally!</p>
                </div>
            """
        
        # Performance Metrics Section
        html += f"""
            <div class="section">
                <h2>📊 Performance Metrics (24h)</h2>
                <div class="metrics-grid">
                    <div class="metric-card">
                        <div class="metric-value">{performance.get('avg_response_time', 0):.2f}s</div>
                        <div class="metric-label">Average Response Time</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-value">{performance.get('total_requests', 0):,.0f}</div>
                        <div class="metric-label">Total Requests</div>
                    </div>
                    <div class="metric-card">
                        <div class="metric-value">{performance.get('error_rate', 0):.2f}%</div>
                        <div class="metric-label">Error Rate</div>
                    </div>
                </div>
            </div>
        """
        
        # Footer
        html += f"""
                <div class="footer">
                    <p>Generated by Homelab Monitoring System | {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} Asia/Jerusalem</p>
                    <p>For detailed metrics and dashboards, visit <a href="https://monitor.mbs-home.ddns.net">Grafana Dashboard</a></p>
                </div>
            </div>
        </body>
        </html>
        """
        
        return html
    
    def send_report(self, to_email: str, html_content: str, subject: str = None):
        """Send the HTML email report"""
        if not subject:
            subject = f"{REPORT_TITLE} - {datetime.now().strftime('%Y-%m-%d')}"
        
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = self.from_email
        msg['To'] = to_email
        
        html_part = MIMEText(html_content, 'html', 'utf-8')
        msg.attach(html_part)
        
        try:
            with smtplib.SMTP(self.smtp_server, self.smtp_port) as server:
                server.send_message(msg)
            logger.info(f"Report sent successfully to {to_email}")
        except Exception as e:
            logger.error(f"Failed to send email: {e}")
            # Fallback: save report to file
            report_file = f"/tmp/homelab_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.html"
            with open(report_file, 'w', encoding='utf-8') as f:
                f.write(html_content)
            logger.info(f"Report saved to {report_file}")

def main():
    """Main function to generate and send daily report"""
    logger.info("Starting daily health report generation...")
    
    try:
        # Initialize components
        report_generator = HealthReportGenerator(PROMETHEUS_URL)
        email_reporter = EmailReporter(SMTP_SERVER, SMTP_PORT, FROM_EMAIL)
        
        # Gather metrics
        logger.info("Gathering service availability metrics...")
        availability = report_generator.get_service_availability()
        
        logger.info("Gathering resource usage metrics...")
        resources = report_generator.get_resource_usage()
        
        logger.info("Gathering container status...")
        containers = report_generator.get_container_status()
        
        logger.info("Gathering SSL certificate status...")
        certificates = report_generator.get_ssl_certificate_status()
        
        logger.info("Gathering active alerts...")
        alerts = report_generator.get_alerts()
        
        logger.info("Gathering performance metrics...")
        performance = report_generator.get_performance_metrics()
        
        logger.info("Creating availability chart...")
        chart_data = report_generator.create_availability_chart(availability)
        
        # Generate report
        logger.info("Generating HTML report...")
        html_report = email_reporter.generate_html_report(
            availability, resources, containers, certificates, alerts, performance, chart_data
        )
        
        # Send report
        logger.info("Sending email report...")
        email_reporter.send_report(TO_EMAIL, html_report)
        
        logger.info("Daily health report completed successfully!")
        
    except Exception as e:
        logger.error(f"Failed to generate daily report: {e}")
        raise

if __name__ == "__main__":
    main()
