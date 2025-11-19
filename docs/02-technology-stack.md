# Technology Stack

This document details every technology used in the baby monitor project, including version requirements, justifications, and alternatives considered.

## Device Firmware

### Prototype Phase (Raspberry Pi)

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Raspberry Pi OS** | 64-bit (Bookworm) | Operating system | Official OS, excellent hardware support |
| **Python** | 3.11+ | Primary language | Rapid development, extensive libraries |
| **picamera2** | Latest | Camera interface | Official Pi camera library, best performance |
| **libcamera** | Latest | Low-level camera | Modern camera stack for Pi |
| **opencv-python** | 4.8+ | Computer vision | Motion detection, image processing |
| **ffmpeg** | 5.0+ | Video encoding | H.265 encoding, format conversion |
| **asyncio** | Built-in | Async framework | Handle concurrent I/O efficiently |
| **pyaudio** | Latest | Audio I/O | Microphone and speaker access |
| **pydub** | Latest | Audio processing | Sound level detection, manipulation |
| **smbus2** | Latest | I2C communication | Sensor communication |
| **adafruit-circuitpython-bme680** | Latest | Env sensor | Temperature, humidity, air quality |
| **adafruit-circuitpython-adxl34x** | Latest | Accelerometer | Motion/vibration detection |
| **aiortc** | 1.5+ | WebRTC | Video streaming, low latency |
| **Flask-SocketIO** | 5.3+ | WebSocket server | Real-time communication |
| **paho-mqtt** | 1.6+ | MQTT client | Sensor data publishing |
| **aiosqlite** | Latest | Local database | Async SQLite access |
| **httpx** | Latest | HTTP client | Async API requests |

**Alternative Considered:**
- **Node.js** for firmware: Rejected due to higher memory usage and less suitable for embedded systems

### Production Phase (RV1126/RK3588)

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Buildroot/Yocto** | Latest LTS | Build system | Embedded Linux build framework |
| **C/C++** | C++17 | Primary language | Performance, hardware access, industry standard |
| **Rockchip MPP** | Latest | Video encoding | Hardware-accelerated H.265 encoding |
| **RKNN Toolkit** | Latest | NPU inference | Rockchip Neural Network runtime |
| **V4L2** | Kernel | Camera interface | Video4Linux2, standard for Linux cameras |
| **ALSA** | Kernel | Audio interface | Advanced Linux Sound Architecture |
| **libcurl** | Latest | HTTP client | API requests, file uploads |
| **libmosquitto** | 2.0+ | MQTT client | Sensor data publishing (C library) |
| **SQLite** | 3.40+ | Local database | Embedded database, zero-config |
| **JSON for Modern C++** (nlohmann) | 3.11+ | JSON parsing | Header-only, easy to use |
| **spdlog** | Latest | Logging | Fast C++ logging library |
| **WebRTC native** | Latest | Video streaming | Google's WebRTC implementation |

**Migration Path:**
1. Prototype in Python on Raspberry Pi
2. Port core functionality to C/C++ on dev boards
3. Use Rockchip SDK examples as foundation
4. Wrap C++ components with Python initially (hybrid approach)
5. Full C/C++ for production firmware

**Alternative Considered:**
- **Rust**: Modern, safe, but less ecosystem support for Rockchip hardware
- **Go**: Good middle ground, but larger binaries and not standard for embedded

## Backend Services

### Core Backend

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **FastAPI** | 0.104+ | Web framework | Fast, modern, async, auto-docs |
| **Python** | 3.11+ | Backend language | Team familiarity, rapid development |
| **uvicorn** | Latest | ASGI server | High-performance async server |
| **PostgreSQL** | 15+ | Primary database | Robust, feature-rich, proven |
| **TimescaleDB** | 2.12+ | Time-series extension | Optimized for sensor data |
| **asyncpg** | Latest | Async PostgreSQL driver | Best async Postgres performance |
| **SQLAlchemy** | 2.0+ | ORM | Database abstraction, migrations |
| **Alembic** | Latest | Database migrations | Version control for schema |
| **Pydantic** | 2.0+ | Data validation | Type-safe models, validation |
| **python-jose** | Latest | JWT handling | Token creation/validation |
| **passlib** | Latest | Password hashing | bcrypt for secure passwords |
| **Firebase Admin SDK** | Latest | Auth integration | Firebase Authentication backend |

