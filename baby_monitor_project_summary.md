# Baby Monitor Development Project - Handoff Summary

## Project Overview

**Goal:** Develop a premium baby monitoring system with two product tiers featuring video monitoring, environmental sensing, AI detection, and cloud connectivity.

**Timeline:** 12-16 weeks for thorough prototype development

**Developer:** Solo development (David) with clear documentation for future collaborators

---

## Product Specifications

### Core Model - $99 (Production Target)
- **Video:** 720p camera
- **Storage:** 32GB eMMC (24 hours of recording)
- **Sensors:** Temperature and humidity only (BME280)
- **Processing:** ESP32-S3 or similar (cloud-dependent for AI)
- **Audio:** Mono speaker, basic microphone
- **Battery:** 500-1000mAh (shutdown protection only)
- **Connectivity:** WiFi + Bluetooth
- **Power:** USB-C charging with magnetic battery connector
- **Manufacturing Cost:** $32-40 per unit

### Pro Model - $299 (Production Target)
- **Video:** 4K camera with enhanced low-light performance
- **Storage:** 512GB eMMC (72 hours of 4K recording)
- **Sensors:** Full suite (temp, humidity, air quality, light, vibration)
- **Processing:** RK3588 or NXP i.MX 8M Plus with NPU (on-device AI)
- **Audio:** Premium stereo/high-quality speaker, better microphone array
- **Battery:** 7000mAh internal (8-10 hours operation)
- **Connectivity:** Dual-band WiFi + Bluetooth + Thread (Matter-ready)
- **Power:** USB-C charging with magnetic battery connector
- **Manufacturing Cost:** $165-185 per unit

### Extended Battery Pack (Accessory) - $79
- **Capacity:** 12,000mAh magnetic attachment
- **Runtime:** 24+ hours for Core, 34+ hours total for Pro
- **Compatible:** Both Core and Pro models
- **Manufacturing Cost:** $28-35 per unit

---

## Subscription Model (Account-Based, Not Per-Device)

### Free Tier (Included with Device)
- Local network streaming (unlimited)
- On-device storage (24-72 hours based on model)
- On-device AI detection (Pro model only, when implemented)
- Push notifications (unlimited)
- Remote viewing (10 hours/month via WebRTC relay)
- Two-way audio
- Environmental monitoring
- **Your Cost:** ~$0.50-1/month per device

### Cloud Storage Plan - $9.99/month ($99.99/year)
- 30-day cloud video storage
- Unlimited remote viewing
- 100GB saved recordings library
- Multi-device viewing/sharing
- Download/export capabilities
- **Your Cost:** $5-7/month per account

### AI Insights Plan - $9.99/month ($99.99/year)
- Advanced pattern analysis
- Sleep quality scoring
- Developmental milestone tracking
- Breathing monitoring via AI
- Unusual event detection
- Weekly reports and insights
- **Your Cost:** $5-8/month per account

### Complete Plan - $17.99/month ($179.99/year)
- All Cloud Storage features
- All AI Insights features
- Priority support
- Early access to new features
- **Your Cost:** $13-15/month per account

**Key Design Principle:** Device MUST work without subscription. Subscriptions add convenience and advanced features, never gate core functionality.

---

## Prototype Development Strategy

### Phase 1: Raspberry Pi 4 Prototype (Weeks 1-8)
**Hardware:**
- Raspberry Pi 4 (4GB) - Already owned
- Camera Module 3 (1080p capable, testing for 720p/1080p)
- BME680 sensor (temp/humidity/pressure/air quality)
- BH1750 light sensor
- ADXL345 accelerometer
- USB audio adapter + speaker
- Standard development setup

**Focus:** Core functionality without AI
- Video streaming and recording
- Environmental sensor integration
- Two-way audio
- Local storage management
- Basic motion/sound detection (non-AI)
- PWA interface development
- Cloud integration (Firebase + GCS)

**Goals:**
- Prove core concept
- Validate user experience
- Test hardware integration
- Build foundational software architecture

