# Development Environment Setup

This guide will help you set up your development environment to start working on the baby monitor project.

---

## Prerequisites

### Required Knowledge
- Basic Python programming
- Linux command line basics
- Git version control
- Basic networking concepts

### Hardware Required
- Development computer (Windows, Mac, or Linux)
- Raspberry Pi 4 (8GB recommended)
- microSD card (128GB, A2 rated)
- USB-C power supply for Pi
- Ethernet cable or WiFi network

### Software Required
- **VS Code:** Primary IDE
- **Git:** Version control
- **Python 3.11+:** Programming language
- **Docker:** For backend services (optional for firmware development)

---

## Step 1: Development Computer Setup

### Install VS Code

**Download and install:**
- https://code.visualstudio.com/

**Required Extensions:**
1. **Remote - SSH** (Microsoft)
   - Develop directly on Raspberry Pi
   - Install: Search "Remote SSH" in extensions

2. **Python** (Microsoft)
   - Python language support
   - Install: Search "Python" in extensions

3. **Docker** (Microsoft)
   - Manage containers
   - Install: Search "Docker" in extensions

4. **GitLens** (GitKraken)
   - Enhanced Git features
   - Install: Search "GitLens" in extensions

**Recommended Extensions:**
- Markdown All in One
- YAML
- Thunder Client (API testing)

### Install Git

**Windows:**
```bash
# Download from https://git-scm.com/download/win
# Or use winget:
winget install --id Git.Git -e --source winget
```

**Mac:**
```bash
brew install git
# Or download from https://git-scm.com/download/mac
```

**Linux:**
```bash
sudo apt install git  # Debian/Ubuntu
sudo dnf install git  # Fedora
```

**Configure Git:**
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Install Python (Local Development)

**Windows:**
```bash
# Download from https://www.python.org/downloads/
# Or use winget:
winget install Python.Python.3.11
```

**Mac:**
```bash
brew install python@3.11
```

**Linux:**
```bash
sudo apt install python3.11 python3.11-venv python3-pip
```

**Verify Installation:**
```bash
python3 --version  # Should be 3.11+
pip3 --version
```

### Install Docker (For Backend Development)

**Windows/Mac:**
- Download Docker Desktop: https://www.docker.com/products/docker-desktop/

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

**Verify Installation:**
```bash
docker --version
docker-compose --version
docker run hello-world
```

---

## Step 2: Raspberry Pi Setup

### Flash Raspberry Pi OS

**Download Raspberry Pi Imager:**
- https://www.raspberrypi.com/software/

**Steps:**
1. Insert microSD card into computer
2. Open Raspberry Pi Imager
3. Choose OS: **Raspberry Pi OS (64-bit)**
4. Choose Storage: Your microSD card
5. Click gear icon (⚙️) for advanced options:
   - Set hostname: `babymonitor.local`
   - Enable SSH
   - Set username: `pi`
   - Set password: (choose secure password)
   - Configure WiFi (if not using Ethernet)
   - Set locale settings
6. Write to SD card

### First Boot

**Connect Hardware:**
1. Insert microSD card into Raspberry Pi
2. Connect Camera Module 3 to CSI port
3. Connect Ethernet cable (or rely on WiFi)
4. Connect power supply
5. Wait ~60 seconds for first boot

**Find Pi on Network:**

**Option A: If using Ethernet/WiFi with mDNS:**
```bash
ping babymonitor.local
```

**Option B: Find IP address:**
```bash
# Linux/Mac:
arp -a | grep raspberrypi

# Windows:
arp -a | findstr b8-27-eb  # Pi 3/4 MAC prefix
```

**SSH into Pi:**
```bash
ssh pi@babymonitor.local
# Or:
ssh pi@<ip_address>
```

**Password:** (what you set in Imager)

### Initial Configuration

**Update System:**
```bash
sudo apt update
sudo apt upgrade -y
```

**Enable Camera:**
```bash
sudo raspi-config
# Navigate to: Interface Options > Camera > Enable
```

**Enable I2C (for sensors):**
```bash
sudo raspi-config
# Navigate to: Interface Options > I2C > Enable
```

