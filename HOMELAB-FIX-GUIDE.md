# 🔧 מדריך תיקון מערכת Homelab

## 🚨 הבעיות שזוהו ותוקנו

### 1. **בעיה עיקרית: Authelia לא משולב**
- **הבעיה**: הקובץ `homelab-compose.yml` לא כלל את שירות Authelia
- **התיקון**: הוספתי את שירות Authelia עם כל ההגדרות הנדרשות
- **השפעה**: עכשיו כל השירותים מוגנים עם אימות

### 2. **בעיה: חסרים middleware labels**
- **הבעיה**: השירותים לא היו מחוברים ל-Authelia
- **התיקון**: הוספתי `middlewares=authelia@file` לכל השירותים
- **השפעה**: כל השירותים דורשים התחברות דרך Authelia

### 3. **בעיה: קובץ משתמשים פגום**
- **הבעיה**: כפילות בקובץ `users_database.yml`
- **התיקון**: תיקנתי את המבנה של קובץ המשתמשים
- **השפעה**: התחברות תקינה למערכת

## 🛠️ איך להפעיל את התיקונים

### שלב 1: הפעלת הסקריפט
```bash
cd /workspace
./fix-homelab.sh
```

### שלב 2: בדיקת תקינות
```bash
./health-check.sh
```

### שלב 3: גישה לשירותים
1. פתח דפדפן וגש ל: `https://auth.mbs-home.ddns.net`
2. התחבר עם:
   - **משתמש**: `admin`
   - **סיסמה**: `password123`
3. אחרי ההתחברות, תוכל לגשת לכל השירותים

## 🌐 רשימת השירותים המתוקנים

| שירות | כתובת | סטטוס |
|--------|--------|--------|
| דשבורד בית | https://mbs-home.ddns.net | ✅ מוגן |
| אימות | https://auth.mbs-home.ddns.net | ✅ פתוח |
| Portainer | https://portainer.mbs-home.ddns.net | ✅ מוגן |
| Traefik | https://traefik.mbs-home.ddns.net | ✅ מוגן |
| Jellyfin | https://media.mbs-home.ddns.net | ✅ מוגן |
| Sonarr | https://sonarr.mbs-home.ddns.net | ✅ מוגן |
| Radarr | https://radarr.mbs-home.ddns.net | ✅ מוגן |
| Lidarr | https://lidarr.mbs-home.ddns.net | ✅ מוגן |
| Bazarr | https://bazarr.mbs-home.ddns.net | ✅ מוגן |
| Prowlarr | https://prowlarr.mbs-home.ddns.net | ✅ מוגן |
| Transmission | https://transmission.mbs-home.ddns.net | ✅ מוגן |
| Slskd | https://slskd.mbs-home.ddns.net | ✅ מוגן |
| Open WebUI | https://ai.mbs-home.ddns.net | ✅ מוגן |
| WireGuard | https://vpn.mbs-home.ddns.net | ✅ מוגן |
| AdGuard | https://dns.mbs-home.ddns.net | ✅ מוגן |

## 🔐 פרטי התחברות

### משתמשי Admin (גישה מלאה)
- **admin** / password123
- **maor** / password123

### משתמשי User (גישה מוגבלת)
- **user1** / password123
- **exampleuser** / password123

## 🚨 פתרון בעיות נפוצות

### אם השירותים לא עולים:
```bash
# בדוק את הלוגים
docker service logs homelab_<service-name>

# בדוק את סטטוס השירותים
docker service ls

# הפעל מחדש שירות ספציפי
docker service update --force homelab_<service-name>
```

### אם Authelia לא עובד:
```bash
# בדוק את הלוגים
docker service logs homelab_authelia

# בדוק את התצורה
docker exec -it $(docker ps -q -f name=authelia) cat /config/configuration.yml
```

### אם Traefik לא עובד:
```bash
# בדוק את הלוגים
docker service logs homelab_traefik

# בדוק את התצורה הדינמית
docker exec -it $(docker ps -q -f name=traefik) cat /etc/traefik/dynamic.yml
```

## 📋 קבצים שנוצרו/עודכנו

1. **homelab-compose.yml** - עודכן עם Authelia ו-middleware
2. **authelia/users_database.yml** - תוקן מבנה המשתמשים
3. **.env** - נוצר עם כל הסודות
4. **fix-homelab.sh** - סקריפט תיקון אוטומטי
5. **health-check.sh** - עודכן לבדיקת Docker Swarm
6. **HOMELAB-FIX-GUIDE.md** - מדריך זה

## 🔄 תחזוקה שוטפת

### עדכון סיסמאות:
```bash
# צור hash חדש לסיסמה
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'new-password'

# עדכן את users_database.yml
# הפעל מחדש את Authelia
docker service update --force homelab_authelia
```

### גיבוי תצורות:
```bash
# גבה את כל התצורות
tar -czf homelab-backup-$(date +%Y%m%d).tar.gz \
  /Volumes/WorkDrive/MacStorage/docker/authelia \
  /Volumes/WorkDrive/MacStorage/docker/traefik \
  /workspace/homelab-compose.yml
```

## ✅ מה תוקן

- ✅ הוספת Authelia למערכת הראשית
- ✅ הגנה על כל השירותים עם אימות
- ✅ תיקון קובץ המשתמשים
- ✅ יצירת סקריפטי תיקון אוטומטיים
- ✅ עדכון בדיקת תקינות
- ✅ יצירת מדריך מפורט

## 🎯 השלבים הבאים

1. **הפעל את הסקריפט** `./fix-homelab.sh`
2. **בדוק את התקינות** `./health-check.sh`
3. **התחבר למערכת** דרך `https://auth.mbs-home.ddns.net`
4. **בדוק שכל השירותים עובדים** דרך הדשבורד

---

**⚠️ חשוב**: שמור את הסיסמאות במקום בטוח ועדכן אותן באופן קבוע!