### Phase 2: Raspberry Pi 5 + AI Kit (Weeks 9-12)
**Hardware Upgrade:**
- Raspberry Pi 5
- Raspberry Pi AI Kit ($70) with Hailo-8L (13 TOPS)
- Migrate all sensors and components

**Focus:** AI feature implementation
- Person detection
- Cry detection and classification
- Sleep position monitoring
- Activity pattern logging
- On-device AI inference
- Performance optimization

**Goals:**
- Validate AI features work on edge hardware
- Measure power consumption with AI
- Test user value of AI features
- Determine cloud vs. edge AI split for production

### Phase 3: Production Hardware Evaluation (Weeks 13-16)
**Hardware:**
- ESP32-S3 dev board (Core model testing)
- RK3588 or i.MX 8M Plus dev board (Pro model testing)

**Focus:** Production readiness
- Port software to production processors
- Validate performance at target specs
- Measure power consumption
- Test thermal management
- Prepare for PCB design

---

## Technical Architecture

### Technology Stack

**Device Software (All Python):**
- **OS:** Raspberry Pi OS (64-bit, latest)
- **Language:** Python 3.9+
- **Video:** picamera2, libcamera, opencv-python, ffmpeg
- **Sensors:** smbus2, adafruit-circuitpython-bme680, adafruit-circuitpython-adxl34x
- **Audio:** pyaudio, pydub, pygame
- **Web Server:** Flask (lightweight, good for prototype)
- **Real-time Communication:** python-socketio
- **AI (Phase 2):** tflite-runtime, pycoral
- **Cloud SDK:** firebase-admin, google-cloud-storage

**Backend (Cloud):**
- **Platform:** Google Cloud / Firebase
- **Authentication:** Firebase Authentication (free, unlimited users)
- **Database:** Firestore (NoSQL, real-time sync)
- **Video Storage:** Google Cloud Storage (cheaper than Firebase Storage)
- **Push Notifications:** Firebase Cloud Messaging (free, unlimited)
- **Functions:** Cloud Functions (for backend logic, serverless)
- **AI Processing (optional):** Google Cloud Vision API (free tier for prototype)

**Frontend (Progressive Web App):**
- **Framework:** Vanilla HTML/CSS/JS initially (simplest)
- **Future:** React or Vue.js if complexity grows
- **Later Migration:** Flutter for native mobile apps (post-prototype)

**Development Tools:**
- **IDE:** VS Code with Remote SSH extension
- **Version Control:** Git + GitHub
- **Device Access:** SSH, remote development on Pi
- **Testing:** Browser for web interface, mobile device for mobile testing

### Video Streaming Architecture

**Phase 1 (Weeks 1-4): RTSP Streaming**
- Simple RTSP server on device
- Good for initial testing and recorded playback
- Higher latency (~500ms) but easy to implement
- Fallback option

**Phase 2 (Weeks 5-8): WebRTC Streaming**
- Low latency (<200ms) for live viewing
- Works for remote access (NAT traversal)
- More complex but better user experience
- Requires STUN/TURN server setup
- **Both RTSP and WebRTC will coexist** (RTSP for playback, WebRTC for live)

**Remote Access:**
- WebRTC for peer-to-peer (zero cost when possible)
- TURN relay server for NAT traversal (limited free tier: 10hrs/month for free users)
- Unlimited for subscribers

### Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Baby Monitor Device                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │  Camera  │  │ Sensors  │  │   Audio  │  │   AI    │ │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘ │
│       │             │              │             │       │
│       └─────────────┴──────────────┴─────────────┘       │
│                         │                                │
│              ┌──────────┴──────────┐                     │
│              │  Python Application │                     │
│              │   (Flask Server)    │                     │
│              └──────────┬──────────┘                     │
│                         │                                │
│         ┌───────────────┼───────────────┐                │
│         │               │               │                │
│    ┌────▼────┐    ┌────▼────┐    ┌─────▼─────┐          │
│    │ Local   │    │ WebRTC  │    │ Firebase  │          │
│    │ Storage │    │ Stream  │    │   SDK     │          │
│    └─────────┘    └─────────┘    └───────────┘          │
└─────────────────────────────────────────────────────────┘
                           │
              ─────────────┼─────────────
                  Internet │
              ─────────────┼─────────────
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │
   ┌────▼──────┐                      ┌──────▼────────┐
   │  Firebase │                      │    Google     │
   │           │                      │     Cloud     │
   │  - Auth   │                      │    Storage    │
   │  - DB     │                      │               │
   │  - FCM    │                      │  (Videos)     │
   └─────┬─────┘                      └───────────────┘
         │
         │
   ┌─────▼─────────────────────────┐
   │   Progressive Web App (PWA)   │
   │                               │
   │  - Live Video View            │
   │  - Recorded Playback          │
   │  - Sensor Dashboard           │
   │  - Settings & Controls        │
   │  - Two-way Audio              │
   └───────────────────────────────┘
