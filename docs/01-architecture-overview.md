# Architecture Overview

## System Architecture

The baby monitor system consists of four major components that work together to provide video monitoring, environmental sensing, AI detection, and cloud connectivity.

```
┌─────────────────────────────────────────────────────────────────────┐
│                          BABY MONITOR DEVICE                         │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Hardware Layer                                              │  │
│  │  ┌────────┐ ┌─────────┐ ┌───────┐ ┌────────┐ ┌──────────┐  │  │
│  │  │ Camera │ │ Sensors │ │ Audio │ │  NPU   │ │ Storage  │  │  │
│  │  │ (4K)   │ │ (Env)   │ │ (I/O) │ │  (AI)  │ │ (eMMC)   │  │  │
│  │  └───┬────┘ └────┬────┘ └───┬───┘ └───┬────┘ └────┬─────┘  │  │
│  └──────┼───────────┼──────────┼─────────┼───────────┼────────┘  │
│         │           │          │         │           │            │
│  ┌──────┴───────────┴──────────┴─────────┴───────────┴────────┐  │
│  │  Firmware Application (C/C++ for production)               │  │
│  │  ┌──────────┐ ┌───────────┐ ┌─────────┐ ┌──────────────┐  │  │
│  │  │  Video   │ │  Sensor   │ │  Audio  │ │      AI      │  │  │
│  │  │ Pipeline │ │  Manager  │ │ Manager │ │   Inference  │  │  │
│  │  └─────┬────┘ └─────┬─────┘ └────┬────┘ └──────┬───────┘  │  │
│  │        │            │            │             │           │  │
│  │  ┌─────┴────────────┴────────────┴─────────────┴────────┐  │  │
│  │  │           Device Communication Layer                  │  │  │
│  │  │  ┌──────────┐ ┌──────────────┐ ┌─────────────────┐   │  │  │
│  │  │  │   MQTT   │ │  WebSockets  │ │   HTTP/REST     │   │  │  │
│  │  │  │(Sensors) │ │   (WebRTC)   │ │ (Upload/Config) │   │  │  │
│  │  │  └──────────┘ └──────────────┘ └─────────────────┘   │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └─────────────────────────────────────────────────────────────┘  │
└─────────────────────────┬───────────────────────────────────────────┘
                          │
                          │ Internet
                          │
         ┌────────────────┴────────────────┐
         │                                 │
┌────────┴──────────┐            ┌─────────┴────────────┐
│  CLOUD BACKEND    │            │   CLIENT APPS        │
│  (Self-Hosted)    │            │   (Flutter)          │
├───────────────────┤            ├──────────────────────┤
│ ┌───────────────┐ │            │ ┌──────────────────┐ │
│ │   FastAPI     │ │◄──────────►│ │   Mobile App     │ │
│ │   Backend     │ │   HTTPS    │ │   (iOS/Android)  │ │
│ └───────┬───────┘ │            │ └──────────────────┘ │
│         │         │            │ ┌──────────────────┐ │
│ ┌───────┴───────┐ │            │ │   Web App        │ │
│ │  PostgreSQL   │ │            │ │   (PWA)          │ │
│ │  (Primary)    │ │            │ └──────────────────┘ │
│ └───────────────┘ │            └──────────────────────┘
│ ┌───────────────┐ │
│ │  TimescaleDB  │ │
│ │ (Time-series) │ │
│ └───────────────┘ │
│ ┌───────────────┐ │
│ │     MinIO     │ │
│ │ (Object Store)│ │
│ └───────────────┘ │
│ ┌───────────────┐ │
│ │     Redis     │ │
│ │   (Cache)     │ │
│ └───────────────┘ │
│ ┌───────────────┐ │
│ │   Mosquitto   │ │
│ │ (MQTT Broker) │ │
│ └───────────────┘ │
│ ┌───────────────┐ │
│ │    CoTURN     │ │
│ │ (TURN Server) │ │
│ └───────────────┘ │
└───────────────────┘
```

## Component Breakdown

### 1. Device (Baby Monitor Hardware)

**Responsibility:** Capture video/audio/sensor data, perform on-device AI, stream to users, store locally

**Key Subsystems:**

#### Video Pipeline
- Capture video from camera (720p for Core, 4K for Pro)
- Encode using H.265 (hardware encoder)
- Implement variable bitrate based on activity
- Store locally with rolling buffer (24-72 hours)
- Stream via WebRTC for live viewing
- Upload events to cloud storage