**Install Essential Tools:**
```bash
sudo apt install -y \
    python3-pip \
    python3-venv \
    git \
    vim \
    htop \
    i2c-tools \
    avahi-daemon
```

**Reboot:**
```bash
sudo reboot
```

**Reconnect after reboot:**
```bash
ssh pi@babymonitor.local
```

---

## Step 3: Repository Setup

### Clone Repository

**On your development computer:**
```bash
cd ~/Projects  # or wherever you keep code
git clone https://github.com/your-username/vigilant-memory.git
cd vigilant-memory
```

**If repository doesn't exist yet:**
```bash
cd ~/Projects
mkdir baby-monitor
cd baby-monitor
git init
```

### Create Directory Structure

```bash
# On Raspberry Pi (via SSH)
cd ~
mkdir baby-monitor
cd baby-monitor

# Create structure
mkdir -p firmware/src/{web/static,web/templates,tests}
mkdir -p backend/src
mkdir -p mobile
mkdir -p docs

# Initialize Git
git init
```

### Create .gitignore

```bash
# In baby-monitor directory
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Secrets
.env
*.key
*.pem
credentials.json

# Test files
*.log
*.db
*.sqlite

# Media
*.mp4
*.avi
*.mkv
test_*.jpg
test_*.png

# Node
node_modules/

# Build
build/
dist/
*.egg-info/

# Temp
tmp/
temp/
EOF
```

### Connect VS Code to Raspberry Pi

**In VS Code:**

1. Press `F1` or `Cmd/Ctrl+Shift+P`
2. Type: "Remote-SSH: Connect to Host"
3. Enter: `pi@babymonitor.local`
4. Enter password when prompted
5. VS Code will install remote server on Pi (first time only)
6. Open folder: `/home/pi/baby-monitor`

**You're now coding directly on the Pi!**

---

## Step 4: Python Environment Setup (Pi)

### Create Virtual Environment

```bash
# On Pi (via VS Code terminal or SSH)
cd ~/baby-monitor/firmware
python3 -m venv venv
source venv/bin/activate  # Activate environment
```

**Add activation to .bashrc (optional):**
```bash
echo "cd ~/baby-monitor/firmware && source venv/bin/activate" >> ~/.bashrc
```

### Create requirements.txt

```bash
# In firmware directory
cat > requirements.txt << 'EOF'
# Camera
picamera2>=0.3.12
opencv-python>=4.8.0

# Video processing
av>=10.0.0
ffmpeg-python>=0.2.0

# Web framework
flask>=3.0.0
flask-cors>=4.0.0
flask-socketio>=5.3.0

# WebRTC
aiortc>=1.5.0
aiohttp>=3.9.0

# Audio
pyaudio>=0.2.13
pydub>=0.25.0
pygame>=2.5.0

# Sensors
smbus2>=0.4.2
adafruit-circuitpython-bme680>=3.7.0
adafruit-circuitpython-adxl34x>=1.12.0
adafruit-circuitpython-bh1750>=1.1.0

# MQTT
paho-mqtt>=1.6.0

# Database
aiosqlite>=0.19.0

# Utilities
python-dotenv>=1.0.0
httpx>=0.25.0
python-jose[cryptography]>=3.3.0

# Development
pytest>=7.4.0
pytest-asyncio>=0.21.0
black>=23.0.0
flake8>=6.1.0
EOF
```

### Install Dependencies

```bash
# Activate venv if not already
source venv/bin/activate

# Install system dependencies first
sudo apt install -y \
    libcap-dev \
    libopencv-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswscale-dev \
    libportaudio2 \
    libportaudio-dev

# Install Python packages
pip install -r requirements.txt
```

**This will take 10-15 minutes on Raspberry Pi.**

### Test Camera

```bash
# Test camera with libcamera (should see preview for 5 seconds)
libcamera-hello --timeout 5000

# Test with Python
python3 << 'EOF'
from picamera2 import Picamera2
import time

picam2 = Picamera2()
config = picam2.create_preview_configuration()
picam2.configure(config)
picam2.start()
print("Camera started successfully!")
time.sleep(2)
picam2.stop()
EOF
```