```

### Storage Strategy

**Local Storage (On-Device):**
- Continuous recording to SD card/eMMC
- Rolling buffer (keep last 24-72 hours based on model)
- Efficient file rotation to prevent storage exhaustion
- Automatic cleanup of old files

**Cloud Storage (Optional, for subscribers):**
- **Smart Upload Strategy:** Only upload motion/sound events + keyframes (not continuous)
- Typical: 8-12 hours of "important" footage per day vs 24 hours continuous
- Reduces storage to ~2-3GB/day vs 15-20GB for continuous
- H.265 compression for efficiency
- Event-based retention (7-30 days based on subscription tier)

**Saved Moments (User-flagged):**
- Separate storage bucket
- 100GB limit for Cloud Storage tier
- User can download/export
- Never auto-deleted

### AI Implementation Strategy

**Prototype Phase 1 (No AI - Weeks 1-8):**
- Basic motion detection (OpenCV frame differencing)
- Sound level detection (amplitude threshold)
- Sensor threshold alerts

**Prototype Phase 2 (Edge AI - Weeks 9-12):**
- Hailo-8L NPU via Raspberry Pi 5 AI Kit
- Pre-trained models:
  - Person detection (MobileNet SSD)
  - Pose estimation (for sleep position)
  - Audio classification (for cry detection)
- Test inference speed, accuracy, power consumption

**Production (Hybrid Approach):**
- **On-Device (Free):** Basic detection (cry, motion, presence)
- **Cloud (Subscription):** Advanced analytics (patterns, insights, predictions)
- **Rationale:** Privacy for core features, advanced AI drives subscription value

---

## Development Phases - Detailed Breakdown

### Weeks 1-2: Setup & Basic Video

**Week 1 Goals:**
- ✓ Raspberry Pi 4 setup with latest OS
- ✓ Camera Module 3 connected and working
- ✓ Python environment configured
- ✓ Git repository initialized
- ✓ VS Code Remote SSH working
- ✓ Capture 1080p test video

**Week 1 Deliverables:**
- Development environment fully operational
- Can capture and save video to file
- Basic Python scripts for camera control
- Documentation: Setup instructions

**Week 2 Goals:**
- ✓ RTSP streaming server implemented
- ✓ Can view stream in VLC from another computer
- ✓ Basic web interface (HTML/JS) to display stream
- ✓ mDNS/Bonjour for device discovery
- ✓ Test on mobile browser (same WiFi)

**Week 2 Deliverables:**
- Local network streaming working
- Simple web page to view live feed
- Can access from phone on same network
- Documentation: Streaming architecture

**Key Technologies:**
- `picamera2` for camera control
- `ffmpeg` for RTSP streaming
- `avahi` for mDNS device discovery
- Flask for simple web server

---

### Weeks 3-4: Sensors & Storage

**Week 3 Goals:**
- ✓ All sensors connected (BME680, BH1750, ADXL345)
- ✓ I2C communication working
- ✓ Reading data from all sensors simultaneously
- ✓ Data logging to CSV/JSON
- ✓ Simple dashboard showing sensor readings

**Week 3 Deliverables:**
- All environmental sensors operational
- Real-time sensor data display on web interface
- Historical data logging
- Documentation: Sensor wiring, I2C addresses

**Week 4 Goals:**
- ✓ Continuous video recording to SD card
- ✓ File rotation system (keep last 24 hours)
- ✓ Storage monitoring and alerts
- ✓ Video playback interface
- ✓ Timeline scrubber for recorded footage

**Week 4 Deliverables:**
- Recording system with automatic cleanup
- Can review past 24 hours of footage
- Storage doesn't fill up (rotation works)
- Playback interface functional
- Documentation: Storage architecture

**Key Technologies:**
- Adafruit CircuitPython libraries for sensors
- Custom file rotation logic
- HTML5 video player for playback

---

### Weeks 5-6: Audio & WebRTC

**Week 5 Goals:**
- ✓ USB audio adapter working (mic + speaker)
- ✓ Can record and play back audio
- ✓ Two-way audio over local network
- ✓ Audio quality acceptable for baby monitoring
- ✓ Lullaby/white noise playback

**Week 5 Deliverables:**
- Two-way audio communication working
- Talk-back feature from web interface
- Audio streaming alongside video
- Simple lullaby player
- Documentation: Audio setup

**Week 6 Goals:**
- ✓ WebRTC implementation for live streaming
- ✓ Lower latency than RTSP (<200ms)
- ✓ Works on local network
- ✓ STUN server configured for remote access
- ✓ Both RTSP and WebRTC available

**Week 6 Deliverables:**
- Low-latency live streaming via WebRTC
- Remote access working (test from cellular)
- Automatic fallback to RTSP if WebRTC fails
- Documentation: WebRTC architecture, TURN setup

**Key Technologies:**
- `pyaudio` for audio I/O
- `aiortc` or similar for WebRTC in Python
- Public STUN servers (Google, etc.)
- Consider CoTURN for TURN server (can run on cloud)

---

### Weeks 7-8: Integration & Cloud Setup

**Week 7 Goals:**
- ✓ All components integrated into single application
- ✓ Modular architecture (video, audio, sensors, storage as modules)
- ✓ Configuration file system
- ✓ Systemd service for auto-start
- ✓ 48+ hour stability test
- ✓ Error handling and recovery

**Week 7 Deliverables:**
- Single Python application running all features
- Starts automatically on boot
- Stable multi-day operation
- Graceful error handling
- Documentation: Application architecture

**Week 8 Goals:**
- ✓ Firebase project created
- ✓ Authentication implemented (email/password)
- ✓ User registration and login working
- ✓ Device pairing/registration system
- ✓ Firestore database schema designed
- ✓ Basic cloud storage upload (test files)

**Week 8 Deliverables:**
- Users can create accounts
- Devices can be paired to user accounts
- Cloud backend operational
- Push notifications working
- Documentation: Cloud architecture, database schema

**Key Technologies:**
- Firebase Admin SDK for Python
- `google-cloud-storage` for GCS
- Firebase Authentication
- Firestore for user/device data

**Milestone:** End of Week 8 = **Functional prototype** with core features, no AI

---

### Weeks 9-10: Hardware Upgrade & AI Implementation

**Week 9 Goals:**
- ✓ Raspberry Pi 5 acquired
- ✓ AI Kit (Hailo-8L) installed
- ✓ All sensors and camera migrated to Pi 5
- ✓ Software ported and tested on Pi 5
- ✓ AI runtime and libraries installed
- ✓ Test inference with sample models

**Week 9 Deliverables:**
- Pi 5 fully operational with all hardware
- Hailo AI accelerator working
- Software running on new platform
- Baseline performance measurements
- Documentation: Pi 5 migration notes

**Week 10 Goals:**
- ✓ Person detection model deployed
- ✓ Baby presence/absence detection
- ✓ Cry detection (audio classification)
- ✓ Real-time inference (<100ms)
- ✓ AI alerts integrated with notification system
- ✓ Power consumption with AI measured

**Week 10 Deliverables:**
- Person detection working accurately
- Cry detection functional
- AI-powered alerts sent to users
- Performance metrics documented
- Documentation: AI models, inference pipeline

**Key Technologies:**
- Raspberry Pi AI Kit / Hailo
- Pre-trained TFLite models
- Custom audio classification model (or pre-trained)

---

### Weeks 11-12: Advanced Features & Cloud AI

**Week 11 Goals:**
- ✓ Pose estimation for sleep position monitoring
- ✓ Activity tracking (awake/asleep detection)
- ✓ Pattern logging for analysis
- ✓ Event timeline with AI annotations
- ✓ False positive rate optimization

**Week 11 Deliverables:**
- Sleep position monitoring
- Activity state tracking
- AI event history in timeline
- Acceptable accuracy (>90%, <5% false positives)
- Documentation: AI features, accuracy metrics

**Week 12 Goals:**
- ✓ Cloud AI integration (Google Cloud Vision API)
- ✓ Smart video upload (events only)
- ✓ Cloud storage working for subscribers
- ✓ Subscription tier management
- ✓ Feature flags (enable/disable based on subscription)
- ✓ Remote access finalized

**Week 12 Deliverables:**
- Cloud storage operational
- Subscription tiers enforced
- Remote viewing from anywhere
- Smart upload reducing bandwidth
- Documentation: Cloud integration, subscription management

**Milestone:** End of Week 12 = **Complete prototype** with all planned features

---

### Weeks 13-16: Polish, Testing & Production Planning

**Week 13-14: UI/UX Polish**
- ✓ Mobile-responsive design improvements
- ✓ User testing with real parents (if possible)
- ✓ Feedback incorporation
- ✓ Performance optimization
- ✓ Battery life testing
- ✓ Bug fixes

**Week 15-16: Production Prep**
- ✓ Order production dev boards (ESP32-S3, RK3588)
- ✓ Port software to production processors
- ✓ Create detailed BOM
- ✓ Document power requirements
- ✓ Thermal testing
- ✓ Prepare for PCB design phase

**Deliverables:**
- Polished prototype ready for demonstration
- User feedback documented
- Production hardware validated
- Ready to engage PCB designer
- Complete documentation

---

## Hardware Shopping List

### Phase 1: Raspberry Pi 4 Prototype (Order Immediately)

**Core Components (~$178):**
- [ ] Raspberry Pi 4 (4GB) - $55 (Already owned)
- [ ] Raspberry Pi Camera Module 3 - $25
- [ ] Official Pi USB-C Power Supply (5V/3A) - $10
- [ ] 128GB microSD Card (A2 rated, UHS-I) - $15

**Sensors (~$38):**
- [ ] BME680 Breakout Board - $20
- [ ] BH1750 Light Sensor - $8
- [ ] ADXL345 Accelerometer - $10

**Audio (~$25):**
- [ ] USB Audio Adapter with Microphone - $15
- [ ] Small Speaker (3-5W) - $10

**Prototyping (~$10):**
- [ ] Half-size Breadboard - $5
- [ ] Male-Female Jumper Wires (40pc) - $5

**Optional (~$12):**
- [ ] Raspberry Pi Case - $12

**Total Phase 1: $250-263**

### Phase 2: Raspberry Pi 5 + AI (Order Week 7-8)

**Hardware (~$180):**
- [ ] Raspberry Pi 5 (4GB or 8GB) - $60-80
- [ ] Raspberry Pi AI Kit (Hailo-8L) - $70
- [ ] Active cooler for Pi 5 (recommended) - $5
- [ ] USB-C power supply (27W for Pi 5) - $12
- [ ] Transfer all sensors and components from Phase 1

**Total Phase 2: ~$150-180**

### Phase 3: Production Hardware Eval (Order Week 12-13)

**Dev Boards (~$170-220):**
- [ ] ESP32-S3 DevKit - $20
- [ ] RK3588 or i.MX 8M Plus dev board - $150-200

**Total Phase 3: ~$170-220**

**Grand Total Hardware Investment: $570-663**

---

## Cloud Service Costs (Prototype Phase)

### Free Tiers (Target: Stay within these)

**Firebase (Google):**
- Authentication: Unlimited users FREE
- Firestore: 50K reads, 20K writes per day FREE
- Cloud Messaging: Unlimited FREE
- Hosting: 10GB storage, 360MB/day transfer FREE

**Google Cloud Storage:**
- 5GB storage FREE
- 1GB network egress/month FREE
- For prototype: Likely stay under limits

**Google Cloud Vision API:**
- 1,000 units/month FREE
- For testing AI features before on-device implementation

**WebRTC TURN Server:**
- Use free public STUN servers
- TURN: Self-host on GCP free tier VM, or use metered service
- Metered cost: ~$0.50/GB relay traffic

**Expected Monthly Cost for Prototype:** $0-20
- Most months: $0 (within free tiers)
- Heavy testing months: $10-20 (if exceed free storage/bandwidth)

---

## Key Software Architecture Decisions

### Device Application Structure

```
baby_monitor/
├── main.py                 # Entry point, starts all services
├── config.py               # Configuration management
├── requirements.txt        # Python dependencies
│
├── core/
│   ├── camera.py          # Camera control, recording
│   ├── sensors.py         # I2C sensor reading
│   ├── audio.py           # Audio I/O, two-way communication
│   ├── storage.py         # Local storage management, rotation
│   └── detection.py       # Basic motion/sound detection (non-AI)
│
├── streaming/
│   ├── rtsp_server.py     # RTSP streaming
│   ├── webrtc_server.py   # WebRTC peer connection
│   └── stream_manager.py  # Manages both streams
│
├── ai/ (Phase 2)
│   ├── inference.py       # Hailo AI inference engine
│   ├── person_detector.py # Person detection model
│   ├── cry_detector.py    # Cry detection model
│   └── pose_estimator.py  # Sleep position monitoring
│
├── cloud/
│   ├── firebase_client.py # Firebase SDK wrapper
│   ├── storage_client.py  # GCS upload management
│   ├── auth.py            # Device authentication
│   └── sync.py            # Cloud sync logic
│
├── web/
│   ├── app.py             # Flask web server
│   ├── api.py             # REST API endpoints
│   ├── socketio_events.py # Real-time events
│   │
│   └── static/
│       ├── index.html     # PWA main page
│       ├── css/
│       ├── js/
│       └── manifest.json  # PWA manifest
│
└── utils/
    ├── logger.py          # Logging configuration
    ├── notifications.py   # Push notification sender
    └── helpers.py         # Common utilities