#### Sensor Management
- Poll environmental sensors (temperature, humidity, air quality, light, vibration)
- Collect readings every 30 seconds
- Publish to MQTT broker
- Store locally in SQLite
- Detect threshold violations

#### Audio System
- Capture microphone input
- Detect sound levels (dB threshold)
- Stream audio alongside video
- Receive and play audio from client (two-way talk)
- Play lullabies/white noise

#### AI Inference (Pro Model Only)
- Person detection using NPU
- Cry classification
- Sleep position monitoring (pose estimation)
- Activity state tracking
- Run inference every 2-3 seconds (not every frame)

#### Local Storage
- SQLite database for configuration and state
- eMMC storage for video files
- File rotation to maintain storage limits
- Event markers linked to video files

#### Communication Layer
- MQTT: Sensor data, device status, events
- WebSockets: WebRTC signaling, real-time control
- HTTP/REST: Video upload, configuration sync, OTA updates

### 2. Cloud Backend (Self-Hosted)

**Responsibility:** User management, device management, cloud storage, subscription management, remote access coordination

**Services:**

#### FastAPI Backend
- REST API for client applications
- User authentication (Firebase Auth integration)
- Device registration and pairing
- Subscription tier management
- Video metadata storage
- Event history

#### PostgreSQL (Primary Database)
- Users and authentication
- Devices and settings
- Subscriptions
- Video metadata
- Event logs
- Shared data across families

#### TimescaleDB (Time-Series Database)
- Sensor readings (high-volume writes)
- Device metrics
- Performance analytics
- Compressed historical data

#### MinIO (Object Storage)
- Video file storage (S3-compatible)
- Thumbnail storage
- Firmware update packages
- User-saved moments

#### Redis
- Session management
- Real-time device presence
- WebRTC room state
- Caching frequently accessed data

#### Mosquitto (MQTT Broker)
- Device-to-cloud messaging
- Pub/sub for sensor data
- Device status updates
- Command distribution

#### CoTURN (TURN Server)
- WebRTC NAT traversal
- ~20% of connections require relay
- Self-hosted to control costs

#### Monitoring Stack (Optional)
- Prometheus: Metrics collection
- Grafana: Visualization
- AlertManager: Alerting

### 3. Client Applications (Flutter)

**Responsibility:** User interface for monitoring, configuration, and control

**Features:**

#### Live Viewing
- WebRTC video stream
- Low latency (<200ms)
- Audio streaming
- Two-way audio control

#### Playback
- HLS streaming for recorded footage
- Timeline scrubber
- Event markers
- Download/save moments

#### Dashboard
- Real-time sensor data
- Device status
- Storage usage
- Battery level

#### Settings
- Device configuration
- Alert preferences
- Subscription management
- Privacy settings (E2E encryption toggle)

#### Notifications
- Push notifications via Firebase Cloud Messaging
- Motion/sound/AI event alerts
- Device offline alerts

**Platforms:**
- iOS (native app via Flutter)
- Android (native app via Flutter)
- Web (PWA via Flutter Web)

### 4. Firebase Services (Managed)

**Responsibility:** Authentication and push notifications

**Services Used:**
- Firebase Authentication: User login/registration (free)
- Firebase Cloud Messaging: Push notifications (free)

**Note:** Firebase is only used for these two services. All other data is self-hosted.

## Data Flow Diagrams

### Live Video Streaming

```
Device                    TURN Server              Client App
  │                            │                        │
  │ 1. Connect to WebSocket    │                        │
  ├───────────────────────────────────────────────────►│
  │                            │                        │
  │ 2. WebRTC Offer            │                        │
  │◄───────────────────────────────────────────────────┤
  │                            │                        │
  │ 3. ICE Candidates          │                        │
  ├───────────────────────────────────────────────────►│
  │◄───────────────────────────────────────────────────┤
  │                            │                        │
  │ 4. Attempt P2P Connection  │                        │
  ├────────────────────────────────────────────────────┤
  │    (Success 80% of time)   │                        │
  │                            │                        │
  │ 5. Video Stream (P2P)      │                        │
  ├────────────────────────────────────────────────────┤
  │                            │                        │
  │     OR (if P2P fails)      │                        │
  │                            │                        │
  │ 6. Relay via TURN          │                        │
  ├───────────────────────────►│                        │
  │                            ├───────────────────────►│
  │◄───────────────────────────┤◄───────────────────────┤
```

### Sensor Data Flow

