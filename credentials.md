# 🔐 פרטי התחברות למערכת Homelab

## 🌐 מערכת SSO מרכזית (Authelia)
**כתובת**: https://auth.mbs-home.ddns.net

### משתמשים:
- **admin** / **password123** (מנהל מערכת)
- **maor** / **password123** (מאור בן סימון - מנהל)
- **user1** / **password123** (משתמש רגיל)

## 🏠 דשבורד ראשי (Homepage)
**כתובת**: https://mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 🔐 מנהל סיסמאות (Vaultwarden)
**כתובת**: https://vault.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia
**הערה**: צור חשבון חדש בהפעלה ראשונה

## 🏡 השתלטות על הבית (Home Assistant)
**כתובת**: https://home.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia
**הערה**: עדיין מתחיל - יכול לקחת 10-15 דקות

## 📧 שירותי מייל (Mail Server)
**כתובת**: https://mail.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 🎬 שירותי מדיה
### Jellyfin
**כתובת**: https://jellyfin.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Sonarr
**כתובת**: https://sonarr.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Radarr
**כתובת**: https://radarr.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Lidarr
**כתובת**: https://lidarr.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Bazarr
**כתובת**: https://bazarr.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Prowlarr
**כתובת**: https://prowlarr.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 📥 הורדות ושיתוף
### Transmission
**כתובת**: https://transmission.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### slskd
**כתובת**: https://slskd.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 🛠️ ניהול מערכת
### Portainer
**כתובת**: https://portainer.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Traefik Dashboard
**כתובת**: https://traefik.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### AdGuard Home
**כתובת**: https://dns.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### WireGuard
**כתובת**: https://vpn.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 📊 ניטור ומדדים
### Grafana
**כתובת**: https://monitor.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

### Prometheus
**כתובת**: https://prometheus.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 🤖 כלים מתקדמים
### Open WebUI
**כתובת**: https://ai.mbs-home.ddns.net
**הגנה**: SSO דרך Authelia

## 🔒 הרשאות משתמשים

### קבוצת Admins:
- גישה מלאה לכל השירותים
- ניהול משתמשים
- הגדרות מערכת

### קבוצת Users:
- גישה לשירותי מדיה
- גישה לדשבורד
- גישה למנהל סיסמאות

## 📝 הערות חשובות

1. **כל השירותים מוגנים ב-SSO** - התחבר פעם אחת ותקבל גישה לכל השירותים
2. **Vaultwarden** - צור חשבון חדש בהפעלה ראשונה
3. **Home Assistant** - עדיין מתחיל, יכול לקחת 10-15 דקות
4. **מערכת הרשאות** - מנהל יכול להוסיף משתמשים חדשים דרך Authelia
5. **גיבויים אוטומטיים** - מתבצעים ברקע כל יום

## 🚀 איך להתחיל

1. **התחבר ל-Authelia**: https://auth.mbs-home.ddns.net
2. **השתמש ב-credentials**: admin / password123
3. **גש לדשבורד**: https://mbs-home.ddns.net
4. **הגדר Vaultwarden**: https://vault.mbs-home.ddns.net
5. **המתן ל-Home Assistant**: https://home.mbs-home.ddns.net