```

### Database Schema (Firestore)

```
/users/{userId}
  - email
  - displayName
  - createdAt
  - subscription: "free" | "storage" | "ai" | "complete"
  - subscriptionExpiry

/devices/{deviceId}
  - ownerId (ref to user)
  - name
  - model: "core" | "pro"
  - createdAt
  - lastSeen
  - firmwareVersion
  - settings: {
      motionSensitivity,
      soundThreshold,
      nightVisionEnabled,
      ...
    }

/devices/{deviceId}/events/{eventId}
  - type: "motion" | "sound" | "cry" | "person_detected"
  - timestamp
  - thumbnailUrl (GCS)
  - videoUrl (GCS, if cloud subscriber)
  - aiConfidence (if AI event)
  - metadata: {...}

/devices/{deviceId}/sensorData/{timestamp}
  - temperature
  - humidity
  - lightLevel
  - airQuality
  - vibration

/devices/{deviceId}/patterns (AI-generated, for subscribers)
  - sleepSchedule
  - cryingPatterns
  - activityLevels
  - insights
```

### REST API Endpoints

**Authentication:**
- `POST /api/auth/register` - Create user account
- `POST /api/auth/login` - Login, get token
- `POST /api/auth/logout` - Logout

**Device Management:**
- `POST /api/devices/pair` - Pair device to user account
- `GET /api/devices` - List user's devices
- `GET /api/devices/{id}` - Get device details
- `PUT /api/devices/{id}/settings` - Update device settings
- `DELETE /api/devices/{id}` - Unpair device

**Video & Events:**
- `GET /api/devices/{id}/stream` - Get stream URL (WebRTC offer)
- `GET /api/devices/{id}/events` - List events (paginated)
- `GET /api/devices/{id}/events/{eventId}` - Get specific event
- `POST /api/devices/{id}/events/{eventId}/save` - Save to cloud

**Sensors:**
- `GET /api/devices/{id}/sensors/current` - Current sensor readings
- `GET /api/devices/{id}/sensors/history` - Historical data (time range)

**Subscription:**
- `POST /api/subscription/create` - Create subscription (Stripe integration)
- `GET /api/subscription/status` - Check subscription status
- `POST /api/subscription/cancel` - Cancel subscription

### WebSocket Events (Real-time)

**Client → Server:**
- `connect` - Authenticate and join device room
- `request_stream` - Request live video stream
- `send_audio` - Send audio data (talk-back)
- `update_settings` - Update device settings in real-time

**Server → Client:**
- `sensor_update` - Real-time sensor data
- `event_detected` - Motion/sound/AI event
- `stream_ready` - Stream available
- `audio_data` - Receive audio from device
- `device_status` - Online/offline status

---

## Development Workflow

### Daily Development Process

1. **VS Code Remote SSH to Pi**
   - Open project folder directly on Pi
   - Edit files as if local

2. **Make Changes**
   - Edit Python files
   - Test immediately (code runs on Pi)

3. **Test Locally**
   - Access web interface from browser: `http://raspberrypi.local:5000`
   - Test on mobile device (same WiFi)

