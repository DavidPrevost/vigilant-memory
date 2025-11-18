# Baby Monitor Firmware

Complete firmware for the baby monitor device running on Raspberry Pi.

## Current Implementation Status

### ✅ Phase 1: Camera + Basic Streaming
- Camera capture (720p/1080p @ 30fps)
- MJPEG streaming over HTTP
- Web interface for live viewing
- Snapshot capture
- H.264 video recording

### ✅ Phase 3: Environmental Sensors (Ready)
- BME680: Temperature, humidity, pressure, air quality
- BH1750: Ambient light measurement
- ADXL345: Motion/vibration detection
- Automatic periodic sensor readings
- Sensor data upload to backend

### ✅ Phase 4: Backend Integration
- Device registration with backend
- MQTT real-time communication
- Video upload to cloud storage
- Event reporting
- System health monitoring
- Remote command execution

### ⏳ Phase 2: Audio + WebRTC (Not Yet Implemented)
- Two-way audio
- WebRTC streaming (low latency)
- Lullaby playback

---

## Architecture

The firmware integrates with the backend infrastructure:

```
┌─────────────────┐
│  Raspberry Pi   │
│   Baby Monitor  │
├─────────────────┤
│                 │
│  Camera ────────┼──► MJPEG Stream (Local)
│  Sensors ───────┼──► Backend API (HTTP)
│  System Monitor─┼──► Backend API (HTTP)
│                 │
│  MQTT Client ───┼──► MQTT Broker ◄──► Backend
│  Video Uploader─┼──► Backend API (HTTP) ──► MinIO
│                 │
└─────────────────┘
```

**Communication Channels:**
- **HTTP REST API**: Device registration, status updates, video uploads, sensor data
- **MQTT**: Real-time telemetry, events, commands from backend
- **Local HTTP**: Web interface for direct access on local network

---

## Quick Start

### 1. Hardware Setup

**Required:**
- Raspberry Pi 4/5 (4GB+ recommended)
- Camera Module 3 (or compatible)
- MicroSD card (32GB+, A2 rated)
- Power supply (official 27W USB-C for Pi 5)

**Optional (Phase 3):**
- BME680 sensor (temperature, humidity, air quality)
- BH1750 sensor (light level)
- ADXL345 sensor (motion/vibration)

### 2. Installation

```bash
# Clone repository
cd ~
git clone https://github.com/DavidPrevost/vigilant-memory.git
cd vigilant-memory/firmware

# Run automated setup
chmod +x setup.sh
./setup.sh
```

This will:
- Check Python version (3.10+ required)
- Create virtual environment
- Install all dependencies
- Verify camera detection

### 3. Register Device

**Before starting the firmware, register with backend:**

```bash
# Activate virtual environment
source venv/bin/activate

# Register device
python src/device_manager.py --register \
  --name "Nursery Monitor" \
  --backend http://your-server-ip:5000

# Verify registration
python src/device_manager.py --status
```

**Output:**
```
✅ Device registered successfully!
Device ID: 5f8d3a1c-9b2e-4f7a-8c3d-1e6f9a4b2c7d
MQTT Client ID: device_5f8d3a1c9b2e

Configuration saved to: /etc/babymonitor/config.json
```

### 4. Start the Monitor

**Option A: Run manually (for testing)**
```bash
python src/main.py
```

**Option B: Install as system service (recommended)**
```bash
# Install systemd service
chmod +x install_service.sh
./install_service.sh

# Enable auto-start on boot
sudo systemctl enable babymonitor

# Start service now
sudo systemctl start babymonitor

# Check status
sudo systemctl status babymonitor

# View logs
sudo journalctl -u babymonitor -f
```

### 5. Access the Monitor

**Local web interface:**
- http://raspberrypi.local:5000
- http://your-pi-ip:5000

**Via backend/mobile app:**
- Access through your backend web dashboard
- Use mobile app (Phase 5)

---

## Project Structure

