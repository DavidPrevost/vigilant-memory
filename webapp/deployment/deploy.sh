#!/bin/bash
set -e

# Flutter Web Deployment Script
# Deploys built Flutter app to Raspberry Pi server

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}❌ Usage: $0 <user@host> <domain>${NC}"
    echo "Example: $0 pi@192.168.1.100 mesoldseparately.org"
    exit 1
fi

SERVER=$1
DOMAIN=$2
WEB_ROOT="/var/www/${DOMAIN}/html"

echo -e "${GREEN}🚀 Deploying Flutter Web App${NC}"
echo "=========================================="
echo "Server: ${SERVER}"
echo "Domain: ${DOMAIN}"
echo ""

# Check if build exists
if [ ! -d "build/web" ]; then
    echo -e "${RED}❌ Error: build/web directory not found${NC}"
    echo "Run ./deployment/build.sh first"
    exit 1
fi

# Verify build has required files
if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}❌ Error: build/web/index.html not found${NC}"
    echo "Run ./deployment/build.sh first"
    exit 1
fi

# Test SSH connection
echo -e "${YELLOW}🔌 Testing SSH connection...${NC}"
if ! ssh -o ConnectTimeout=5 ${SERVER} "echo 'Connection successful'" > /dev/null 2>&1; then
    echo -e "${RED}❌ Cannot connect to ${SERVER}${NC}"
    echo "Check:"
    echo "  1. Server is running"
    echo "  2. SSH is enabled"
    echo "  3. Correct user@host format"
    echo "  4. SSH keys are configured (or use password)"
    exit 1
fi
echo -e "${GREEN}✅ SSH connection successful${NC}"

# Check if web root exists on server
echo ""
echo -e "${YELLOW}📁 Checking web directory...${NC}"
if ! ssh ${SERVER} "sudo test -d ${WEB_ROOT}"; then
    echo -e "${RED}❌ Web directory ${WEB_ROOT} does not exist on server${NC}"
    echo "Run setup_server.sh on the server first:"
    echo "  sudo ./setup_server.sh ${DOMAIN}"
    exit 1
fi
echo -e "${GREEN}✅ Web directory exists${NC}"

# Create backup of current deployment
echo ""
echo -e "${YELLOW}💾 Creating backup of current deployment...${NC}"
BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S).tar.gz"
ssh ${SERVER} "sudo tar -czf /tmp/${BACKUP_NAME} -C ${WEB_ROOT} . 2>/dev/null || echo 'No previous deployment to backup'"
echo -e "${GREEN}✅ Backup created: /tmp/${BACKUP_NAME}${NC}"

# Create temporary directory for upload
TEMP_DIR="/tmp/flutter-deploy-$(date +%s)"
echo ""
echo -e "${YELLOW}📤 Uploading files...${NC}"

# Copy files to server
rsync -avz --progress \
    --exclude='.git' \
    --exclude='*.map' \
    build/web/ ${SERVER}:${TEMP_DIR}/

echo -e "${GREEN}✅ Files uploaded${NC}"

# Move files to web root and set permissions
echo ""
echo -e "${YELLOW}🔧 Installing files...${NC}"

ssh ${SERVER} << ENDSSH
set -e

# Remove old files (except .well-known for Let's Encrypt)
sudo find ${WEB_ROOT} -mindepth 1 ! -path "${WEB_ROOT}/.well-known*" -delete

# Move new files
sudo mv ${TEMP_DIR}/* ${WEB_ROOT}/

# Set ownership and permissions
sudo chown -R www-data:www-data ${WEB_ROOT}
sudo chmod -R 755 ${WEB_ROOT}

# Clean up temp directory
rm -rf ${TEMP_DIR}

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

echo "✅ Deployment complete"
ENDSSH

# Verify deployment
echo ""
echo -e "${YELLOW}🧪 Verifying deployment...${NC}"

# Check if index.html is accessible
HTTP_CODE=$(ssh ${SERVER} "curl -s -o /dev/null -w '%{http_code}' http://localhost/" || echo "000")

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ Web server responding (HTTP ${HTTP_CODE})${NC}"
else
    echo -e "${YELLOW}⚠️  Web server response: HTTP ${HTTP_CODE}${NC}"
fi

# Get deployment info
BUILD_SIZE=$(du -sh build/web | cut -f1)
FILE_COUNT=$(find build/web -type f | wc -l)

# Display summary
echo ""
echo -e "${GREEN}=========================================="
echo "✅ Deployment Successful!"
echo "==========================================${NC}"
echo ""
echo "📊 Deployment Summary:"
echo "   Files deployed: ${FILE_COUNT}"
echo "   Total size: ${BUILD_SIZE}"
echo "   Backup: ${BACKUP_NAME}"
echo ""
echo "🔗 Your app should be available at:"
echo "   https://${DOMAIN}"
echo "   https://www.${DOMAIN}"
echo ""
echo "🔧 Server Commands:"
echo "   View logs:    ssh ${SERVER} 'sudo tail -f ${WEB_ROOT}/../logs/error.log'"
echo "   Nginx status: ssh ${SERVER} 'sudo systemctl status nginx'"
echo "   Restart:      ssh ${SERVER} 'sudo systemctl restart nginx'"
echo ""
echo "🔄 Rollback (if needed):"
echo "   ssh ${SERVER} 'cd ${WEB_ROOT} && sudo tar -xzf /tmp/${BACKUP_NAME}'"
echo ""

# Offer to open browser
if command -v xdg-open &> /dev/null; then
    read -p "Open https://${DOMAIN} in browser? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xdg-open "https://${DOMAIN}"
    fi
elif command -v open &> /dev/null; then
    read -p "Open https://${DOMAIN} in browser? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "https://${DOMAIN}"
    fi
fi