4. **Commit & Push**
   - Git commits on Pi
   - Push to GitHub for backup

5. **Deploy to Test Device**
   - For now, Pi IS the test device
   - Later: Deploy to second Pi for isolated testing

### Testing Strategy

**Unit Testing:**
- pytest for Python unit tests
- Test each module independently
- Mock hardware when needed (for CI/CD later)

**Integration Testing:**
- Test full workflows end-to-end
- Real hardware required

**User Testing:**
- Week 8: First round with completed core features
- Week 12: Second round with AI features
- Gather feedback from parents if possible

**Performance Testing:**
- Monitor CPU/memory usage
- Measure streaming latency
- Test concurrent users
- Battery life measurements (Phase 2)

---

## Known Challenges & Solutions

### Challenge 1: WebRTC Complexity
**Problem:** WebRTC is complex, especially NAT traversal
**Solution:**
- Start with RTSP (simple, works)
- Add WebRTC in Phase 2 (weeks 5-6)
- Use existing libraries (aiortc)
- Public STUN servers available
- CoTURN for TURN server (self-host or use service)

### Challenge 2: Video Storage Costs
**Problem:** Cloud storage expensive at scale
**Solution:**
- Smart upload strategy (events only, not continuous)
- H.265 compression (50% smaller than H.264)
- Local-first architecture (most video stays on device)
- Subscription required for cloud storage

