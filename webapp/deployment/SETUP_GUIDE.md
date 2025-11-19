# Baby Monitor Deployment Guide - Simple Step-by-Step

This guide will help you deploy the Baby Monitor dashboard to your Raspberry Pi using Git.

## What You Have So Far

✅ DNS configured on Squarespace:
- @ record → Your IP
- app record → Your IP

## What We'll Do

1. Setup your Raspberry Pi as a web server
2. Clone this repo to the Pi
3. Build the Flutter app (on your computer)
4. Deploy to the Pi using Git
5. Setup SSL certificate

---

## PART 1: Setup Raspberry Pi Server

**Where:** SSH into your Raspberry Pi

```bash
# SSH to your Pi
ssh pi@YOUR_PI_IP

# Update system
sudo apt update
sudo apt upgrade -y

# Install nginx (web server)
sudo apt install -y nginx

# Install certbot (for SSL certificates)
sudo apt install -y certbot python3-certbot-nginx

# Install Git (if not already installed)
sudo apt install -y git

# Enable and start nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# Setup firewall
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

**Verify nginx is running:**
```bash
sudo systemctl status nginx
# Should show "active (running)"
```

---

## PART 2: Clone Repository on Pi

**Where:** Still on the Raspberry Pi (via SSH)

```bash
# Go to home directory
cd ~

# Clone the repository
git clone https://github.com/YOUR_USERNAME/vigilant-memory.git

# (Or if already cloned, just pull latest)
cd ~/vigilant-memory
git pull
```

---

## PART 3: Configure nginx

**Where:** Still on the Raspberry Pi

**Which domain?** Choose one:
- `mesoldseparately.org` (root domain)
- `app.mesoldseparately.org` (subdomain)

I recommend `app.mesoldseparately.org` - replace `DOMAIN` below with your choice.

```bash
# Set your domain (choose one)
DOMAIN="app.mesoldseparately.org"
# OR
DOMAIN="mesoldseparately.org"

# Create web directory
sudo mkdir -p /var/www/${DOMAIN}/html