```
Device Sensors    Device Firmware    MQTT Broker    Backend API    TimescaleDB
      │                  │                 │              │              │
      │ 1. Read sensors  │                 │              │              │
      ├─────────────────►│                 │              │              │
      │   (every 30s)    │                 │              │              │
      │                  │ 2. Publish      │              │              │
      │                  ├────────────────►│              │              │
      │                  │  (MQTT topic)   │              │              │
      │                  │                 │ 3. Subscribe │              │
      │                  │                 ├─────────────►│              │
      │                  │                 │              │ 4. Insert    │
      │                  │                 │              ├─────────────►│
      │                  │                 │              │              │
      │                  │                 │              │ 5. Check     │
      │                  │                 │              │   thresholds │
      │                  │                 │              │              │
      │                  │                 │ 6. Push      │              │
      │                  │                 │   notification│             │
      │                  │                 │   (if alert) │              │
```

### Video Upload (Event-Based)

```
Device            Backend API       MinIO           PostgreSQL
  │                    │              │                  │
  │ 1. Detect motion   │              │                  │
  │    or sound event  │              │                  │
  │                    │              │                  │
  │ 2. Extract clip    │              │                  │
  │    (30s before +   │              │                  │
  │     2min after)    │              │                  │
  │                    │              │                  │
  │ 3. POST /upload    │              │                  │
  ├───────────────────►│              │                  │
  │                    │ 4. Get signed│                  │
  │                    │    upload URL│                  │
  │                    ├─────────────►│                  │
  │                    │◄─────────────┤                  │
  │ 5. Upload directly │              │                  │
  │    to MinIO        │              │                  │
  ├────────────────────────────────────►                  │
  │                    │              │                  │
  │ 6. Confirm upload  │              │                  │
  ├───────────────────►│              │                  │
  │                    │ 7. Save metadata               │
  │                    ├───────────────────────────────►│
  │                    │              │                  │
  │ 8. Notify user     │              │                  │
  │    (push)          │              │                  │
```

## Network Architecture

### Prototype/Development (Up to 50 users)

```
┌─────────────────────────────────────┐
│     Home Office / Dev Environment    │
│                                      │
│  ┌────────────────────────────────┐ │
│  │    Mini PC / Desktop           │ │
│  │                                │ │
│  │  Docker Containers:            │ │
│  │  - FastAPI                     │ │
│  │  - PostgreSQL + TimescaleDB    │ │
│  │  - MinIO                       │ │
│  │  - Redis                       │ │
│  │  - Mosquitto                   │ │
│  │  - CoTURN                      │ │
│  └────────────────────────────────┘ │
│                                      │
│  Home Internet (100+ Mbps)           │
│  + Cloudflare Tunnel for HTTPS       │
└──────────────┬───────────────────────┘
               │
               │ Internet
               │
        Public Access via
        Cloudflare Tunnel
```

### Production (500-1,000 users)

```
┌──────────────────────────────────────────┐
│         Colocation / Datacenter           │
│                                           │
│  ┌─────────────────────────────────────┐ │
│  │   Dell R730 (Primary Server)        │ │
│  │   - FastAPI (4 workers)             │ │
│  │   - PostgreSQL Primary              │ │
│  │   - TimescaleDB Primary             │ │
│  │   - MinIO (distributed)             │ │
│  │   - Redis                           │ │
│  │   - Mosquitto                       │ │
│  │   - CoTURN                          │ │
│  │   - HAProxy (load balancer)         │ │
│  └─────────────────────────────────────┘ │
│                                           │
│  Static IP + 10TB Bandwidth              │
│  Redundant Power                         │
└──────────────┬────────────────────────────┘
               │
               │ Internet
               │
         Cloudflare
         (DDoS Protection
          + DNS)
```

### Large Scale (5,000+ users)

```
┌───────────────────────────────────────────────┐
│          Colocation / Datacenter              │
│                                                │
│  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Server 1         │  │ Server 2         │  │
│  │ (Compute)        │  │ (Compute)        │  │
│  │ - FastAPI (4x)   │  │ - FastAPI (4x)   │  │
│  │ - PostgreSQL     │  │ - PostgreSQL     │  │
│  │   Primary        │  │   Replica        │  │
│  │ - Redis (node 1) │  │ - Redis (node 2) │  │
│  └──────────────────┘  └──────────────────┘  │
│           │                     │              │
│           └──────────┬──────────┘              │
│                      │                         │
│            ┌─────────┴──────────┐              │
│            │   HAProxy          │              │
│            │   (Floating IP)    │              │
│            └────────────────────┘              │
│                      │                         │
│            ┌─────────┴──────────┐              │
│            │ Server 3           │              │
│            │ (Storage)          │              │
│            │ - MinIO (200TB)    │              │
│            │ - CoTURN           │              │
│            │ - Backups          │              │
│            └────────────────────┘              │
│                                                │
│  Half-Rack, Redundant Power, 10Gbps Network   │
└────────────────────┬───────────────────────────┘
                     │
                     │ Internet
                     │
              Cloudflare CDN
              + DDoS Protection
```

