# Deploying Flutter Web Dashboard to Raspberry Pi

This guide will help you deploy the Baby Monitor web dashboard to your Raspberry Pi 4B using the domain `mesoldseparately.org`.

## Prerequisites

- Raspberry Pi 4B (4GB RAM) with clean Raspberry Pi OS install
- Domain: `mesoldseparately.org` (DNS access required)
- Static or dynamic IP address for your home network
- Router access for port forwarding
- SSH access to your Raspberry Pi

## Overview

The deployment consists of:
1. **Flutter Web Build** - Static files served by nginx
2. **Nginx Web Server** - Serves the Flutter app and reverse proxies the API
3. **SSL/HTTPS** - Let's Encrypt certificate for secure access
4. **DNS Configuration** - Point domain to your home IP
5. **Port Forwarding** - Allow external access

## Quick Start

### Step 1: DNS Configuration

Before starting, configure your domain's DNS:

1. Log in to your domain registrar (where you registered `mesoldseparately.org`)
2. Create an **A record**:
   - **Host/Name**: `@` (or leave blank for root domain)
   - **Type**: `A`
   - **Value/Points to**: Your home's public IP address
   - **TTL**: 3600 (or Auto)

3. Optionally create a **CNAME record** for www:
   - **Host/Name**: `www`
   - **Type**: `CNAME`
   - **Value/Points to**: `mesoldseparately.org`
   - **TTL**: 3600 (or Auto)

**Find your public IP**: Visit https://whatismyipaddress.com/