### Challenge 3: AI Model Accuracy
**Problem:** Pre-trained models may not work well for babies
**Solution:**
- Start with general person detection (works fine)
- Fine-tune cry detection with baby cry datasets
- Iterate based on user feedback
- Cloud AI for advanced features (can update models easily)

### Challenge 4: Power Consumption
**Problem:** Always-on camera/AI drains battery
**Solution:**
- Duty cycling (reduce frame rate when quiet)
- Motion-triggered full recording
- AI runs intermittently (every 2-3 seconds, not every frame)
- USB-C power primary, battery is backup

### Challenge 5: Network Reliability
**Problem:** WiFi dropout = lost monitoring
**Solution:**
- Local recording continues even if internet down
- Auto-reconnect logic
- Status notifications when offline
- Local network streaming always works

---

## Success Metrics

### Prototype Success Criteria (End of Week 12)

**Functionality:**
- [ ] 1080p video streaming with <200ms latency (local network)
- [ ] Remote access working from cellular network
- [ ] All sensors reading accurate data
- [ ] Two-way audio with acceptable quality
- [ ] 24+ hours continuous operation without crashes
- [ ] Motion and cry detection with >90% accuracy, <5% false positives
- [ ] Cloud storage working for subscribers
- [ ] Push notifications delivered within 5 seconds

