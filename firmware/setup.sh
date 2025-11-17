#!/bin/bash

# Baby Monitor Firmware Setup Script
# Automates installation of dependencies and environment setup

set -e  # Exit on error

echo "========================================"
echo "Baby Monitor Firmware Setup"
echo "========================================"
echo ""

# Check if running on Raspberry Pi
if [[ ! -f /proc/device-tree/model ]] || ! grep -q "Raspberry Pi" /proc/device-tree/model; then
    echo "⚠️  Warning: This script is designed for Raspberry Pi"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Step 1: Checking system requirements..."
echo "----------------------------------------"

# Check Python version
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found"
    echo "Installing Python 3..."
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv
else
    PYTHON_VERSION=$(python3 --version | awk '{print $2}')
    echo "✓ Python $PYTHON_VERSION found"
fi

# Check if camera is enabled
echo ""
echo "Step 2: Checking camera configuration..."
echo "----------------------------------------"

if vcgencmd get_camera | grep -q "supported=1 detected=1"; then
    echo "✓ Camera detected and enabled"
else
    echo "⚠️  Camera not detected"
    echo ""
    echo "Please enable the camera:"
    echo "1. Run: sudo raspi-config"
    echo "2. Navigate to: Interface Options > Camera"
    echo "3. Select: Enable"
    echo "4. Reboot"
    echo ""
    read -p "Continue setup anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install system dependencies
echo ""
echo "Step 3: Installing system dependencies..."
echo "----------------------------------------"

sudo apt update
sudo apt install -y \
    python3-pip \
    python3-venv \
    libcap-dev \
    libopencv-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev

echo "✓ System dependencies installed"

# Create virtual environment
echo ""
echo "Step 4: Creating Python virtual environment..."
echo "----------------------------------------"

if [ -d "venv" ]; then
    echo "⚠️  Virtual environment already exists"
    read -p "Remove and recreate? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf venv
        python3 -m venv venv
        echo "✓ Virtual environment recreated"
    else
        echo "✓ Using existing virtual environment"
    fi
else
    python3 -m venv venv
    echo "✓ Virtual environment created"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo ""
echo "Step 5: Upgrading pip..."
echo "----------------------------------------"
pip install --upgrade pip setuptools wheel
echo "✓ pip upgraded"

# Install Python dependencies
echo ""
echo "Step 6: Installing Python dependencies..."
echo "----------------------------------------"
echo "This may take 10-15 minutes on Raspberry Pi..."
echo ""

pip install -r requirements.txt

echo ""
echo "✓ Python dependencies installed"

# Create necessary directories
echo ""
echo "Step 7: Creating directories..."
echo "----------------------------------------"

mkdir -p logs
mkdir -p recordings
mkdir -p temp

echo "✓ Directories created"

# Test camera
echo ""
echo "Step 8: Testing camera..."
echo "----------------------------------------"

python src/camera.py

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Camera test passed"
else
    echo ""
    echo "❌ Camera test failed"
    echo "Please check camera connection and try again"
    exit 1
fi

# Setup complete
echo ""
echo "========================================"
echo "✓ Setup Complete!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. Activate virtual environment:"
echo "   source venv/bin/activate"
echo ""
echo "2. Start the web server:"
echo "   python src/web_server.py"
echo ""
echo "3. Access the monitor at:"
echo "   http://raspberrypi.local:5000"
echo "   or http://$(hostname -I | awk '{print $1}'):5000"
echo ""
echo "See README.md for more information."
echo ""