**Alternative Considered:**
- **Django**: Too heavyweight, REST-focused vs FastAPI's async capability
- **Flask**: Simpler but lacks async support, FastAPI has better performance
- **Go (Fiber/Gin)**: Faster but team less familiar, Python easier for solo dev

### Storage & Caching

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **MinIO** | Latest | Object storage | S3-compatible, self-hostable |
| **Redis** | 7.0+ | Cache & sessions | In-memory speed, pub/sub for real-time |
| **redis-py** | Latest | Redis client | Async Redis for Python |

**Alternative Considered:**
- **Google Cloud Storage**: Expensive at scale, vendor lock-in
- **Memcached**: Less features than Redis, no pub/sub
- **Ceph**: Too complex for our scale

### Message Broker

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Mosquitto** | 2.0+ | MQTT broker | Lightweight, proven for IoT |
| **paho-mqtt** | Latest | MQTT Python client | Official Eclipse Paho library |

**Alternative Considered:**
- **EMQX**: More features, overkill for our initial scale
- **RabbitMQ**: More complex, MQTT not primary protocol
- **AWS IoT Core**: Expensive, vendor lock-in

### WebRTC Infrastructure

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **CoTURN** | Latest | TURN server | Self-hosted, NAT traversal |
| **Public STUN servers** | N/A | STUN (ICE) | Google/Mozilla free STUN servers |

**Alternative Considered:**
- **Twilio**: $0.50-1/GB, too expensive at scale
- **Agora**: Managed solution, less control
- **Janus Gateway**: More complex than needed

### Monitoring & Observability

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Prometheus** | Latest | Metrics collection | Industry standard, powerful |
| **Grafana** | Latest | Visualization | Beautiful dashboards, Prometheus integration |
| **AlertManager** | Latest | Alerting | Prometheus alerting component |
| **prometheus-client** | Latest | Python metrics exporter | Expose FastAPI metrics |
| **node-exporter** | Latest | System metrics | CPU, memory, disk metrics |

**Alternative Considered:**
- **Datadog**: $15/host/month, expensive for self-hosted approach
- **New Relic**: Similar cost issues
- **InfluxDB + Telegraf**: Good, but Prometheus is more popular

## Frontend (Mobile & Web)

### Mobile Application

| Technology | Version | Purpose | Justification |
|------------|---------|---------|---------------|
| **Flutter** | 3.16+ | UI framework | Team familiarity, single codebase |
| **Dart** | 3.2+ | Programming language | Required for Flutter |
| **flutter_webrtc** | Latest | WebRTC client | Video streaming in Flutter |
| **mqtt_client** | Latest | MQTT client | Real-time sensor updates |
| **http** | Latest | HTTP client | REST API calls |
| **web_socket_channel** | Latest | WebSocket client | Real-time events |
| **provider** | Latest | State management | Simple, scalable state management |
| **fl_chart** | Latest | Charts & graphs | Sensor data visualization |
| **video_player** | Latest | HLS playback | Recorded video playback |
| **firebase_auth** | Latest | Authentication | Firebase Auth integration |
| **firebase_messaging** | Latest | Push notifications | FCM for notifications |
| **flutter_secure_storage** | Latest | Secure storage | Store auth tokens, encryption keys |
| **shared_preferences** | Latest | User preferences | Settings persistence |

**Alternative Considered:**
- **React Native**: Larger ecosystem but team unfamiliar
- **Native (Swift + Kotlin)**: 2× development effort
- **Ionic**: Web-based, performance concerns

### Web Application (PWA)

Built using Flutter Web - same codebase as mobile apps.

**Progressive Web App Features:**
- Service worker for offline support
- Web app manifest for "Add to Home Screen"
- Responsive design (mobile and desktop)

**Alternative Considered:**
- **React**: Separate codebase from mobile
- **Vue.js**: Same issue, double the work
- **Vanilla JS**: Too much to build from scratch

## External Services (Managed)

### Authentication

| Service | Cost | Purpose | Justification |
|---------|------|---------|---------------|
| **Firebase Authentication** | Free | User auth | Free, unlimited users, proven |

**Alternative Considered:**
- **Auth0**: $23/month + per-user fees
- **Supabase Auth**: Free, but less mature
- **Roll our own**: Security risk, time-consuming

### Push Notifications

