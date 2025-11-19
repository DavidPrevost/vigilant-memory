#!/bin/bash
set -e

# Raspberry Pi Web Server Setup Script
# Sets up nginx, SSL, and firewall for hosting Flutter web app

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (use sudo)${NC}"
    exit 1
fi

# Check domain argument
if [ -z "$1" ]; then
    echo -e "${RED}❌ Usage: sudo $0 <domain>${NC}"
    echo "Example: sudo $0 mesoldseparately.org"
    exit 1
fi

DOMAIN=$1
EMAIL="admin@${DOMAIN}"  # Email for Let's Encrypt

echo -e "${GREEN}🚀 Setting up web server for ${DOMAIN}${NC}"
echo "=========================================="

# Update system
echo ""
echo -e "${YELLOW}📦 Updating system packages...${NC}"
apt update
apt upgrade -y

# Install required packages
echo ""
echo -e "${YELLOW}📥 Installing nginx, certbot, and dependencies...${NC}"
apt install -y \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    curl \
    wget

# Configure firewall
echo ""
echo -e "${YELLOW}🔒 Configuring firewall...${NC}"
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw status

# Create web directory
echo ""
echo -e "${YELLOW}📁 Creating web directory structure...${NC}"
WEB_ROOT="/var/www/${DOMAIN}"
mkdir -p ${WEB_ROOT}/{html,logs}

