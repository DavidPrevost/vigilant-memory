# Quick Start Guide - Deploy to Raspberry Pi

This is a condensed guide for deploying the Baby Monitor dashboard to your Raspberry Pi using `mesoldseparately.org`.

## 1. Configure DNS (Do This First!)

Go to your domain registrar where you registered `mesoldseparately.org`:

1. **Find your public IP**: Visit https://whatismyipaddress.com/
2. **Create A Record**:
   ```
   Type: A
   Host: @ (or blank)
   Value: YOUR_PUBLIC_IP
   TTL: 3600
   ```
3. **Create CNAME** (optional for www):
   ```
   Type: CNAME
   Host: www
   Value: mesoldseparately.org
   TTL: 3600
   ```

**Wait 5-60 minutes** for DNS to propagate. Check with: `nslookup mesoldseparately.org`

## 2. Configure Router Port Forwarding

Access your router's admin panel and forward these ports to your Raspberry Pi:

```
Port 80 (HTTP)  → Raspberry Pi IP:80
Port 443 (HTTPS) → Raspberry Pi IP:443
```

Find your Pi's IP: `hostname -I` (on the Pi)

## 3. Setup Raspberry Pi Server

**On your Raspberry Pi:**

```bash
# Transfer setup script to Pi
# (Run this from your development machine)
scp webapp/deployment/setup_server.sh pi@YOUR_PI_IP:~/

# SSH into Pi
ssh pi@YOUR_PI_IP

# Run setup
chmod +x setup_server.sh
sudo ./setup_server.sh mesoldseparately.org
```

This installs nginx, configures SSL, and sets up the server.

## 4. Build Flutter App

**On your development machine:**

```bash
cd webapp
chmod +x deployment/build.sh
./deployment/build.sh
```

## 5. Deploy to Server

**From your development machine:**

```bash
cd webapp
chmod +x deployment/deploy.sh
./deployment/deploy.sh pi@YOUR_PI_IP mesoldseparately.org
```

## 6. Visit Your Site

Open https://mesoldseparately.org in your browser!

---

## Common Commands

### Redeploy After Changes

```bash
cd webapp
./deployment/build.sh
./deployment/deploy.sh pi@YOUR_PI_IP mesoldseparately.org
```

### View Logs on Pi

```bash
# Nginx errors
sudo tail -f /var/log/nginx/error.log

# Access logs
sudo tail -f /var/www/mesoldseparately.org/logs/access.log
```

### Restart nginx

```bash
sudo systemctl restart nginx
```

### Check SSL Certificate

```bash
sudo certbot certificates
```

### Renew SSL Certificate

```bash
sudo certbot renew
```

---

## Troubleshooting

### "Site not loading"
- Check DNS: `nslookup mesoldseparately.org`
- Check port forwarding in router
- Check nginx: `sudo systemctl status nginx`

### "SSL Certificate Error"
- Verify DNS is working first
- Run: `sudo certbot --nginx -d mesoldseparately.org -d www.mesoldseparately.org`

### "API calls failing"
- Check backend is running: `curl http://localhost:5000/health`
- Check nginx proxy config: `sudo nginx -t`

---

## File Locations

| What | Where |
|------|-------|
| Web files | `/var/www/mesoldseparately.org/html/` |
| Nginx config | `/etc/nginx/sites-available/mesoldseparately.org` |
| Logs | `/var/www/mesoldseparately.org/logs/` |
| SSL certs | `/etc/letsencrypt/live/mesoldseparately.org/` |

---

## Emergency Rollback

If deployment breaks something:

```bash
# SSH to Pi
ssh pi@YOUR_PI_IP

# Find backup
ls -lh /tmp/backup-*.tar.gz

# Restore from backup
cd /var/www/mesoldseparately.org/html
sudo tar -xzf /tmp/backup-YYYYMMDD-HHMMSS.tar.gz

# Restart nginx
sudo systemctl restart nginx
```