| Service | Cost | Purpose | Justification |
|---------|------|---------|---------------|
| **Firebase Cloud Messaging** | Free | Push notifications | Free, unlimited, cross-platform |

**Alternative Considered:**
- **OneSignal**: Free tier limited, then $9/month
- **Pusher**: Expensive at scale
- **Amazon SNS**: More complex, AWS lock-in

### Email (Transactional)

| Service | Cost | Purpose | Justification |
|---------|------|---------|---------------|
| **SendGrid** | Free (100/day), then $20/month | Password resets, alerts | Reliable, generous free tier |

**Alternative Considered:**
- **Mailgun**: Similar pricing
- **Amazon SES**: Cheaper but more complex
- **Self-hosted SMTP**: Deliverability issues

### Payment Processing

| Service | Cost | Purpose | Justification |
|---------|------|---------|---------------|
| **Stripe** | 2.9% + $0.30 per transaction | Payments & subscriptions | Industry standard, excellent API |

**Alternative Considered:**
- **PayPal**: Higher fees, worse developer experience
- **Square**: Limited subscription features
- **Paddle**: Merchant of record, higher fees

### Backups

| Service | Cost | Purpose | Justification |
|---------|------|---------|---------------|
| **Backblaze B2** | $0.006/GB/month | Offsite backups | Cheapest cloud storage |

**Alternative Considered:**
- **AWS S3 Glacier**: More expensive
- **Wasabi**: Cheaper but less reliable
- **Local backups only**: Risky (fire, theft)

## Development Tools

### Version Control

| Tool | Purpose | Justification |
|------|---------|---------------|
| **Git** | Version control | Industry standard |
| **GitHub** | Code hosting | Free for private repos, excellent CI/CD |
| **GitHub Actions** | CI/CD | Integrated, generous free tier |

### Development Environment

| Tool | Purpose | Justification |
|------|---------|---------------|
| **VS Code** | IDE | Free, excellent extensions, Remote SSH |
| **Remote - SSH** (extension) | Remote development | Develop directly on Pi/servers |
| **Docker** | Containerization | Consistent environments, easy deployment |
| **Docker Compose** | Multi-container orchestration | Local development stack |
| **Postman** / **Insomnia** | API testing | Test REST APIs during development |

### Testing

| Tool | Purpose | Justification |
|------|---------|---------------|
| **pytest** | Python unit tests | Standard Python testing framework |
| **pytest-asyncio** | Async test support | Test async FastAPI code |
| **pytest-cov** | Code coverage | Measure test coverage |
| **Flutter test** | Flutter unit/widget tests | Built into Flutter SDK |

### Documentation

| Tool | Purpose | Justification |
|------|---------|---------------|
| **Markdown** | Documentation format | Simple, version-controllable |
| **MkDocs** (optional) | Documentation site | Generate docs from markdown |
| **FastAPI auto-docs** | API documentation | Built-in Swagger/OpenAPI docs |
| **Mermaid** | Diagrams in markdown | Diagrams as code |

### Build Tools

**Firmware:**
- **CMake**: C/C++ build system
- **Make**: Traditional build tool
- **GCC/G++**: C/C++ compiler for ARM
- **Cross-compilation toolchain**: Build ARM binaries on x86

**Backend:**
- **Poetry** (optional): Python dependency management
- **pip**: Python package installer
- **Docker**: Build container images

**Mobile:**
- **Flutter SDK**: Build mobile/web apps
- **Android Studio**: Android builds & emulator
- **Xcode**: iOS builds (requires Mac)

## Infrastructure Software

### Operating Systems

| Environment | OS | Justification |
|-------------|-----|---------------|
| **Device (prototype)** | Raspberry Pi OS (64-bit) | Official, best hardware support |
| **Device (production)** | Custom Buildroot/Yocto Linux | Minimal, optimized for embedded |
| **Servers** | Ubuntu Server 22.04 LTS | Stable, 5-year support, familiar |

### Containerization

| Technology | Purpose | Justification |
|------------|---------|---------------|
| **Docker** | Containerization | Standard, portable |
| **Docker Compose** | Local orchestration | Simple multi-container apps |
| **Docker Swarm** (optional) | Production orchestration | Built into Docker, simpler than K8s |