### Test Sensors

```bash
# Detect I2C devices (should see addresses if sensors connected)
i2cdetect -y 1
```

---

## Step 5: Backend Development Setup

### Install Docker Compose

**If not already installed:**
```bash
sudo apt install docker-compose
# or newer syntax:
sudo apt install docker-compose-plugin
```

### Create docker-compose.yml

```bash
# On development computer or server
cd ~/Projects/baby-monitor/backend

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: devpassword
      POSTGRES_DB: baby_monitor
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  timescaledb:
    image: timescale/timescaledb:latest-pg15
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: devpassword
      POSTGRES_DB: baby_monitor_timeseries
    ports:
      - "5433:5432"
    volumes:
      - timescale_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  minio:
    image: minio/minio:latest
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    ports:
      - "9000:9000"
      - "9001:9001"
    volumes:
      - minio_data:/data

  mosquitto:
    image: eclipse-mosquitto:2
    ports:
      - "1883:1883"
      - "9002:9001"
    volumes:
      - ./mosquitto.conf:/mosquitto/config/mosquitto.conf
      - mosquitto_data:/mosquitto/data

volumes:
  postgres_data:
  timescale_data:
  redis_data:
  minio_data:
  mosquitto_data:
EOF
```

### Create Mosquitto Config

```bash
cat > mosquitto.conf << 'EOF'
listener 1883
allow_anonymous true
persistence true
persistence_location /mosquitto/data/
log_dest stdout
EOF
```

### Start Services

```bash
docker-compose up -d
```

### Verify Services

```bash
# Check all services running
docker-compose ps

# Test PostgreSQL
docker exec -it backend-postgres-1 psql -U postgres -d baby_monitor -c "SELECT version();"

# Test Redis
docker exec -it backend-redis-1 redis-cli ping

# Test MinIO (open in browser)
# http://localhost:9001
# Login: minioadmin / minioadmin

# Test Mosquitto
docker exec -it backend-mosquitto-1 mosquitto_pub -t test -m "hello"
```

### Create Backend Python Environment

```bash
cd ~/Projects/baby-monitor/backend
python3 -m venv venv
source venv/bin/activate

cat > requirements.txt << 'EOF'
# Web framework
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
python-multipart>=0.0.6

# Database
sqlalchemy>=2.0.0
asyncpg>=0.29.0
alembic>=1.12.0

# Validation
pydantic>=2.4.0
pydantic-settings>=2.0.0

# Authentication
python-jose[cryptography]>=3.3.0
passlib[bcrypt]>=1.7.4
firebase-admin>=6.2.0

# Cache & Queue
redis>=5.0.0
aioredis>=2.0.1

# Utilities
python-dotenv>=1.0.0
httpx>=0.25.0

# Development
pytest>=7.4.0
pytest-asyncio>=0.21.0
black>=23.0.0
flake8>=6.1.0
EOF

pip install -r requirements.txt
```

---

## Step 6: Mobile Development Setup (Flutter)

### Install Flutter

**macOS:**
```bash
# Install using Homebrew
brew install --cask flutter

# Or download from flutter.dev
```

**Linux:**
```bash
# Download Flutter SDK
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.0-stable.tar.xz
tar xf flutter_linux_3.16.0-stable.tar.xz

# Add to PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

**Windows:**
- Download from https://docs.flutter.dev/get-started/install/windows
- Extract and add to PATH

### Install Android Studio

**Download:**
- https://developer.android.com/studio

**Install Android SDK:**
1. Open Android Studio
2. Go to: Settings > Appearance & Behavior > System Settings > Android SDK
3. Install Android 13.0 (API 33) or latest
4. Install Android SDK Command-line Tools

### Install Xcode (macOS only, for iOS)

**Download from App Store:**
- https://apps.apple.com/us/app/xcode/id497799835

**Install Command Line Tools:**
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

### Run Flutter Doctor

```bash
flutter doctor -v
```

**Fix any issues reported.**

### Create Flutter Project

```bash
cd ~/Projects/baby-monitor/mobile
flutter create baby_monitor_app
cd baby_monitor_app
```

### Test Flutter App

**Run on Android emulator:**
```bash
# Start emulator from Android Studio or:
flutter emulators --launch <emulator_id>

