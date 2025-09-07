# 🚨 CRITICAL HOMELAB RECOVERY PACKAGE 🚨

## What This Package Contains

This package contains everything you need to recover your homelab from the current critical state where `mbs-home.ddns.net` returns 404 and all services are down.

## Files Included

1. **`emergency-recovery.sh`** - Main recovery script (RUN THIS FIRST)
2. **`test-recovery.sh`** - Test script to verify recovery
3. **`docker-compose.yml`** - Minimal working configuration
4. **`traefik/config/traefik.yml`** - Traefik configuration
5. **`RECOVERY-GUIDE.md`** - Detailed step-by-step guide
6. **`README-RECOVERY.md`** - This file

## IMMEDIATE ACTION REQUIRED

### Step 1: Run Emergency Recovery
```bash
# On your server, run:
chmod +x emergency-recovery.sh
./emergency-recovery.sh
```

### Step 2: Test Recovery
```bash
# After recovery, test:
chmod +x test-recovery.sh
./test-recovery.sh
```

### Step 3: Report Results
Send me the output of both scripts so I can help you with the next steps.

## What the Recovery Script Does

1. **Stops all containers** and cleans up broken configuration
2. **Creates backup** of current broken setup
3. **Creates minimal working directories** for Traefik and data
4. **Creates minimal docker-compose.yml** with only Traefik and a test service
5. **Creates proper Traefik configuration** for SSL certificates
6. **Sets correct permissions** for certificate storage
7. **Starts minimal services** and tests them
8. **Provides status report** and next steps

## Expected Results

After running the recovery script, you should have:

- ✅ Traefik running on ports 80, 443, and 8080
- ✅ A test service (whoami) accessible via Traefik
- ✅ SSL certificate generation working
- ✅ Basic routing to `mbs-home.ddns.net`

## If Recovery Fails

If the recovery script fails:

1. **Check Docker status**: `sudo systemctl status docker`
2. **Check port conflicts**: `sudo lsof -i :80` and `sudo lsof -i :443`
3. **Check firewall**: `sudo ufw status`
4. **Check DNS**: `nslookup mbs-home.ddns.net`

## Next Steps After Recovery

Once basic recovery is working:

1. **Add Nextcloud** (most critical service)
2. **Add AdGuard Home** (DNS filtering)
3. **Add Jellyfin** (media server)
4. **Add other services one by one**

## Critical Notes

- **Work on ONE service at a time**
- **Test locally FIRST before external**
- **Don't add Authelia until everything else works**
- **Keep configuration SIMPLE initially**

## Support

If you encounter issues:

1. Run the recovery script and send me the output
2. Run the test script and send me the output
3. Include any error messages you see
4. Include your public IP: `curl ifconfig.me`

---

**🚨 CRITICAL: Start with `./emergency-recovery.sh` and report the results immediately! 🚨**