**Alternative Considered:**
- **Kubernetes**: Too complex for our scale
- **Nomad**: Less ecosystem support
- **Bare metal**: Docker provides better isolation and deployment

### Reverse Proxy / Load Balancer

| Technology | Purpose | Justification |
|------------|---------|---------------|
| **HAProxy** | Load balancing | High performance, proven |
| **Nginx** | Reverse proxy, static files | Versatile, efficient |
| **Cloudflare** | DNS, DDoS protection | Free tier, excellent performance |

### SSL/TLS

| Technology | Purpose | Justification |
|------------|---------|---------------|
| **Let's Encrypt** | Free SSL certificates | Automated, trusted CA |
| **Certbot** | Certificate management | Official Let's Encrypt client |
| **Cloudflare** | Certificate proxy | Alternative to Let's Encrypt |

### Networking

| Technology | Purpose | Justification |
|------------|---------|---------------|
| **Cloudflare Tunnel** (dev) | HTTPS without port forwarding | Free, secure, no static IP needed |
| **Tailscale** (alternative) | Mesh VPN | Easy remote access for management |
| **UFW** | Firewall | Simple Ubuntu firewall |

## Version Requirements Summary

### Critical Version Dependencies

**Must Match:**
- Python: 3.11+ (backend and prototype firmware)
- PostgreSQL: 15+ (required for TimescaleDB 2.12+)
- Flutter: 3.16+ (latest stable features)
- Docker: 20.10+ (for Docker Compose features)

**Can Be Flexible:**
- Redis: 6.0+ works, 7.0+ preferred
- MinIO: Rolling release, always use latest
- Mosquitto: 1.6+ works, 2.0+ preferred

### Update Policy

**Security Updates:**
- Apply immediately for critical vulnerabilities
- Test in dev environment first
- Backend services: Update monthly
- Device firmware: Update quarterly (via OTA)

**Feature Updates:**
- Evaluate new features quarterly
- Update during maintenance windows
- Maintain compatibility with older clients

## Technology Decision Log

### Why Self-Hosted Infrastructure?

**Decision:** Self-host backend, storage, and services

**Reasons:**
1. Cost: 70-80% cheaper than cloud at scale
2. Control: Own the infrastructure, no vendor lock-in
3. Privacy: Sensitive baby video data stays under our control
4. Learning: Team develops DevOps skills
5. Flexibility: Can optimize for our specific use case

**Trade-offs:**
- More maintenance burden
- Need to handle scaling ourselves
- Responsible for uptime and backups

### Why Python for Backend?

**Decision:** Use Python (FastAPI) for backend API

**Reasons:**
1. Team familiarity: Faster development
2. Async support: Handle many concurrent connections
3. Rich ecosystem: Libraries for everything
4. Type hints: Pydantic for validation
5. Auto-documentation: FastAPI generates OpenAPI docs

**Trade-offs:**
- Slower than Go/Rust (but fast enough with async)
- Higher memory usage (but manageable with caching)

### Why C/C++ for Production Firmware?

**Decision:** Migrate from Python to C/C++ for production devices

**Reasons:**
1. Performance: Critical for 4K video encoding
2. Memory: Lower footprint for embedded systems
3. Battery: More efficient = longer battery life
4. Hardware access: Rockchip SDKs are C/C++
5. Industry standard: Embedded systems are almost always C/C++

**Trade-offs:**
- Longer development time
- More complex debugging
- Steeper learning curve

### Why Flutter Over React Native?

**Decision:** Use Flutter for mobile/web apps

**Reasons:**
1. Team familiarity: Already know Flutter
2. Single codebase: Mobile + web from one code
3. Performance: Compiled to native code
4. UI quality: Beautiful, smooth animations
5. Hot reload: Fast development iteration

**Trade-offs:**
- Larger app size (~20MB vs ~10MB)
- Dart less common than JavaScript
- Slightly smaller ecosystem (but growing)

### Why PostgreSQL Over NoSQL?

**Decision:** Use PostgreSQL as primary database

**Reasons:**
1. ACID compliance: Data consistency matters
2. Relations: Users → Devices → Events have clear relationships
3. Mature: Proven, stable, well-documented
4. Flexible: JSON columns when needed (JSONB)
5. TimescaleDB: Extension for time-series data

**Trade-offs:**
- Vertical scaling harder than some NoSQL (but we can replicate)
- Schema migrations required (vs schemaless)

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