```
firmware/
├── src/
│   ├── main.py                 # Main application orchestrator
│   ├── config.py               # Configuration management
│   ├── camera.py               # Camera control
│   ├── backend_client.py       # Backend API client
│   ├── mqtt_client.py          # MQTT communication
│   ├── video_uploader.py       # Video upload queue
│   ├── system_monitor.py       # System health monitoring
│   ├── device_manager.py       # Device registration CLI
│   ├── web_server.py           # Local web server (Phase 1)
│   ├── sensors/
│   │   ├── sensor_manager.py   # Sensor coordinator
│   │   ├── bme680_sensor.py    # Temp/humidity/air quality
│   │   ├── bh1750_sensor.py    # Light sensor
│   │   └── adxl345_sensor.py   # Accelerometer/motion
│   └── web/
│       ├── static/             # CSS, JavaScript
│       └── templates/          # HTML templates
├── tests/                      # Unit tests
├── requirements.txt            # Python dependencies
├── setup.sh                    # Automated setup
├── install_service.sh          # Service installer
├── babymonitor.service         # Systemd service file
└── README.md                   # This file
```

---

## Configuration

### Configuration File

Located at: `/etc/babymonitor/config.json`

**Example:**
```json
{
  "device_id": "5f8d3a1c-9b2e-4f7a-8c3d-1e6f9a4b2c7d",
  "device_name": "Nursery Monitor",
  "backend_url": "http://server:5000",
  "mqtt_broker_host": "server",
  "mqtt_broker_port": 1883,
  "camera_resolution": [1280, 720],
  "camera_framerate": 30,
  "sensors_enabled": true,
  "upload_videos": true,
  "motion_detection_enabled": false
}
```

### Manage Configuration

```bash
# View current configuration
python src/device_manager.py --status

# Update MQTT broker
python src/device_manager.py --mqtt-host server.local --mqtt-port 1883

# Unregister device
python src/device_manager.py --unregister
```

---

## Features

### Camera

**Capabilities:**
- 1080p @ 30fps (or 720p for better performance)
- H.264 hardware encoding
- MJPEG streaming for local access
- Snapshot capture
- Event-triggered recording

**Video Storage:**
- Local buffering in `/var/babymonitor/recordings/`
- Automatic upload to backend (MinIO/S3)
- Configurable retention policies

### Sensors (Phase 3)

**BME680** - Environmental Monitoring
- Temperature: ±0.5°C accuracy
- Humidity: ±3% accuracy
- Pressure: ±1 hPa
- Air quality: Gas resistance measurement

**BH1750** - Light Sensor
- Range: 1-65535 lux
- Used for automatic night mode
- Room brightness monitoring

**ADXL345** - Motion Detection
- 3-axis accelerometer
- Detects vibration/movement
- Crib shaking detection

**Automatic Readings:**
- Every 60 seconds (configurable)
- Sent to backend via HTTP and MQTT
- Cached locally for latest values

### Backend Integration

**Device Registration:**
- Secure device authentication
- Unique device ID and secret
- MQTT client credentials

**Status Updates:**
- CPU usage, temperature
- Memory and disk usage
- Network connectivity
- Battery level (if available)
- Sent every 60 seconds

**Video Uploads:**
- Automatic queue management
- Retry logic with exponential backoff
- Local cleanup after successful upload
- Failed uploads moved to `/var/babymonitor/recordings/failed/`

**Event Reporting:**
- Motion detection events
- Sound level alerts
- Sensor threshold violations
- System health warnings

### MQTT Communication

**Published Topics:**
- `devices/{device_id}/status` - Device status heartbeat
- `devices/{device_id}/telemetry` - Sensor readings
- `devices/{device_id}/events` - Detection events

**Subscribed Topics:**
- `devices/{device_id}/commands` - Remote commands from backend

**Supported Commands:**
- `start_recording` - Start video recording
- `stop_recording` - Stop recording
- `capture_snapshot` - Take snapshot
- `update_settings` - Update configuration
- `reboot` - Reboot device

### System Monitoring

**Tracked Metrics:**
- CPU usage and temperature
- Memory usage
- Disk space
- Network connectivity
- WiFi signal strength
- System uptime
- Battery level (if present)

**Health Checks:**
- CPU temperature < 80°C
- Disk usage < 90%
- Memory usage < 90%

---

## Development

### Running Tests

```bash
source venv/bin/activate
pytest tests/ -v
```

### Code Formatting

```bash
black src/
flake8 src/
```

### Testing Components Individually

**Test Camera:**
```bash
python src/camera.py
```

**Test Backend Connection:**
```bash
python -c "from src.backend_client import BackendClient; \
    client = BackendClient('http://server:5000'); \
    print('Healthy!' if client.health_check() else 'Failed')"
```

**Test Sensors:**
```bash
python -c "from src.sensors import SensorManager; \
    sm = SensorManager(); \
    sm.initialize(); \
    print(sm.read_all())"
```

