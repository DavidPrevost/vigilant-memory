#!/bin/bash
# Deploy script - Run this ON the Raspberry Pi after git pull

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}🚀 Deploying Baby Monitor Dashboard${NC}"
echo "======================================"

# Get domain from argument or use default
DOMAIN=${1:-"app.mesoldseparately.org"}

echo "Domain: ${DOMAIN}"
echo ""

# Check if running on Pi
if [ ! -f "webapp/build/web/index.html" ]; then
    echo -e "${YELLOW}⚠️  Build files not found!${NC}"
    echo "Expected: webapp/build/web/index.html"
    echo ""
    echo "Did you:"
    echo "  1. Build the app on your computer: flutter build web --release"
    echo "  2. Commit and push: git add build/web && git commit -m 'Build' && git push"
    echo "  3. Pull on Pi: git pull"
    exit 1
fi

# Check if web directory exists
if [ ! -d "/var/www/${DOMAIN}" ]; then
    echo -e "${YELLOW}📁 Creating web directory...${NC}"
    sudo mkdir -p /var/www/${DOMAIN}/html
fi

# Backup existing deployment
if [ -d "/var/www/${DOMAIN}/html" ] && [ "$(ls -A /var/www/${DOMAIN}/html)" ]; then
    BACKUP="/tmp/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo -e "${YELLOW}💾 Creating backup: ${BACKUP}${NC}"
    sudo tar -czf ${BACKUP} -C /var/www/${DOMAIN}/html . 2>/dev/null || true
fi

# Deploy files
echo -e "${YELLOW}📦 Copying files to web root...${NC}"
sudo rm -rf /var/www/${DOMAIN}/html/*
sudo cp -r webapp/build/web/* /var/www/${DOMAIN}/html/

# Set permissions
echo -e "${YELLOW}🔧 Setting permissions...${NC}"
sudo chown -R www-data:www-data /var/www/${DOMAIN}
sudo chmod -R 755 /var/www/${DOMAIN}

# Test nginx config
echo -e "${YELLOW}🧪 Testing nginx configuration...${NC}"
sudo nginx -t

# Reload nginx
echo -e "${YELLOW}🔄 Reloading nginx...${NC}"
sudo systemctl reload nginx

# Verify
echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo "🔗 Your site: https://${DOMAIN}"
echo ""
echo "To test locally on the Pi:"
echo "  curl http://localhost"
echo ""
echo "To view logs:"
echo "  sudo tail -f /var/log/nginx/error.log"
echo ""
if [ -n "${BACKUP}" ]; then
    echo "💾 Backup saved: ${BACKUP}"
    echo "To rollback:"
    echo "  sudo rm -rf /var/www/${DOMAIN}/html/*"
    echo "  sudo tar -xzf ${BACKUP} -C /var/www/${DOMAIN}/html/"
    echo "  sudo systemctl reload nginx"
    echo ""
fi
