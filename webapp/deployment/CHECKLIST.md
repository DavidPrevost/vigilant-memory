# Deployment Checklist

Use this checklist to ensure all steps are completed for deploying to `mesoldseparately.org`.

## Pre-Deployment Setup

### DNS Configuration
- [ ] Found public IP address (https://whatismyipaddress.com/)
- [ ] Logged into domain registrar for `mesoldseparately.org`
- [ ] Created A record: `@` → `YOUR_PUBLIC_IP`
- [ ] Created CNAME record: `www` → `mesoldseparately.org`
- [ ] Waited for DNS propagation (5-60 minutes)
- [ ] Verified DNS works: `nslookup mesoldseparately.org`

### Router Configuration
- [ ] Found Raspberry Pi local IP: `hostname -I`
- [ ] Logged into router admin panel
- [ ] Forwarded port 80 → Raspberry Pi IP:80
- [ ] Forwarded port 443 → Raspberry Pi IP:443
- [ ] Tested port forwarding (https://www.yougetsignal.com/tools/open-ports/)

### Raspberry Pi Preparation
- [ ] Raspberry Pi 4B is running
- [ ] Clean Raspberry Pi OS installed
- [ ] SSH is enabled
- [ ] Can SSH into Pi: `ssh pi@YOUR_PI_IP`
- [ ] Pi is connected to network
- [ ] Pi has static IP (or DHCP reservation)

## Server Setup (On Raspberry Pi)

- [ ] Transferred `setup_server.sh` to Pi
- [ ] Made script executable: `chmod +x setup_server.sh`
- [ ] Ran setup script: `sudo ./setup_server.sh mesoldseparately.org`
- [ ] Setup completed without errors
- [ ] nginx is running: `sudo systemctl status nginx`
- [ ] Firewall is active: `sudo ufw status`
- [ ] SSL certificate obtained (if DNS was ready)

## Application Configuration (Development Machine)

- [ ] Updated `webapp/.env` with production URLs:
  ```
  API_BASE_URL=https://mesoldseparately.org/api
  WS_URL=wss://mesoldseparately.org
  ```
- [ ] Added Firebase credentials to `.env`
- [ ] Verified all environment variables are set

## Build & Deploy

- [ ] Made build script executable: `chmod +x deployment/build.sh`
- [ ] Built Flutter app: `./deployment/build.sh`
- [ ] Build completed successfully
- [ ] `build/web/` directory exists and contains files
- [ ] Made deploy script executable: `chmod +x deployment/deploy.sh`
- [ ] Deployed to server: `./deployment/deploy.sh pi@YOUR_PI_IP mesoldseparately.org`
- [ ] Deployment completed without errors

## Verification

- [ ] Opened https://mesoldseparately.org in browser
- [ ] Site loads without errors
- [ ] SSL certificate is valid (green padlock)
- [ ] Login screen appears
- [ ] No console errors (F12 → Console)
- [ ] Responsive design works (test mobile view)

## Backend Integration (If Applicable)

- [ ] Backend API is running on Pi
- [ ] Backend is accessible: `curl http://localhost:5000/health`
- [ ] nginx reverse proxy is configured
- [ ] API calls from frontend work
- [ ] WebSocket connection works

## Security

- [ ] Only necessary ports are open (22, 80, 443)
- [ ] SSL/HTTPS is working
- [ ] HTTP redirects to HTTPS
- [ ] Security headers are set (check developer tools)
- [ ] Firewall is enabled: `sudo ufw status`

## Monitoring & Maintenance

- [ ] Know how to view logs: `sudo tail -f /var/log/nginx/error.log`
- [ ] SSL auto-renewal is configured (certbot timer)
- [ ] Created first backup: `sudo tar -czf ~/backup.tar.gz /var/www/mesoldseparately.org`
- [ ] Documented server IP and credentials securely
- [ ] Know how to redeploy updates
- [ ] Set up monitoring/alerts (optional)

## Optional Enhancements

- [ ] Set up dynamic DNS (if using dynamic IP)
- [ ] Configure email notifications
- [ ] Set up automated backups
- [ ] Configure CDN (Cloudflare)
- [ ] Set up monitoring (UptimeRobot, etc.)
- [ ] Configure log rotation
- [ ] Set up fail2ban for SSH protection

## Troubleshooting Reference

If something goes wrong:

**DNS Issues:**
```bash
nslookup mesoldseparately.org
dig mesoldseparately.org
```

**nginx Issues:**
```bash
sudo systemctl status nginx
sudo nginx -t
sudo tail -f /var/log/nginx/error.log
```

**SSL Issues:**
```bash
sudo certbot certificates
sudo certbot renew --dry-run
```

**Firewall Issues:**
```bash
sudo ufw status verbose
sudo ufw allow 'Nginx Full'
```

**Deployment Issues:**
```bash
# View last backup
ls -lh /tmp/backup-*.tar.gz

# Rollback
cd /var/www/mesoldseparately.org/html
sudo tar -xzf /tmp/backup-LATEST.tar.gz
sudo systemctl restart nginx
```

## Post-Deployment

- [ ] Shared URL with team/users
- [ ] Documented any customizations
- [ ] Scheduled regular updates
- [ ] Set calendar reminder for manual SSL check (90 days)
- [ ] Created maintenance plan

---

## Notes

Use this space for notes, IP addresses, or customizations:

```
Public IP: _________________
Pi Local IP: _________________
Router Login: _________________
Domain Registrar: _________________

Custom changes:
-
-
-

```

---

**Date Completed:** _______________

**Deployed By:** _______________

**Next Review:** _______________