# Create placeholder index.html
cat > ${WEB_ROOT}/html/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Baby Monitor - Setup In Progress</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            backdrop-filter: blur(10px);
        }
        h1 { font-size: 2.5rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🍼 Baby Monitor</h1>
        <p>Server setup in progress...</p>
        <p>Deploy your Flutter app to complete setup</p>
    </div>
</body>
</html>
EOF

# Set permissions
chown -R www-data:www-data ${WEB_ROOT}
chmod -R 755 ${WEB_ROOT}

# Create nginx configuration
echo ""
echo -e "${YELLOW}⚙️  Creating nginx configuration...${NC}"

cat > /etc/nginx/sites-available/${DOMAIN} <<'NGINXCONF'
# Baby Monitor Web App - Nginx Configuration
# Domain: DOMAIN_PLACEHOLDER

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;

    # ACME challenge for Let's Encrypt
    location /.well-known/acme-challenge/ {
        root /var/www/DOMAIN_PLACEHOLDER/html;
    }

    # Redirect all other requests to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name DOMAIN_PLACEHOLDER www.DOMAIN_PLACEHOLDER;

    # SSL Configuration (will be managed by Certbot)
    # ssl_certificate managed by certbot
    # ssl_certificate_key managed by certbot

    # SSL Security Settings
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Document root
    root /var/www/DOMAIN_PLACEHOLDER/html;
    index index.html;

    # Access and error logs
    access_log /var/www/DOMAIN_PLACEHOLDER/logs/access.log;
    error_log /var/www/DOMAIN_PLACEHOLDER/logs/error.log;

    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/javascript
        application/json
        application/xml+rss
        application/rss+xml
        application/atom+xml
        image/svg+xml
        font/truetype
        font/opentype
        application/font-woff
        application/font-woff2;

    # Flutter web app
    location / {
        try_files $uri $uri/ /index.html;

        # Cache control for static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }

        # Don't cache index.html
        location = /index.html {
            add_header Cache-Control "no-cache, no-store, must-revalidate";
            add_header Pragma "no-cache";
            add_header Expires "0";
        }
    }

    # Backend API proxy (if backend runs on same server)
    location /api/ {
        proxy_pass http://localhost:5000/api/;
        proxy_http_version 1.1;

        # Proxy headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket endpoint
    location /socket.io/ {
        proxy_pass http://localhost:5000/socket.io/;
        proxy_http_version 1.1;

        # WebSocket headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "OK\n";
        add_header Content-Type text/plain;
    }
}
NGINXCONF

# Replace domain placeholder
sed -i "s/DOMAIN_PLACEHOLDER/${DOMAIN}/g" /etc/nginx/sites-available/${DOMAIN}

# Enable site
ln -sf /etc/nginx/sites-available/${DOMAIN} /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
echo ""
echo -e "${YELLOW}🧪 Testing nginx configuration...${NC}"
nginx -t

# Restart nginx
echo ""
echo -e "${YELLOW}🔄 Starting nginx...${NC}"
systemctl restart nginx
systemctl enable nginx

# Wait for nginx to start
sleep 2

# Check if domain resolves
echo ""
echo -e "${YELLOW}🌐 Checking DNS resolution...${NC}"
if host ${DOMAIN} > /dev/null 2>&1; then
    echo -e "${GREEN}✅ DNS resolves for ${DOMAIN}${NC}"
    DNS_READY=true
else
    echo -e "${YELLOW}⚠️  DNS does not resolve yet for ${DOMAIN}${NC}"
    echo "You need to:"
    echo "  1. Set up an A record pointing ${DOMAIN} to your public IP"
    echo "  2. Wait for DNS propagation (can take up to 48 hours)"
    echo "  3. Run: sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
    DNS_READY=false
fi

# Setup SSL with Let's Encrypt if DNS is ready
if [ "$DNS_READY" = true ]; then
    echo ""
    echo -e "${YELLOW}🔐 Setting up SSL certificate with Let's Encrypt...${NC}"

    # Stop nginx temporarily for standalone mode
    systemctl stop nginx

    # Get certificate (standalone mode is more reliable for first-time setup)
    certbot certonly --standalone \
        --non-interactive \
        --agree-tos \
        --email ${EMAIL} \
        -d ${DOMAIN} \
        -d www.${DOMAIN} \
        --pre-hook "systemctl stop nginx" \
        --post-hook "systemctl start nginx"

    # Update nginx config with SSL
    certbot install --nginx \
        --non-interactive \
        --cert-name ${DOMAIN}

    # Start nginx
    systemctl start nginx

    # Setup auto-renewal
    echo ""
    echo -e "${YELLOW}⏰ Setting up automatic SSL renewal...${NC}"

    # Test renewal
    certbot renew --dry-run

    # Certbot installs a systemd timer automatically, verify it
    systemctl list-timers | grep certbot

    echo -e "${GREEN}✅ SSL certificate installed and auto-renewal configured${NC}"
else
    echo ""
    echo -e "${YELLOW}⏭️  Skipping SSL setup (DNS not ready)${NC}"
    echo "After DNS propagates, run:"
    echo "  sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
fi

# Display server info
echo ""
echo -e "${GREEN}=========================================="
echo "✅ Server Setup Complete!"
echo "==========================================${NC}"
echo ""
echo "📋 Server Information:"
echo "   Domain: ${DOMAIN}"
echo "   Web Root: ${WEB_ROOT}/html"
echo "   Logs: ${WEB_ROOT}/logs"
echo "   Nginx Config: /etc/nginx/sites-available/${DOMAIN}"
echo ""
echo "🔗 URLs:"
if [ "$DNS_READY" = true ]; then
    echo "   https://${DOMAIN}"
    echo "   https://www.${DOMAIN}"
else
    echo "   http://$(hostname -I | awk '{print $1}') (local only)"
fi
echo ""
echo "📝 Next Steps:"
echo "   1. Deploy Flutter app: ./deployment/deploy.sh pi@<IP> ${DOMAIN}"
if [ "$DNS_READY" = false ]; then
    echo "   2. Configure DNS A record to point to your public IP"
    echo "   3. Setup port forwarding: 80→80, 443→443"
    echo "   4. Run: sudo certbot --nginx -d ${DOMAIN} -d www.${DOMAIN}"
fi
echo ""
echo "🔧 Useful Commands:"
echo "   Check nginx: sudo systemctl status nginx"
echo "   View logs: sudo tail -f ${WEB_ROOT}/logs/error.log"
echo "   Test config: sudo nginx -t"
echo "   Renew SSL: sudo certbot renew"
echo ""
