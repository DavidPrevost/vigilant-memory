#!/bin/bash
# Install Baby Monitor as systemd service

set -e

echo "🔧 Installing Baby Monitor Service"
echo "===================================="

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please run as regular user (not root/sudo)"
    echo "   The script will ask for sudo password when needed"
    exit 1
fi

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Project directory: $SCRIPT_DIR"

# Check if venv exists
if [ ! -d "$SCRIPT_DIR/venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "   Run ./setup.sh first to install dependencies"
    exit 1
fi

# Check if device is registered
CONFIG_FILE="/etc/babymonitor/config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  Device not registered yet"
    echo "   You can register after installation with:"
    echo "   python src/device_manager.py --register --name 'My Baby Monitor' --backend http://server:5000"
fi

# Create directories
echo "📁 Creating directories..."
sudo mkdir -p /var/babymonitor/recordings
sudo mkdir -p /var/log
sudo mkdir -p /etc/babymonitor
sudo chown -R $USER:$USER /var/babymonitor
sudo chown -R $USER:$USER /etc/babymonitor

# Copy service file with correct paths
echo "📝 Installing systemd service..."
SERVICE_FILE="/tmp/babymonitor.service"
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Baby Monitor Service
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$SCRIPT_DIR
ExecStart=$SCRIPT_DIR/venv/bin/python $SCRIPT_DIR/src/main.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Environment
Environment="PATH=$SCRIPT_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# Resource limits
MemoryLimit=512M
CPUQuota=80%

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Install service
sudo cp "$SERVICE_FILE" /etc/systemd/system/babymonitor.service
sudo systemctl daemon-reload

echo ""
echo "✅ Installation complete!"
echo ""
echo "Available commands:"
echo "  sudo systemctl start babymonitor     - Start the service"
echo "  sudo systemctl stop babymonitor      - Stop the service"
echo "  sudo systemctl status babymonitor    - Check service status"
echo "  sudo systemctl enable babymonitor    - Enable auto-start on boot"
echo "  sudo systemctl disable babymonitor   - Disable auto-start"
echo "  sudo journalctl -u babymonitor -f    - View logs (live)"
echo ""
echo "To enable auto-start on boot:"
echo "  sudo systemctl enable babymonitor"
echo ""
echo "To start the service now:"
echo "  sudo systemctl start babymonitor"
echo ""