# Run app
flutter run
```

**Run on iOS simulator (macOS):**
```bash
# List simulators
xcrun simctl list devices

# Boot simulator
open -a Simulator

# Run app
flutter run
```

---

## Step 7: Development Workflow

### Typical Day

**1. Start Docker services (if doing backend work):**
```bash
cd ~/Projects/baby-monitor/backend
docker-compose up -d
```

**2. Connect VS Code to Raspberry Pi:**
- Open VS Code
- Remote-SSH: Connect to `pi@babymonitor.local`
- Open folder: `/home/pi/baby-monitor`

**3. Start developing:**
```bash
# Activate Python environment
cd firmware
source venv/bin/activate

# Run firmware
python src/main.py

# Or run specific module
python src/camera.py
```

**4. Test from mobile app:**
```bash
cd ~/Projects/baby-monitor/mobile/baby_monitor_app
flutter run
```

### Common Commands

**Firmware (on Pi):**
```bash
# Activate environment
source venv/bin/activate

# Run main application
python src/main.py

# Run tests
pytest

# Format code
black src/

# Check code style
flake8 src/
```

**Backend (on dev computer):**
```bash
# Activate environment
source venv/bin/activate

# Run API server
uvicorn src.main:app --reload

# Create database migration
alembic revision --autogenerate -m "Description"

# Apply migrations
alembic upgrade head

# Run tests
pytest
```

**Mobile (on dev computer):**
```bash
# Run on emulator/simulator
flutter run

# Run on physical device
flutter run -d <device_id>

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/camera-integration

# Make changes, then:
git add .
git commit -m "Add camera capture functionality"

# Push to remote
git push origin feature/camera-integration

# When ready, merge to main
git checkout main
git merge feature/camera-integration
git push origin main
```

---

## Step 8: Useful Tools

### API Testing

**Thunder Client (VS Code Extension):**
- Install extension
- Create requests
- Test API endpoints

**Or use curl:**
```bash
# Test health endpoint
curl http://localhost:8000/health

# Test with authentication
curl -H "Authorization: Bearer <token>" \
  http://localhost:8000/devices
```

### Database Tools

**pgAdmin (GUI):**
- Download: https://www.pgadmin.org/download/
- Connect to localhost:5432

**Or use psql (command line):**
```bash
# Connect to database
docker exec -it backend-postgres-1 psql -U postgres -d baby_monitor

# Run queries
SELECT * FROM users;
```

### Monitoring Pi Performance

```bash
# CPU/memory usage
htop

# Temperature
vcgencmd measure_temp

# Disk usage
df -h

# Network usage
iftop
```

---

## Troubleshooting

### Can't connect to Raspberry Pi

**Check Pi is on network:**
```bash
ping babymonitor.local
```

**If ping fails:**
1. Connect monitor and keyboard to Pi
2. Check WiFi: `sudo raspi-config` > System Options > Wireless LAN
3. Check SSH enabled: `sudo raspi-config` > Interface Options > SSH

### Python package installation fails

**Update pip:**
```bash
pip install --upgrade pip setuptools wheel
```

**Install dependencies one by one:**
```bash
pip install picamera2
pip install opencv-python
# etc.
```

### Camera not working

**Check camera detected:**
```bash
libcamera-hello --list-cameras
```

**If not detected:**
1. Check cable connection (ribbon cable can be finicky)
2. Re-enable camera: `sudo raspi-config`
3. Reboot: `sudo reboot`

### Docker services won't start

**Check logs:**
```bash
docker-compose logs <service_name>
```

**Restart services:**
```bash
docker-compose down
docker-compose up -d
```

### Flutter doctor issues

**Common fixes:**
```bash
# Android licenses
flutter doctor --android-licenses

# Update Flutter
flutter upgrade

# Clear cache
flutter clean
```

---

## Next Steps

Once your development environment is set up:

1. Read [Development Roadmap](./06-development-roadmap.md)
2. Start with Phase 1: Camera + Basic Streaming
3. Commit code frequently
4. Test on real hardware early and often

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
