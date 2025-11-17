# Testing Procedures

This document provides step-by-step testing procedures for the baby monitor system at each phase of development.

**Current Phase:** Phase 1 - Camera + Basic Streaming

---

## Table of Contents

- [Phase 1: Camera + Basic Streaming](#phase-1-camera--basic-streaming)
  - [Pre-Installation Checklist](#pre-installation-checklist)
  - [Installation Steps](#installation-steps)
  - [Testing Procedures](#testing-procedures)
  - [Expected Results](#expected-results)
  - [Troubleshooting](#troubleshooting)
- [Phase 2: Audio + WebRTC](#phase-2-audio--webrtc) (Coming Soon)

---

## Phase 1: Camera + Basic Streaming

### Pre-Installation Checklist

**Hardware Requirements:**
- [ ] Raspberry Pi 4 (4GB or 8GB RAM)
- [ ] Camera Module 3 (official Raspberry Pi camera)
- [ ] USB-C power supply (5V/3A, official recommended)
- [ ] 128GB microSD card (A2 rated, UHS-I)
- [ ] Ethernet cable OR WiFi network access
- [ ] Computer/phone on same network for testing

**Software Requirements:**
- [ ] Raspberry Pi OS (64-bit) installed and updated
- [ ] Internet connection for downloading packages
- [ ] SSH enabled (if testing remotely)

**Physical Setup:**
- [ ] Camera Module 3 connected to CSI port
- [ ] Pi powered on and booted
- [ ] Pi connected to network (Ethernet or WiFi)

---

### Installation Steps

#### Step 1: Prepare Raspberry Pi

**1.1 - Update System**

```bash
# SSH into Raspberry Pi or use terminal on Pi
ssh pi@raspberrypi.local
# Or if using IP: ssh pi@192.168.1.XXX

# Update package lists
sudo apt update

# Upgrade installed packages (this may take 10-15 minutes)
sudo apt upgrade -y
```

**Expected Output:**
```
Reading package lists... Done
Building dependency tree... Done
...
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
```

**1.2 - Enable Camera**

```bash
# Open Raspberry Pi configuration tool
sudo raspi-config
```

**Navigation:**
1. Arrow keys to navigate to "Interface Options"
2. Press Enter
3. Navigate to "Camera"
4. Press Enter
5. Select "Yes" to enable camera
6. Select "Finish"
7. Select "Yes" to reboot (or reboot manually: `sudo reboot`)

**Expected Result:** Pi reboots

**1.3 - Verify Camera Connection**

```bash
# After reboot, SSH back in or open terminal
ssh pi@raspberrypi.local

# Test camera detection
libcamera-hello --list-cameras
```

**Expected Output:**
```
Available cameras
-----------------
0 : imx708 [4608x2592] (/base/soc/i2c0mux/i2c@1/imx708@1a)
    Modes: 'SRGGB10_CSI2P' : 1536x864 [120.13 fps - (768, 432)/3072/1728 crop]
           'SRGGB10_CSI2P' : 2304x1296 [56.03 fps - (0, 0)/4608/2592 crop]
           'SRGGB10_CSI2P' : 4608x2592 [14.35 fps - (0, 0)/4608/2592 crop]
```

**If camera not detected:**
- Check ribbon cable connection (blue tab facing USB ports)
- Ensure cable fully inserted in both camera and Pi
- Try different CSI port if Pi has multiple
- Re-enable camera in raspi-config
- Reboot again

**1.4 - Test Camera Capture**

```bash
# Capture 5-second preview (should show on display if connected)
libcamera-hello --timeout 5000

# Capture a still image
libcamera-still -o test.jpg

# Verify image was created
ls -lh test.jpg
```

**Expected Output:**
```
-rw-r--r-- 1 pi pi 2.1M Nov 17 10:30 test.jpg
```

**1.5 - Clone Repository**

```bash
# Navigate to home directory
cd ~

# Clone the repository
git clone https://github.com/DavidPrevost/vigilant-memory.git

# Navigate to firmware directory
cd vigilant-memory/firmware

# Verify files are present
ls -la
```

**Expected Output:**
```
drwxr-xr-x 4 pi pi 4096 Nov 17 10:35 .
drwxr-xr-x 3 pi pi 4096 Nov 17 10:35 ..
-rw-r--r-- 1 pi pi  234 Nov 17 10:35 .gitignore
-rw-r--r-- 1 pi pi 5432 Nov 17 10:35 README.md
-rw-r--r-- 1 pi pi  892 Nov 17 10:35 requirements.txt
-rwxr-xr-x 1 pi pi 2156 Nov 17 10:35 setup.sh
drwxr-xr-x 3 pi pi 4096 Nov 17 10:35 src
```

---

#### Step 2: Run Automated Setup

**2.1 - Execute Setup Script**

```bash
# Make sure you're in the firmware directory
cd ~/vigilant-memory/firmware

# Run setup script (this will take 15-20 minutes)
./setup.sh
```

**Expected Output (abbreviated):**
```
========================================
Baby Monitor Firmware Setup
========================================

Step 1: Checking system requirements...
----------------------------------------
✓ Python 3.11.2 found

Step 2: Checking camera configuration...
----------------------------------------
✓ Camera detected and enabled

Step 3: Installing system dependencies...
----------------------------------------
[... installation output ...]
✓ System dependencies installed

Step 4: Creating Python virtual environment...
----------------------------------------
✓ Virtual environment created

Step 5: Upgrading pip...
----------------------------------------
✓ pip upgraded

Step 6: Installing Python dependencies...
----------------------------------------
This may take 10-15 minutes on Raspberry Pi...
[... lots of compilation output ...]
✓ Python dependencies installed

Step 7: Creating directories...
----------------------------------------
✓ Directories created

Step 8: Testing camera...
----------------------------------------
Baby Monitor - Camera Test
==================================================

1. Starting camera...
[... camera test output ...]

✓ All tests passed!

========================================
✓ Setup Complete!
========================================

Next steps:
1. Activate virtual environment:
   source venv/bin/activate

2. Start the web server:
   python src/web_server.py

3. Access the monitor at:
   http://raspberrypi.local:5000
```

**If setup fails:**
- Check error messages carefully
- Most common: camera not enabled - see Step 1.2
- Internet connection issues - check network
- Permission errors - ensure you're user 'pi' or have sudo access

**2.2 - Verify Installation**

```bash
# Activate virtual environment
source venv/bin/activate

# Your prompt should now show (venv)
# Example: (venv) pi@raspberrypi:~/vigilant-memory/firmware $

# Verify Python packages installed
pip list | grep -E "picamera2|flask|opencv"
```

**Expected Output:**
```
Flask                    3.0.0
flask-cors               4.0.0
opencv-python            4.8.1.78
picamera2                0.3.12
```

---

### Testing Procedures

#### Test 1: Camera Module Test

**Purpose:** Verify camera capture and basic functionality

**Steps:**

```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Run camera test
python src/camera.py
```

**Expected Output:**
```
Baby Monitor - Camera Test
==================================================

1. Starting camera...
   ✓ Camera started successfully

2. Capturing test frame...
   ✓ Captured frame (2456789 bytes)
   ✓ Saved to /tmp/test_frame.jpg

3. Testing video recording (5 seconds)...
   ✓ Recording started to /tmp/test_video.h264
   [... 5 second pause ...]
   ✓ Stopped recording
   ✓ Recording saved to /tmp/test_video.h264

4. Camera information:
   Resolution: 1280x720
   Framerate: 30 fps
   Status: Idle

✓ All tests passed!

5. Stopping camera...
   ✓ Camera stopped

==================================================
Camera test complete!
```

**Verification:**

```bash
# Check test files were created
ls -lh /tmp/test_frame.jpg /tmp/test_video.h264
```

**Expected:**
```
-rw-r--r-- 1 pi pi 2.4M Nov 17 11:00 /tmp/test_frame.jpg
-rw-r--r-- 1 pi pi  15M Nov 17 11:00 /tmp/test_video.h264
```

**View test image (if Pi has display):**
```bash
# View captured image
gpicview /tmp/test_frame.jpg
```

**Play test video (if Pi has display):**
```bash
# Play video with VLC
vlc /tmp/test_video.h264
```

**✅ Test Pass Criteria:**
- Camera starts without errors
- Frame is captured successfully
- Frame file size is reasonable (> 1MB)
- Video recording completes
- Video file size is reasonable (> 10MB for 5 seconds)
- Camera stops cleanly

**❌ Common Failures:**
- "Camera not started" - Camera not enabled in raspi-config
- "Permission denied" - Run as user 'pi' or check permissions
- "No camera detected" - Check physical connection

---

#### Test 2: Web Server Start

**Purpose:** Verify web server starts and responds

**Steps:**

```bash
# Ensure virtual environment is activated
source venv/bin/activate

# Start web server (this will block terminal)
python src/web_server.py
```

**Expected Output:**
```
Baby Monitor - Web Server
==================================================

Starting server...
Access the monitor at: http://raspberrypi.local:5000
Or: http://192.168.1.XXX:5000

Press Ctrl+C to stop
==================================================

INFO:werkzeug:WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.1.XXX:5000
INFO:werkzeug:Press CTRL+C to quit
INFO:werkzeug:Restarting with stat
```

**Note your Pi's IP address from the output!**

**Keep this terminal open** - the server needs to keep running

**✅ Test Pass Criteria:**
- Server starts without errors
- Shows IP addresses
- No Python exceptions or errors
- Terminal shows "Running on..." messages

**❌ Common Failures:**
- "Address already in use" - Port 5000 already taken, try: `sudo lsof -i :5000` to find process
- "Camera error" - Camera not working, go back to Test 1
- Module import errors - Check virtual environment activated

---

#### Test 3: Web Interface Access

**Purpose:** Verify web interface loads and displays video

**Equipment Needed:**
- Computer or phone on same network as Pi
- Web browser (Chrome, Firefox, Safari, Edge)

**Steps:**

**3.1 - Access Web Interface**

Open web browser and navigate to **one of these URLs:**
- `http://raspberrypi.local:5000`
- `http://192.168.1.XXX:5000` (use Pi's IP from Test 2)

**Expected Result:**
- Page loads within 2-3 seconds
- You see the web interface with title "👶 Baby Monitor"
- Purple gradient background
- Video container in center

**3.2 - Verify Video Stream**

**Expected Result:**
- Live video feed appears in video container
- Video shows what camera sees (even if it's just ceiling/desk)
- Video is smooth (30 fps)
- No lag or stuttering (on good network)
- "Loading camera..." message disappears

**3.3 - Check Status Display**

**Expected Result:**
- Green "Camera Online" indicator pulsing
- Current timestamp updating every second
- Resolution shows "1280x720"
- Frame rate shows "30 fps"
- Status shows "Streaming"

**3.4 - Test Snapshot Feature**

Click "📸 Capture Snapshot" button

**Expected Result:**
- New browser tab/window opens
- Shows a still image (JPEG) from camera
- Image is clear and properly exposed
- Image can be saved to your device

**3.5 - Test Refresh Feature**

Click "🔄 Refresh Stream" button

**Expected Result:**
- Video briefly pauses (< 1 second)
- Video resumes streaming
- No errors in browser console (F12)

**3.6 - Test on Mobile Device**

Open same URL on phone (on same WiFi):
- `http://raspberrypi.local:5000` or Pi's IP

**Expected Result:**
- Page is responsive and fits screen
- Video is centered and scaled properly
- Buttons are touch-friendly
- All features work as on desktop

**✅ Test Pass Criteria:**
- Web page loads successfully
- Video stream displays without errors
- Stream is smooth and responsive
- All buttons work
- Mobile interface is usable
- No JavaScript errors in console

**❌ Common Failures:**
- "Unable to connect" - Check Pi's IP, ensure same network
- "Connection refused" - Web server not running, check Test 2
- Video doesn't load - Check browser console (F12) for errors
- Very slow/choppy video - WiFi issues, try Ethernet
- Page loads but no video - Camera issue, check Test 1

---

#### Test 4: API Endpoint Test

**Purpose:** Verify REST API endpoints work correctly

**Equipment:** Computer with curl or browser

**4.1 - Test Status Endpoint**

```bash
# From your computer (not Pi)
curl http://raspberrypi.local:5000/api/status
```

**Expected Output:**
```json
{
  "status": "online",
  "resolution": {
    "width": 1280,
    "height": 720
  },
  "framerate": 30,
  "recording": false
}
```

**Or in browser:** Navigate to `http://raspberrypi.local:5000/api/status`

**4.2 - Test Snapshot Endpoint**

In browser: `http://raspberrypi.local:5000/api/snapshot`

**Expected Result:**
- Browser displays or downloads a JPEG image
- Image shows current camera view
- Image size is reasonable (1-3 MB)

**4.3 - Test Video Feed Endpoint**

In browser: `http://raspberrypi.local:5000/video_feed`

**Expected Result:**
- Browser shows continuous video stream
- Stream is MJPEG format
- Can see individual frames updating

**✅ Test Pass Criteria:**
- All endpoints return data
- Status JSON is properly formatted
- Snapshot returns valid JPEG
- Video feed streams continuously

---

#### Test 5: Performance Test

**Purpose:** Verify system performance under load

**5.1 - Monitor CPU Usage**

Open second SSH session to Pi:

```bash
ssh pi@raspberrypi.local

# Monitor system resources
htop
```

**Expected Results while streaming:**
- CPU usage: 25-40%
- Memory usage: < 50% (< 2GB on 4GB Pi)
- No swap usage
- Load average: < 1.0

**5.2 - Check Temperature**

```bash
# Check Pi temperature
vcgencmd measure_temp
```

**Expected Result:**
- Temperature: 45-65°C under normal load
- Warning if > 70°C (consider cooling)
- Throttling if > 80°C

**5.3 - Test Multiple Viewers**

Open web interface on 3 different devices simultaneously

**Expected Results:**
- All three can view stream
- No significant performance degradation
- CPU usage may increase to 40-50%
- Stream remains smooth on all devices

**5.4 - Long-Running Test**

Let server run for 1 hour with continuous viewing

**Expected Results:**
- No memory leaks (memory usage stays stable)
- No disconnections
- Video quality remains constant
- No error messages in terminal
- Pi temperature stable

**✅ Test Pass Criteria:**
- CPU usage acceptable (< 50%)
- Temperature manageable (< 70°C)
- Multiple viewers work
- System stable over time
- No memory leaks

---

#### Test 6: Network Performance Test

**Purpose:** Measure streaming latency and quality

**6.1 - Latency Test**

1. Point camera at clock or stopwatch
2. Compare time shown in stream to real time
3. Measure delay

**Expected Result:**
- Latency: 200-400ms (acceptable for monitoring)
- Consistent (doesn't vary much)

**6.2 - WiFi vs Ethernet**

Test streaming quality on both:

**WiFi:**
- Should work on 5GHz network
- May be choppy on 2.4GHz with weak signal
- Latency: 250-500ms

**Ethernet:**
- Smooth, consistent stream
- Lower latency: 150-250ms
- Preferred for production use

**6.3 - Distance Test**

Move viewing device around house

**Expected Results:**
- Works anywhere on same network
- Quality depends on WiFi signal strength
- May need WiFi extender for large homes

---

### Expected Results Summary

**Phase 1 Success Criteria:**

✅ **Camera Functionality:**
- Camera captures 720p video at 30fps
- Frame capture works (JPEG snapshots)
- Recording works (H.264 video)
- Camera starts and stops cleanly

✅ **Web Server:**
- Server starts without errors
- Serves web interface
- Provides video stream
- API endpoints respond

✅ **Web Interface:**
- Page loads on all devices
- Video stream displays
- Controls work (snapshot, refresh)
- Responsive design on mobile

✅ **Performance:**
- CPU usage < 50%
- Temperature < 70°C
- Stable over 1+ hours
- Supports 3+ concurrent viewers

✅ **Network:**
- Works on local network
- Latency acceptable (< 500ms)
- Works over WiFi and Ethernet

---

### Troubleshooting

#### Camera Issues

**Problem:** "Camera not started" or "No camera detected"

**Solutions:**
1. Check camera cable connection
2. Enable camera: `sudo raspi-config` > Interface Options > Camera
3. Reboot: `sudo reboot`
4. Verify: `libcamera-hello --list-cameras`

**Problem:** Poor image quality or wrong colors

**Solutions:**
1. Check lens is clean
2. Adjust exposure in `camera.py`
3. Ensure adequate lighting
4. Check camera focus (Camera Module 3 is fixed-focus)

---

#### Web Server Issues

**Problem:** "Address already in use"

**Solutions:**
```bash
# Find process using port 5000
sudo lsof -i :5000

# Kill process
sudo kill <PID>

# Or restart Pi
sudo reboot
```

**Problem:** Can't access from other devices

**Solutions:**
1. Check firewall:
   ```bash
   sudo ufw allow 5000/tcp
   # Or disable temporarily:
   sudo ufw disable
   ```

2. Verify Pi's IP:
   ```bash
   hostname -I
   ```

3. Ensure same network (WiFi SSID)

4. Try IP instead of hostname:
   `http://192.168.1.XXX:5000`

---

#### Performance Issues

**Problem:** High CPU usage or temperature

**Solutions:**
1. Add heatsink to Pi
2. Use fan for active cooling
3. Reduce resolution to 640x480:
   ```python
   camera = CameraManager(resolution=(640, 480), framerate=30)
   ```
4. Close other applications

**Problem:** Choppy video

**Solutions:**
1. Use Ethernet instead of WiFi
2. Improve WiFi signal (move closer to router)
3. Reduce resolution
4. Check network bandwidth:
   ```bash
   # Install speedtest
   pip install speedtest-cli
   # Run test
   speedtest-cli
   ```

---

#### Browser Issues

**Problem:** Video doesn't display

**Solutions:**
1. Check browser console (F12) for errors
2. Try different browser
3. Clear browser cache
4. Try incognito/private mode
5. Check if video_feed endpoint works:
   `http://raspberrypi.local:5000/video_feed`

**Problem:** Buttons don't work

**Solutions:**
1. Check browser console for JavaScript errors
2. Ensure page fully loaded
3. Try hard refresh (Ctrl+Shift+R)

---

### Test Log Template

Use this template to record your test results:

```
========================================
BABY MONITOR TEST LOG
========================================

Date: [DATE]
Tester: [YOUR NAME]
Pi Model: Raspberry Pi 4 [4GB/8GB]
Camera: Camera Module 3
Network: [WiFi/Ethernet]

PHASE 1 TESTS:

Test 1: Camera Module Test
Status: [PASS/FAIL]
Notes:

Test 2: Web Server Start
Status: [PASS/FAIL]
Server URL: http://[IP]:5000
Notes:

Test 3: Web Interface Access
Status: [PASS/FAIL]
Devices Tested: [Desktop/Mobile/Tablet]
Notes:

Test 4: API Endpoint Test
Status: [PASS/FAIL]
Notes:

Test 5: Performance Test
Status: [PASS/FAIL]
CPU Usage: [%]
Temperature: [°C]
Notes:

Test 6: Network Performance Test
Status: [PASS/FAIL]
Latency: [ms]
Network Type: [WiFi/Ethernet]
Notes:

OVERALL RESULT: [PASS/FAIL]

ISSUES ENCOUNTERED:
1.
2.

NOTES:
-

========================================
```

---

## Phase 2: Audio + WebRTC

*Tests for Phase 2 will be added here once implemented*

### Coming Soon:
- Audio capture test
- Speaker playback test
- Two-way audio test
- WebRTC connection test
- Latency comparison (MJPEG vs WebRTC)
- Lullaby playback test

---

## Phase 3: Environmental Sensors

*Tests for Phase 3 will be added here once implemented*

---

**Last Updated:** 2025-11-17
**Current Phase:** Phase 1
**Document Version:** 1.0
