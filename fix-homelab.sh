#!/bin/bash

echo "🔧 תיקון מערכת Homelab - מתחיל..."

# בדיקה אם Docker פועל
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker לא פועל. מתחיל Docker..."
    sudo systemctl start docker
    sleep 5
fi

# בדיקה אם Docker Swarm פעיל
if ! docker node ls > /dev/null 2>&1; then
    echo "🔄 מתחיל Docker Swarm..."
    docker swarm init
fi

# יצירת רשתות אם לא קיימות
echo "🌐 יוצר רשתות Docker..."
docker network create --driver overlay frontend 2>/dev/null || true
docker network create --driver overlay backend 2>/dev/null || true
docker network create --driver overlay management 2>/dev/null || true

# עצירת השירותים הקיימים
echo "🛑 עוצר שירותים קיימים..."
docker stack rm homelab 2>/dev/null || true
sleep 10

# המתנה שהשירותים ייעצרו
echo "⏳ ממתין שהשירותים ייעצרו..."
sleep 15

# הפעלת המערכת החדשה
echo "🚀 מפעיל את המערכת המתוקנת..."
docker stack deploy -c homelab-compose.yml homelab

# המתנה שהשירותים יתחילו
echo "⏳ ממתין שהשירותים יתחילו..."
sleep 30

# בדיקת סטטוס השירותים
echo "📊 בודק סטטוס השירותים..."
docker service ls

echo "✅ תיקון הושלם!"
echo ""
echo "🌐 השירותים זמינים ב:"
echo "   - דשבורד בית: https://mbs-home.ddns.net"
echo "   - אימות: https://auth.mbs-home.ddns.net"
echo "   - Portainer: https://portainer.mbs-home.ddns.net"
echo "   - Traefik: https://traefik.mbs-home.ddns.net"
echo ""
echo "🔑 פרטי התחברות:"
echo "   - משתמש: admin"
echo "   - סיסמה: password123"
echo ""
echo "📝 הערות:"
echo "   - כל השירותים מוגנים עכשיו עם Authelia"
echo "   - יש צורך להתחבר דרך auth.mbs-home.ddns.net"
echo "   - אם יש בעיות, בדוק את הלוגים: docker service logs homelab_<service-name>"