**User Experience:**
- [ ] Setup process <10 minutes for non-technical user
- [ ] Mobile interface intuitive and responsive
- [ ] Video quality acceptable for monitoring
- [ ] Audio clear enough to hear baby

**Technical:**
- [ ] Code well-organized and documented
- [ ] Can demonstrate to potential investors/users
- [ ] Ready to port to production hardware
- [ ] Clear path to manufacturing

---

## Next Steps After Prototype

### Production Transition (Post Week 16)

1. **PCB Design (4-8 weeks)**
   - Hire PCB designer
   - Two designs (Core and Pro)
   - BOM finalized
   - Design reviews and revisions

2. **Prototype PCBs (2-4 weeks)**
   - Order 10-25 assembled boards
   - Hand assembly if needed
   - Software bring-up on custom hardware
   - Test and debug

3. **Certifications (12-16 weeks)**
   - FCC (required for US sales)
   - CE (if selling in Europe)
   - Safety testing (UL/CSA)
   - Can start during PCB design

4. **Industrial Design (8-12 weeks, parallel)**
   - Housing design
   - Magnetic connector design
   - Injection mold tooling

5. **Manufacturing Setup (4-8 weeks)**
   - Select contract manufacturer
   - First production run (100-500 units)
   - Quality control processes

6. **Market Launch (Ongoing)**
   - Crowdfunding campaign? (Kickstarter/Indiegogo)
   - Pre-orders
   - Marketing materials
   - Customer support setup