# Create nginx config file
sudo nano /etc/nginx/sites-available/${DOMAIN}
```

**Paste this configuration** (replace `app.mesoldseparately.org` if using different domain):

```nginx
# HTTP - Redirect to HTTPS (after SSL is setup)
server {
    listen 80;
    listen [::]:80;
    server_name app.mesoldseparately.org;

    # For now, serve the site
    # After SSL is setup, this will redirect to HTTPS

    root /var/www/app.mesoldseparately.org/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    # Backend API proxy
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # WebSocket support
    location /socket.io/ {
        proxy_pass http://localhost:5000/socket.io/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

**Save and exit:** Press `Ctrl+X`, then `Y`, then `Enter`

**Enable the site:**
```bash
# Create symbolic link
sudo ln -s /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/

# Remove default site
sudo rm -f /etc/nginx/sites-enabled/default

# Test configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

---

## PART 4: Build Flutter App

**Where:** On your **LOCAL COMPUTER** (not the Pi)

```bash
# Navigate to webapp directory
cd /path/to/vigilant-memory/webapp

# Update .env file with production URLs
cat > .env << 'EOF'
API_BASE_URL=https://app.mesoldseparately.org/api
WS_URL=wss://app.mesoldseparately.org

# Add your Firebase config
FIREBASE_API_KEY=your_key_here
FIREBASE_AUTH_DOMAIN=your_domain_here
FIREBASE_PROJECT_ID=your_project_here
FIREBASE_APP_ID=your_app_id_here
EOF

# Build the Flutter web app
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release

# Commit the build output
git add build/web
git commit -m "Build web app for production"
git push
```

**Note:** Normally you don't commit build files, but for simple Git-based deployment, this works.

---

## PART 5: Deploy to Raspberry Pi

**Where:** Back on your **Raspberry Pi** (via SSH)

```bash
# Navigate to repo
cd ~/vigilant-memory

# Pull the latest changes (includes build)
git pull

# Copy built files to web directory
sudo rm -rf /var/www/${DOMAIN}/html/*
sudo cp -r webapp/build/web/* /var/www/${DOMAIN}/html/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/${DOMAIN}
sudo chmod -R 755 /var/www/${DOMAIN}

# Reload nginx
sudo systemctl reload nginx
```

**Test it:**
```bash
# From the Pi, test locally
curl http://localhost

# Should show HTML output
```

---

## PART 6: Setup SSL Certificate

**Where:** On your **Raspberry Pi**

**Important:** Wait until DNS is fully propagated (test with `nslookup app.mesoldseparately.org`)

```bash
# Set your domain
DOMAIN="app.mesoldseparately.org"

# Get SSL certificate
sudo certbot --nginx -d ${DOMAIN}
```

**Follow the prompts:**
- Enter email address
- Agree to terms: `Y`
- Share email: `N` (optional)
- Redirect HTTP to HTTPS: `2` (Yes, redirect)

**Certbot will:**
- Get a free SSL certificate from Let's Encrypt
- Automatically update your nginx config
- Setup auto-renewal

**Verify auto-renewal:**
```bash
sudo certbot renew --dry-run
```

---

## PART 7: Router Port Forwarding

**Where:** Your router's admin interface

You need to forward these ports from your router to your Raspberry Pi:

1. **Find your Pi's local IP:**
   ```bash
   # On the Pi
   hostname -I
   # Example output: 192.168.1.100
   ```

2. **Access your router:**
   - Usually http://192.168.1.1 or http://192.168.0.1
   - Login with router admin credentials

3. **Find Port Forwarding settings:**
   - Look for: "Port Forwarding", "Virtual Server", "NAT", or "Applications"

4. **Add these rules:**
   ```
   Service Name: HTTP
   External Port: 80
   Internal IP: 192.168.1.100 (your Pi's IP)
   Internal Port: 80
   Protocol: TCP

   Service Name: HTTPS
   External Port: 443
   Internal IP: 192.168.1.100
   Internal Port: 443
   Protocol: TCP
   ```

5. **Save and apply**

---

## PART 8: Test Your Site

**From any device (not on your home network):**

1. Open browser
2. Go to: `https://app.mesoldseparately.org`
3. You should see the Baby Monitor login screen!

**If it doesn't work:**

Check DNS:
```bash
nslookup app.mesoldseparately.org
# Should show your public IP
```

Check from your phone (disconnect from WiFi, use cellular):
```
https://app.mesoldseparately.org
```

---

## Future Updates

When you make changes to the app:

**On your computer:**
```bash
cd webapp
flutter build web --release
git add build/web
git commit -m "Update app"
git push
```

**On Raspberry Pi:**
```bash
cd ~/vigilant-memory
git pull
sudo cp -r webapp/build/web/* /var/www/${DOMAIN}/html/
sudo systemctl reload nginx
```

---

## Quick Reference Commands

**On Raspberry Pi:**

```bash
# View nginx logs
sudo tail -f /var/log/nginx/error.log

# Check nginx status
sudo systemctl status nginx

# Test nginx config
sudo nginx -t

# Reload nginx (after config changes)
sudo systemctl reload nginx

# Restart nginx (if needed)
sudo systemctl restart nginx

# Check SSL certificate
sudo certbot certificates

# Renew SSL (happens automatically, but you can force it)
sudo certbot renew
```

---

## Troubleshooting

### "Site not loading"
1. Check DNS: `nslookup app.mesoldseparately.org`
2. Check nginx: `sudo systemctl status nginx`
3. Check firewall: `sudo ufw status`
4. Check port forwarding on router

### "SSL not working"
1. Make sure DNS is propagated first
2. Run: `sudo certbot --nginx -d app.mesoldseparately.org`
3. Check: `sudo certbot certificates`

### "Can't connect from outside"
1. Verify port forwarding on router
2. Test ports: https://www.yougetsignal.com/tools/open-ports/
3. Check your public IP: https://whatismyipaddress.com/

### "API calls failing"
1. Make sure backend is running: `curl http://localhost:5000/health`
2. Check nginx proxy config: `sudo nano /etc/nginx/sites-available/${DOMAIN}`
3. Check logs: `sudo tail -f /var/log/nginx/error.log`

---

## Summary of What's Where

**Your Computer:**
- Source code
- Build Flutter app
- Commit and push to Git

**Raspberry Pi:**
- Clone Git repository
- nginx web server
- SSL certificates
- Deployed website at `/var/www/${DOMAIN}/html`

**Squarespace:**
- DNS records point domain to your home IP

**Your Router:**
- Port forwarding sends traffic to Raspberry Pi

**Flow:**
```
Internet → Your Public IP → Router (port forward) → Raspberry Pi (nginx) → Website
```
