#!/bin/bash

# סקריפט דוח יומי אוטומטי
# שולח דוח יומי על מצב המערכת

# הגדרות
EMAIL_TO="admin@mbs-home.ddns.net"
EMAIL_FROM="noreply@mbs-home.ddns.net"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/daily-report.log"
PROM_URL=${PROM_URL:-"http://prometheus:9090"}

# יצירת דוח
{
echo "=== דוח יומי - $DATE ==="
echo ""

# בדיקת סטטוס שירותים
echo "📊 סטטוס שירותים:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

# בדיקת שימוש בדיסק
echo "💾 שימוש בדיסק:"
df -h
echo ""

# בדיקת זיכרון
echo "🧠 שימוש בזיכרון:"
free -h
echo ""

# בדיקת מדדים מ-Prometheus
echo "📡 מדדים מרכזיים (Prometheus):"
if command -v curl >/dev/null 2>&1; then
  echo "- Endpoints down (blackbox):"
  curl -sG "$PROM_URL/api/v1/query" --data-urlencode 'query=probe_success==0' | jq -r '.data.result[] | "  * " + .metric.instance' || true
  echo "- Traefik 5xx rate (req/s):"
  curl -sG "$PROM_URL/api/v1/query" --data-urlencode 'query=sum by (service) (rate(traefik_service_requests_total{code=~"5.."}[5m]))' | jq -r '.data.result[] | "  * " + .metric.service + ": " + .value[1]' || true
  echo "- SSL expiring <14d:"
  curl -sG "$PROM_URL/api/v1/query" --data-urlencode 'query=(probe_ssl_earliest_cert_expiry - time()) < 14 * 24 * 3600' | jq -r '.data.result[] | "  * " + .metric.instance' || true
  echo "- Avg CPU usage (node-exporter):"
  curl -sG "$PROM_URL/api/v1/query" --data-urlencode 'query=100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)' | jq -r '.data.result[] | "  * " + .metric.instance + ": " + .value[1] + "%"' || true
  echo "- Memory available %:"
  curl -sG "$PROM_URL/api/v1/query" --data-urlencode 'query=(node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100' | jq -r '.data.result[] | "  * " + .metric.instance + ": " + .value[1] + "%"' || true
  echo ""
fi

# בדיקת לוגים של Grafana
echo "📈 לוגים אחרונים של Grafana:"
docker logs grafana --tail 10 || true
echo ""

# בדיקת לוגים של Prometheus
echo "📊 לוגים אחרונים של Prometheus:"
docker logs prometheus --tail 10 || true
echo ""

} > $LOG_FILE

# שליחת המייל
if command -v msmtp >/dev/null 2>&1; then
    {
      echo "To: $EMAIL_TO"
      echo "From: $EMAIL_FROM"
      echo "Subject: דוח יומי - $DATE"
      echo "Content-Type: text/plain; charset=UTF-8"
      echo
      cat $LOG_FILE
    } | msmtp -t
    echo "דוח יומי נשלח בהצלחה ל-$EMAIL_TO"
elif command -v sendmail >/dev/null 2>&1; then
    {
      echo "To: $EMAIL_TO"
      echo "From: $EMAIL_FROM"
      echo "Subject: דוח יומי - $DATE"
      echo "Content-Type: text/plain; charset=UTF-8"
      echo
      cat $LOG_FILE
    } | sendmail -t
    echo "דוח יומי נשלח בהצלחה ל-$EMAIL_TO (sendmail)"
else
    echo "msmtp/sendmail לא זמינים. הדוח נשמר ב-$LOG_FILE"
fi

# ניקוי
rm -f $LOG_FILE