---

## Critical Reminders for Development Team

### 1. Local-First Architecture
**The device MUST work without internet or subscription.**
- Local streaming always available
- Local storage always recording
- Basic detection always functional
- Cloud is enhancement, not requirement

### 2. Privacy by Design
- Encryption for all cloud communications
- Local processing preferred for sensitive data
- Clear user consent for cloud features
- Option to disable cloud entirely

### 3. Battery & Power Management
- Graceful shutdown on power loss
- Battery status monitoring
- Low-power modes when appropriate
- USB-C power delivery support

### 4. Subscription Ethics
- Never break existing functionality to force upgrades
- Clear value proposition for each tier
- Annual discount (17% off) to encourage commitment
- Account-based (not per-device) to support multi-child families

### 5. Code Quality
- Document as you go
- Clear variable names
- Modular architecture (easy to test/replace components)
- Error handling everywhere
- Logging for debugging

### 6. User Experience
- Setup must be dead simple
- App must be fast and responsive
- Errors should be helpful, not cryptic
- Parents are tired and stressed - make it easy

---

## Resource Links

### Documentation & Tutorials
- **Raspberry Pi:** https://www.raspberrypi.com/documentation/
- **Camera Module 3:** https://www.raspberrypi.com/products/camera-module-3/
- **Adafruit Learning:** https://learn.adafruit.com
- **Firebase Docs:** https://firebase.google.com/docs
- **OpenCV Tutorials:** https://docs.opencv.org/master/
- **WebRTC:** https://webrtc.org/getting-started/overview

### Community Support
- **Raspberry Pi Forums:** https://forums.raspberrypi.com
- **Reddit:** r/raspberry_pi, r/homeautomation, r/IOT
- **Stack Overflow:** For specific coding questions

### Tools & Services
- **VS Code:** https://code.visualstudio.com
- **Firebase Console:** https://console.firebase.google.com
- **Google Cloud Console:** https://console.cloud.google.com
- **GitHub:** For version control

---

## Contact & Collaboration

**Project Lead:** David
**Development Location:** Home office (suburban house)
**Hardware:** Mini-PCs, Raspberry Pis available for testing
**Timeline:** 12-16 weeks for complete prototype
**Budget:** ~$600-700 for prototype hardware, cloud services on free tier

**Collaboration Model:**
- Solo development initially
- Clear documentation for future team members
- GitHub for code sharing
- Consider contractors for specific tasks (PCB design, mobile app polish)

---

## Final Notes

This is an ambitious but achievable project. The phased approach allows for learning and iteration:

- **Phase 1 (Pi 4):** Prove the concept, build foundation
- **Phase 2 (Pi 5 + AI):** Add intelligence, test advanced features
- **Phase 3 (Production HW):** Validate manufacturing approach

The key to success is:
1. **Start simple** - Get basic features working before adding complexity
2. **Test early and often** - Real hardware, real use cases
3. **Document everything** - Future you will thank present you
4. **Iterate based on feedback** - Users will teach you what matters

**You're building something that helps parents sleep better at night. That's meaningful work.**

Good luck! 🍼📹🤖