**Test MQTT:**
```bash
python -c "from src.mqtt_client import MQTTClient; \
    mqtt = MQTTClient('server', 1883, 'test_device', 'client123'); \
    mqtt.connect(); \
    print('Connected!' if mqtt.wait_for_connection() else 'Failed')"
```

---

## Troubleshooting

### Device Won't Register

**Check backend connectivity:**
```bash
curl http://your-server:5000/health
```

**Expected:**
```json
{"status": "healthy", "timestamp": "..."}
```

**If fails:**
- Verify backend is running
- Check firewall/network
- Verify backend URL is correct

### Camera Not Detected

**On Raspberry Pi OS Bookworm (current):**
- Camera is enabled by default
- No raspi-config needed

**Verify detection:**
```bash
libcamera-hello --list-cameras
```

**If not detected:**
- Check ribbon cable connection
- Verify cable orientation (blue tab toward USB ports)
- Reboot: `sudo reboot`

### Sensors Not Working

**Check I2C is enabled:**
```bash
ls /dev/i2c-*
# Should show: /dev/i2c-1
```

**Enable I2C:**
```bash
sudo raspi-config
# Interface Options > I2C > Enable
sudo reboot
```

**Detect sensors:**
```bash
sudo apt install i2c-tools
sudo i2cdetect -y 1
```

**Expected addresses:**
- BME680: 0x76 or 0x77
- BH1750: 0x23 or 0x5C
- ADXL345: 0x53

### Service Won't Start

**Check logs:**
```bash
sudo journalctl -u babymonitor -n 50
```

**Common issues:**
- Device not registered: Run `device_manager.py --register`
- Backend not reachable: Check network/firewall
- Camera busy: Kill other camera processes
- Permission issues: Check file ownership

### High CPU/Temperature

**Monitor resources:**
```bash
htop
vcgencmd measure_temp
```

**Solutions:**
- Reduce camera resolution to 720p
- Lower framerate to 24fps
- Add heatsink/fan
- Disable unnecessary features

### MQTT Connection Fails

**Test MQTT broker:**
```bash
# Install mosquitto clients
sudo apt install mosquitto-clients

# Test connection
mosquitto_sub -h your-server -p 1883 -t 'test' -v
```

**Check configuration:**
```bash
python src/device_manager.py --status
# Verify mqtt_broker_host and mqtt_broker_port
```

---

## System Service Management

**Start service:**
```bash
sudo systemctl start babymonitor
```

**Stop service:**
```bash
sudo systemctl stop babymonitor
```

**Restart service:**
```bash
sudo systemctl restart babymonitor
```

**Check status:**
```bash
sudo systemctl status babymonitor
```

**View logs:**
```bash
# Live logs
sudo journalctl -u babymonitor -f

# Last 100 lines
sudo journalctl -u babymonitor -n 100

# Since boot
sudo journalctl -u babymonitor -b
```

**Enable auto-start:**
```bash
sudo systemctl enable babymonitor
```

**Disable auto-start:**
```bash
sudo systemctl disable babymonitor
```

---

## Performance

**Raspberry Pi 4 (4GB):**
- 720p @ 30fps: ~25-30% CPU
- 1080p @ 30fps: ~35-45% CPU
- With sensors: +5% CPU
- Temperature: 45-55°C (with heatsink)
- Memory: ~200-300MB

**Network:**
- MJPEG local stream: ~1.5-3 Mbps
- Video upload: Depends on recording
- MQTT: <1 KB/s
- HTTP status: <1 KB/min

**Storage:**
- Firmware: ~100MB
- Recordings (temporary): Varies
- Logs: ~1MB/day

---

## Security Notes

- Device credentials stored in `/etc/babymonitor/config.json`
- Ensure proper file permissions (600)
- Use HTTPS for backend in production
- Use TLS for MQTT in production
- Videos encrypted if backend configured for E2E

---

## Next Steps

**Phase 2: Audio + WebRTC**
- Two-way audio communication
- Low-latency WebRTC streaming
- Lullaby playback

**Phase 5: Mobile App**
- Flutter mobile app
- Push notifications
- Remote access

**Production Hardware:**
- Test on RK3588 (Pro model)
- Test on RV1126 (Core model)
- Custom PCB integration

---

## Support

**Documentation:** `/docs` directory in repository
**Backend Setup:** See `backend/README.md`
**Testing Procedures:** See `docs/10-testing-procedures.md`

---

**Current Version:** 1.0.0 (Phase 1 + 3 + 4 Integration)
**Last Updated:** 2025-11-18
