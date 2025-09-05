#!/bin/bash

# סקריפט דוח יומי אוטומטי
# שולח דוח יומי על מצב המערכת

# הגדרות
EMAIL_TO="admin@mbs-home.ddns.net"
EMAIL_FROM="noreply@mbs-home.ddns.net"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
LOG_FILE="/tmp/daily-report.log"

# יצירת דוח
echo "=== דוח יומי - $DATE ===" > $LOG_FILE
echo "" >> $LOG_FILE

# בדיקת סטטוס שירותים
echo "📊 סטטוס שירותים:" >> $LOG_FILE
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" >> $LOG_FILE
echo "" >> $LOG_FILE

# בדיקת שימוש בדיסק
echo "💾 שימוש בדיסק:" >> $LOG_FILE
df -h >> $LOG_FILE
echo "" >> $LOG_FILE

# בדיקת זיכרון
echo "🧠 שימוש בזיכרון:" >> $LOG_FILE
free -h >> $LOG_FILE
echo "" >> $LOG_FILE

# בדיקת לוגים של Grafana
echo "📈 לוגים אחרונים של Grafana:" >> $LOG_FILE
docker logs grafana --tail 10 >> $LOG_FILE
echo "" >> $LOG_FILE

# בדיקת לוגים של Prometheus
echo "📊 לוגים אחרונים של Prometheus:" >> $LOG_FILE
docker logs prometheus --tail 10 >> $LOG_FILE
echo "" >> $LOG_FILE

# שליחת המייל
if command -v mail >/dev/null 2>&1; then
    mail -s "דוח יומי - $DATE" -a "From: $EMAIL_FROM" "$EMAIL_TO" < $LOG_FILE
    echo "דוח יומי נשלח בהצלחה ל-$EMAIL_TO"
else
    echo "פקודת mail לא זמינה. הדוח נשמר ב-$LOG_FILE"
fi

# ניקוי
rm -f $LOG_FILE