**Note**: If your ISP provides a dynamic IP, consider using a Dynamic DNS service (see [Dynamic DNS Setup](#dynamic-dns-setup) below).

### Step 2: Router Port Forwarding

Configure your router to forward ports 80 and 443 to your Raspberry Pi:

1. Find your Raspberry Pi's local IP: `hostname -I`
2. Access your router's admin panel (usually http://192.168.1.1 or http://192.168.0.1)
3. Navigate to Port Forwarding / Virtual Server / NAT settings
4. Add these rules:
   - **Port 80** (HTTP) → Raspberry Pi IP:80
   - **Port 443** (HTTPS) → Raspberry Pi IP:443

**Example**:
```
External Port: 80    → Internal IP: 192.168.1.100:80 (TCP)
External Port: 443   → Internal IP: 192.168.1.100:443 (TCP)
```

### Step 3: Build Flutter Web App

On your development machine (not the Pi):

```bash
cd webapp
chmod +x deployment/build.sh
./deployment/build.sh
```

This creates `webapp/build/web/` with production-ready files.

### Step 4: Setup Raspberry Pi Server

Transfer the setup script to your Raspberry Pi:

```bash
# From your development machine
scp deployment/setup_server.sh pi@<PI_IP_ADDRESS>:~/
ssh pi@<PI_IP_ADDRESS>
```

On the Raspberry Pi:

```bash
chmod +x setup_server.sh
sudo ./setup_server.sh mesoldseparately.org
```

This script will:
- Install nginx, certbot, and dependencies
- Configure nginx with SSL
- Set up Let's Encrypt certificate
- Configure firewall rules

### Step 5: Deploy Web App

Transfer the built Flutter app to the Raspberry Pi:

```bash
# From your development machine
chmod +x deployment/deploy.sh
./deployment/deploy.sh pi@<PI_IP_ADDRESS> mesoldseparately.org
```

This will:
- Copy built files to the Pi
- Set correct permissions
- Restart nginx

### Step 6: Verify Deployment

Visit https://mesoldseparately.org in your browser. You should see the login screen.

## File Structure on Raspberry Pi

```
/var/www/mesoldseparately.org/
├── html/                    # Flutter web app files
│   ├── index.html
│   ├── flutter.js
│   ├── main.dart.js
│   └── assets/
├── logs/                    # Nginx logs
│   ├── access.log
│   └── error.log
└── ssl/                     # SSL certificates (managed by certbot)

/etc/nginx/
├── sites-available/
│   └── mesoldseparately.org
└── sites-enabled/
    └── mesoldseparately.org -> ../sites-available/mesoldseparately.org
```

## Environment Configuration

### Update API Endpoints

Before building, update `webapp/.env`:

```bash
# Production API URL
API_BASE_URL=https://mesoldseparately.org/api
WS_URL=wss://mesoldseparately.org

# Firebase configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
FIREBASE_PROJECT_ID=your_project_id
```

### Backend API Setup

If hosting the backend API on the same Raspberry Pi:

1. The nginx config includes a reverse proxy to `http://localhost:5000/api`
2. Run your Flask backend on port 5000
3. API calls to `https://mesoldseparately.org/api/...` will proxy to the backend

**Start backend**:
```bash
cd backend
docker-compose up -d
```

## SSL Certificate Renewal

Let's Encrypt certificates expire after 90 days. Auto-renewal is configured:

```bash
# Test renewal
sudo certbot renew --dry-run

# Manual renewal (if needed)
sudo certbot renew

# Renewal happens automatically via cron job
```

## Dynamic DNS Setup

If your ISP assigns dynamic IP addresses:

### Option 1: Cloudflare (Recommended)

1. Transfer `mesoldseparately.org` nameservers to Cloudflare (free)
2. Install cloudflared on Raspberry Pi:

```bash
# Install cloudflared
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64.deb
sudo dpkg -i cloudflared-linux-arm64.deb

# Setup DDNS
sudo cloudflared tunnel login
sudo cloudflared tunnel create babymonitor
sudo cloudflared tunnel route dns babymonitor mesoldseparately.org
```

3. Create tunnel config at `/etc/cloudflared/config.yml`:

```yaml
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: mesoldseparately.org
    service: https://localhost:443
  - service: http_status:404
```

4. Start tunnel:
```bash
sudo cloudflared service install
sudo systemctl start cloudflared
sudo systemctl enable cloudflared
```

### Option 2: DuckDNS (Free DDNS Service)

If you prefer a free subdomain instead:

```bash
# Install DDNS updater
mkdir -p ~/duckdns
cd ~/duckdns
echo 'echo url="https://www.duckdns.org/update?domains=YOUR_SUBDOMAIN&token=YOUR_TOKEN&ip=" | curl -k -o ~/duckdns/duck.log -K -' > duck.sh
chmod 700 duck.sh

# Add to crontab (update every 5 minutes)
crontab -e
# Add: */5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

Then use `your-subdomain.duckdns.org` instead of `mesoldseparately.org`.

## Troubleshooting

### DNS Not Resolving

```bash
# Check DNS propagation
nslookup mesoldseparately.org

# Or use online tool
# https://www.whatsmydns.net/#A/mesoldseparately.org

# DNS can take 24-48 hours to propagate fully
```

### SSL Certificate Error

```bash
# Check nginx config
sudo nginx -t

# View nginx logs
sudo tail -f /var/log/nginx/error.log

# Retry certificate
sudo certbot --nginx -d mesoldseparately.org -d www.mesoldseparately.org
```

### Cannot Access from Internet

1. **Check port forwarding**:
   ```bash
   # From outside your network
   telnet mesoldseparately.org 80
   telnet mesoldseparately.org 443
   ```

2. **Check firewall**:
   ```bash
   sudo ufw status
   # Should show 80/tcp and 443/tcp as ALLOW
   ```

3. **Check nginx**:
   ```bash
   sudo systemctl status nginx
   sudo nginx -t
   ```

### Site Loads but API Calls Fail

1. Check backend is running:
   ```bash
   curl http://localhost:5000/health
   ```

2. Check nginx proxy config:
   ```bash
   sudo nano /etc/nginx/sites-available/mesoldseparately.org
   # Verify proxy_pass directives
   ```

3. View nginx error logs:
   ```bash
   sudo tail -f /var/log/nginx/error.log
   ```

## Updating the Dashboard

To deploy updates:

```bash
# 1. Build new version
cd webapp
./deployment/build.sh

# 2. Deploy to Pi
./deployment/deploy.sh pi@<PI_IP_ADDRESS> mesoldseparately.org
```

## Performance Optimization

### Enable Gzip Compression

Already configured in nginx for:
- HTML, CSS, JavaScript
- JSON, XML
- Fonts and SVG

### Enable Caching

Static assets are cached for 1 year. To clear cache, rebuild with new version.

### Monitor Resource Usage

```bash
# CPU/Memory usage
htop

# Nginx connections
sudo ss -tulpn | grep nginx

# Disk usage
df -h
```

## Security Considerations

1. **Firewall**: Only ports 22 (SSH), 80 (HTTP), 443 (HTTPS) are open
2. **SSL**: TLS 1.2+ only, strong ciphers configured
3. **Headers**: Security headers configured (HSTS, X-Frame-Options, etc.)
4. **Updates**: Keep Raspberry Pi OS and packages updated:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

## Backup

### Backup Web Files

```bash
# On Raspberry Pi
sudo tar -czf ~/backup-webapp-$(date +%Y%m%d).tar.gz /var/www/mesoldseparately.org/html
```

### Backup nginx Config

```bash
sudo tar -czf ~/backup-nginx-$(date +%Y%m%d).tar.gz /etc/nginx
```

## Advanced: Custom Domain for Backend

If you want separate domains for frontend and backend:

1. Create another A record: `api.mesoldseparately.org` → Your IP
2. Update `.env`: `API_BASE_URL=https://api.mesoldseparately.org`
3. Modify nginx config to serve API on subdomain
4. Request SSL cert: `sudo certbot --nginx -d api.mesoldseparately.org`

## Getting Help

- Check logs: `sudo tail -f /var/log/nginx/error.log`
- Test nginx config: `sudo nginx -t`
- Check SSL: https://www.ssllabs.com/ssltest/analyze.html?d=mesoldseparately.org
- DNS check: https://www.whatsmydns.net/