## Security Layers

### 1. Transport Security
- All communications over TLS 1.3
- Certificate pinning for device-to-cloud
- HTTPS for all REST APIs
- WebRTC uses DTLS/SRTP (encrypted by default)

### 2. Authentication
- Users: Firebase Authentication (OAuth2, JWT)
- Devices: Registration flow with unique device ID + token
- API requests: Bearer token authentication
- MQTT: Username/password per device

### 3. Authorization
- Row-level security in PostgreSQL
- API middleware validates user owns device
- Subscription tier enforcement via feature flags
- Rate limiting to prevent abuse

### 4. Data Encryption

**In-Transit:**
- Always encrypted (TLS, DTLS, SRTP)

**At-Rest:**
- Database: Encrypted filesystem (LUKS)
- Object storage: AES-256 (server-side)
- Optional E2E: User-controlled encryption keys

**End-to-End (Optional):**
- User enables in settings
- Videos encrypted with user's key before upload
- Backend cannot decrypt
- Key stored in user's device/browser
- Trade-off: No support access, no AI training

### 5. Device Security
- Secure boot (production firmware)
- Read-only root filesystem
- Signed firmware updates (OTA)
- Automatic security patches
- Fail-safe rollback on bad updates

## Scalability Considerations

### Horizontal Scaling

**Backend API:**
- Stateless design (session in Redis)
- Multiple FastAPI workers
- Load balanced via HAProxy
- Can add servers as needed

**Database:**
- PostgreSQL primary-replica setup
- Read queries to replicas
- Write queries to primary
- Connection pooling (PgBouncer)

**Object Storage:**
- MinIO distributed mode (erasure coding)
- Scales across multiple servers
- Automatic replication

**MQTT:**
- Mosquitto can cluster
- Or use EMQX for larger deployments

### Vertical Scaling

**Database:**
- More RAM = larger cache
- Faster SSD = better query performance
- More CPU cores = more concurrent connections

**Storage:**
- Add drives to existing servers
- Expand RAID arrays

### Caching Strategy

**Redis Caching:**
- User session data (TTL: 24 hours)
- Device online status (TTL: 2 minutes)
- Frequently accessed device settings (TTL: 1 hour)
- API response cache for expensive queries (TTL: 5 minutes)

**Database Query Optimization:**
- Indexed columns: user_id, device_id, timestamp
- Partitioning for time-series data (monthly partitions)
- Materialized views for analytics

## Disaster Recovery

### Backup Strategy

**Databases:**
- Automated daily backups (pg_dump)
- Continuous WAL archiving
- Retention: 30 days
- Offsite backup to Backblaze B2

**Object Storage (Videos):**
- MinIO erasure coding provides redundancy
- Critical videos: User-saved moments backed up
- Event videos: 30-day retention, then purged
- Full backup not feasible (too large)

**Configuration:**
- Docker Compose files in Git
- Configuration files backed up daily
- Infrastructure-as-code approach

### Recovery Procedures

**Database Failure:**
1. Promote replica to primary (if using replication)
2. Or restore from latest backup
3. Recovery Time Objective (RTO): 1 hour
4. Recovery Point Objective (RPO): 24 hours

**Server Failure:**
1. Provision new server
2. Restore from backups
3. Update DNS
4. RTO: 4 hours

**Complete Datacenter Failure:**
1. Provision new infrastructure
2. Restore all services from backups
3. RTO: 24 hours
4. Note: Live video unavailable during outage (acceptable)

## Performance Targets

### Response Times
- API requests: <100ms (95th percentile)
- Database queries: <50ms (95th percentile)
- Video stream startup: <2 seconds
- WebRTC connection: <5 seconds
- Page load: <1 second

### Throughput
- API: 1,000 requests/second per server
- Database: 10,000 queries/second
- Video uploads: 100 concurrent uploads
- Concurrent streams: 500 per server

### Resource Usage
- CPU: <70% average utilization
- Memory: <80% utilization
- Disk I/O: <80% capacity
- Network: <70% bandwidth utilization

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
