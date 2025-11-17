# Baby Monitor Firmware

Firmware for the baby monitor device running on Raspberry Pi 4.

## Current Phase: Phase 1 - Camera + Basic Streaming

### Features Implemented
- ✅ Camera capture (720p @ 30fps)
- ✅ MJPEG streaming over HTTP
- ✅ Web interface for live viewing
- ✅ Snapshot capture
- ✅ Status API

### Coming Next (Phase 2)
- Two-way audio
- WebRTC streaming (low latency)
- Lullaby playback

---

## Quick Start (On Raspberry Pi)

### Prerequisites
- Raspberry Pi 4 (4GB or 8GB)
- Camera Module 3 connected
- Raspberry Pi OS (64-bit) installed
- Internet connection

### Installation

```bash
# 1. Clone repository (if not already done)
cd ~
git clone https://github.com/your-org/baby-monitor.git
cd baby-monitor/firmware

# 2. Run setup script
chmod +x setup.sh
./setup.sh

# 3. Activate virtual environment
source venv/bin/activate

# 4. Test camera
python src/camera.py

# 5. Start web server
python src/web_server.py
```

### Access the Monitor

Once the server is running:
- **From same network:** http://raspberrypi.local:5000
- **Or use IP address:** http://192.168.1.XXX:5000

---

## Manual Setup (Detailed)

### 1. System Dependencies

```bash
# Update system
sudo apt update
sudo apt upgrade -y

# Enable camera
sudo raspi-config
# Navigate to: Interface Options > Camera > Enable

# Install system packages
sudo apt install -y \
    python3-pip \
    python3-venv \
    libcap-dev \
    libopencv-dev \
    libavcodec-dev \
    libavformat-dev
```

### 2. Python Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

This will take 10-15 minutes on Raspberry Pi.

### 3. Test Camera

```bash
# Test with libcamera first
libcamera-hello --timeout 5000

# Test with our Python script
python src/camera.py
```

Expected output:
```
Baby Monitor - Camera Test
==================================================

1. Starting camera...
2. Capturing test frame...
   ✓ Captured frame (XXXXX bytes)
   ✓ Saved to /tmp/test_frame.jpg
3. Testing video recording (5 seconds)...
   ✓ Recording saved to /tmp/test_video.h264
4. Camera information:
   Resolution: 1280x720
   Framerate: 30 fps
   Status: Idle

✓ All tests passed!
```

### 4. Start Web Server

```bash
python src/web_server.py
```

Expected output:
```
Baby Monitor - Web Server
==================================================

Starting server...
Access the monitor at: http://raspberrypi.local:5000
Or: http://<your-pi-ip>:5000

Press Ctrl+C to stop
==================================================
```

### 5. View in Browser

Open a web browser on your computer or phone (same WiFi network) and navigate to:
- http://raspberrypi.local:5000

You should see the live video feed!

---

## Project Structure

```
firmware/
├── src/
│   ├── camera.py           # Camera management module
│   ├── web_server.py       # Flask web server
│   └── web/
│       ├── static/         # Static files (CSS, JS)
│       └── templates/      # HTML templates
│           └── index.html  # Main web interface
├── tests/                  # Unit tests (coming soon)
├── requirements.txt        # Python dependencies
├── setup.sh               # Automated setup script
└── README.md              # This file
```

---

## API Endpoints

### GET /
Main web interface

### GET /video_feed
MJPEG video stream

### GET /api/status
Get camera status
```json
{
  "status": "online",
  "resolution": {"width": 1280, "height": 720},
  "framerate": 30,
  "recording": false
}
```

### GET /api/snapshot
Capture and download a single frame (JPEG)

### POST /api/camera/resolution/{width}/{height}
Change camera resolution (requires restart)

---

## Development

### Running Tests

```bash
# Activate virtual environment
source venv/bin/activate

# Run tests
pytest

# Run with coverage
pytest --cov=src tests/
```

### Code Formatting

```bash
# Format code
black src/

# Check code style
flake8 src/
```

---

## Troubleshooting

### Camera not detected

```bash
# Check if camera is connected
libcamera-hello --list-cameras

# If not detected:
# 1. Check ribbon cable connection
# 2. Enable camera in raspi-config
# 3. Reboot: sudo reboot
```

### Web server won't start

```bash
# Check if port 5000 is already in use
sudo lsof -i :5000

# Use a different port
python src/web_server.py --port 5001
```

### Cannot access from other device

```bash
# Check Raspberry Pi's IP address
hostname -I

# Make sure firewall isn't blocking
sudo ufw allow 5000/tcp

# Or disable firewall temporarily
sudo ufw disable
```

### Low frame rate

```bash
# Check CPU usage
htop

# Check temperature
vcgencmd measure_temp

# If overheating, add cooling or reduce resolution
```

---

## Performance Notes

**Current Performance (Raspberry Pi 4, 4GB):**
- Resolution: 1280x720 (720p)
- Frame rate: 30 fps
- CPU usage: ~25-35%
- Latency: ~200-300ms (MJPEG over HTTP)

**Tips for better performance:**
- Use Ethernet instead of WiFi
- Reduce resolution to 640x480 for slower networks
- Close other applications on Pi
- Ensure good cooling (heatsink/fan)

---

## Next Steps

After verifying Phase 1 works:

1. **Phase 2:** Add audio and WebRTC
   - See: `/docs/06-development-roadmap.md`

2. **Phase 3:** Add environmental sensors
   - Temperature, humidity, light, motion

3. **Phase 4:** Cloud integration
   - User accounts, cloud storage, remote access

---

## Support

**Documentation:** See `/docs` directory
**Issues:** Report at GitHub repository
**Questions:** See troubleshooting section above

---

**Current Version:** 0.1.0 (Phase 1 Prototype)
**Last Updated:** 2025-11-17
