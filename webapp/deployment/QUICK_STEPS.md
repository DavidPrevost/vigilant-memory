# Quick Deployment Steps

Follow these steps in order. **Bold** = where you run the command.

## Initial Setup (Do Once)

### 1. Setup Raspberry Pi
**On Pi (via SSH):**
```bash
# Update and install packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx git ufw

# Setup firewall
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# Clone repository
cd ~
git clone https://github.com/YOUR_USERNAME/vigilant-memory.git
cd vigilant-memory
```

### 2. Configure nginx
**On Pi:**
```bash
# Choose your domain
DOMAIN="app.mesoldseparately.org"

# Create web directory
sudo mkdir -p /var/www/${DOMAIN}/html

# Download nginx config
sudo curl -o /etc/nginx/sites-available/${DOMAIN} \
  https://raw.githubusercontent.com/YOUR_USERNAME/vigilant-memory/main/webapp/deployment/nginx.conf

# Edit the config to replace domain
sudo sed -i "s/app.mesoldseparately.org/${DOMAIN}/g" /etc/nginx/sites-available/${DOMAIN}

# Enable site
sudo ln -s /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

### 3. Setup Port Forwarding
**On your router:**
- Port 80 → Pi IP (port 80)
- Port 443 → Pi IP (port 443)

---

## Deploy App (Do Every Time You Update)

### 1. Build on Your Computer
**On your computer:**
```bash
cd webapp
flutter build web --release
git add build/web
git commit -m "Build app"
git push
```

### 2. Deploy on Pi
**On Pi:**
```bash
cd ~/vigilant-memory
git pull
chmod +x webapp/deployment/deploy_from_pi.sh
./webapp/deployment/deploy_from_pi.sh app.mesoldseparately.org
```

### 3. Test
Open: https://app.mesoldseparately.org

---

## Setup SSL (Do Once After DNS Works)

**On Pi:**
```bash
sudo certbot --nginx -d app.mesoldseparately.org
```

Follow prompts, choose redirect HTTP → HTTPS.

---

## Useful Commands

**Check status:**
```bash
sudo systemctl status nginx
sudo nginx -t
```

**View logs:**
```bash
sudo tail -f /var/log/nginx/error.log
```

**Restart nginx:**
```bash
sudo systemctl restart nginx
```

---

## Troubleshooting

**Site not loading?**
```bash
# Check DNS
nslookup app.mesoldseparately.org

# Check nginx
sudo systemctl status nginx

# Check firewall
sudo ufw status
```

**SSL not working?**
```bash
# Make sure DNS works first, then:
sudo certbot --nginx -d app.mesoldseparately.org
```
