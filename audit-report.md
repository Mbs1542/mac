## Homelab System Audit and Optimization Report

Date: 2025-09-06
Branch: hotfix-service-outage

### Summary of Current Status
- **CRITICAL FIXES APPLIED**: Resolved service outages following optimization deployment
- Prometheus: Fixed merge conflict in configuration file; service now running properly
- Grafana: Added Prometheus data source provisioning; metrics collection restored
- Mail Server: Added SMTP relay service for internal container communication
- Traefik secured: insecure dashboard exposure removed; dashboard routed via HTTPS with Authelia.
- Authelia SSO: enforced across UI services via Traefik middlewares; hashing params hardened.
- Compose files: standardized labels and secrets usage; moved sensitive values to `.env`.
- Watchtower: label-gated updates enabled; notifications configured.
- Baseline health: system CPU/memory/disk within normal thresholds for homelab scale.

### Findings and Issues
- **CRITICAL**: Prometheus configuration had Git merge conflict preventing service startup
- **CRITICAL**: Grafana missing Prometheus data source configuration
- **CRITICAL**: Mail server service completely missing from compose files
- Insecure Traefik dashboard previously exposed (`--api.insecure=true` and port 8080 published).
- Missing SSO protection on multiple services in `homelab-compose.yml`.
- Hardcoded secrets detected in compose files (WireGuard, Open WebUI).
- Prometheus config duplicated jobs and Mac-specific targets.
- Grafana metrics not explicitly enabled.

### Changes Implemented
- **HOTFIX CHANGES (hotfix-service-outage branch)**:
  - `prometheus/config/prometheus.yml`: Resolved Git merge conflict; removed duplicate node-exporter job
  - `homelab-compose.yml`: Added mailserver service (SMTP relay) with Gmail integration
  - `simple-compose.yml`: Added Grafana provisioning volume mount
  - `grafana/config/provisioning/datasources/prometheus.yml`: Created Prometheus data source configuration
- `homelab-compose.yml`
  - Removed Traefik `--api.insecure=true` and hardened dashboard router with `authelia@file,secure-headers@file`.
  - Added Authelia middleware to: Traefik, Portainer, Homepage, Jellyfin, Sonarr, Radarr, Lidarr, Bazarr, Prowlarr, Transmission, Slskd, WireGuard UI, Dozzle, Open WebUI.
  - Moved `wireguard` and `open-webui` secrets to `.env` variables.
  - Enabled Watchtower label gating `WATCHTOWER_LABEL_ENABLE=true`.
- `minimal-compose.yml`
  - Fixed duplicate Prometheus metrics flag and enforced Authelia on Traefik/Homepage.
- `simple-compose.yml`
  - Ensured secrets resolved via `.env` for Grafana/Vaultwarden.
- `traefik/config/dynamic.yml`
  - Verified Authelia forwardAuth and security headers.
- `authelia/configuration.yml`
  - Hardened Argon2id parameters (iterations=3, memory=256, parallelism=4).
- `authelia/users_database.yml`
  - Added example users to guide onboarding; replace with real argon2id hashes.
- `prometheus/config/prometheus.yml`
  - Deduplicated jobs; updated docker target placeholder; kept Traefik scraping.
- `grafana/config/grafana.ini`
  - Enabled metrics section.
- `scripts/daily-report.sh`
  - Added CPU/load, directory disk usage, and formatting improvements.

### Action Plan with Commands and Snippets
- Secrets and environment
  - Create `.env` with secure values:
```bash
WG_ADMIN_PASSWORD='<random-strong>'
OPENWEBUI_SECRET_KEY='<random-strong>'
GRAFANA_ADMIN_PASSWORD='<random-strong>'
VAULTWARDEN_ADMIN_TOKEN='<random-strong>'
AUTHELIA_SESSION_SECRET='<random-strong>'
AUTHELIA_STORAGE_ENCRYPTION_KEY='<random-strong>'
AUTHELIA_JWT_SECRET='<random-strong>'
```

- Authelia user onboarding
  1) Generate a password hash:
```bash
docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password 'StrongPass'
```
  2) Add to `authelia/users_database.yml` under the desired groups.
  3) Redeploy Authelia.

- Traefik middleware usage (example label)
```yaml
labels:
  - "traefik.http.routers.service.middlewares=authelia@file,secure-headers@file"
```

- Prometheus exporters to consider
  - node-exporter, cAdvisor, Docker engine metrics at `:9323`.
  - Add scrape jobs accordingly in `prometheus.yml`.

### System Health and Monitoring
Run these to gather up-to-date health:
```bash
uptime
free -h
df -h / /workspace
```

Key metrics by service:
- Traefik: requests, 4xx/5xx, latency histograms, TLS handshake errors.
- Authelia: authentications, failures, regulation bans (via logs/exporters).
- Grafana/Prometheus: target up status, scrape durations; admin auth events.
- Media stack: CPU/memory per container; API response times where supported.
- WireGuard: peer handshakes, rx/tx bytes.

### User and Permission Management Guide
- Add a new user (file backend):
  - Generate hash, add to `users_database.yml`, assign `groups: [users]` or `admins`.
  - Example access control in `configuration.yml`:
```yaml
access_control:
  default_policy: deny
  rules:
    - domain: "*.mbs-home.ddns.net"
      policy: one_factor
      subject:
        - "group:admins"
```

### Best Practices and Recommendations
- Use one primary compose (`homelab-compose.yml`); archive others.
- Keep secrets out of Git; use `.env` and secret stores where possible.
- Apply resource limits/healthchecks consistently (already present in stack).
- Backups: keep daily rsync or volume tar with 7–30 day retention; verify restores.
- Enable alerting in Grafana/Prometheus for failures and resource saturation.

### Final Checklist
- [x] **CRITICAL**: Prometheus merge conflict resolved
- [x] **CRITICAL**: Grafana Prometheus data source configured
- [x] **CRITICAL**: Mail server service added
- [x] SSO enforced at reverse proxy
- [x] Traefik dashboard secured
- [x] Secrets via environment variables
- [x] Prometheus config deduplicated and corrected
- [x] Grafana metrics enabled
- [x] Watchtower label gating enabled
- [x] Health reporting script improved

### ⚠️ IMPORTANT: Required Action
**You must create a Google App Password and add it to your `.env` file:**
```bash
echo "GMAIL_APP_PASSWORD='<your-google-app-password>'" >> .env
```

For detailed diffs, review the Git history on this branch.

