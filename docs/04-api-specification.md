# API Specification

This document defines all API endpoints, WebSocket events, and MQTT topics for the baby monitor system.

## API Overview

The system uses three communication protocols:

1. **REST API (HTTP/HTTPS):** User/device management, configuration, video uploads
2. **WebSockets:** Real-time events, WebRTC signaling
3. **MQTT:** Sensor data, device status, lightweight messaging

**Base URLs:**
- REST API: `https://api.babymonitor.example.com/v1`
- WebSocket: `wss://api.babymonitor.example.com/ws`
- MQTT: `mqtt://mqtt.babymonitor.example.com:1883` (TLS: 8883)

---

## Authentication

### User Authentication

**Method:** Bearer token (JWT from Firebase)

**Headers:**
```http
Authorization: Bearer <firebase_id_token>
```

**Token Validation:**
1. Client authenticates with Firebase
2. Client receives Firebase ID token
3. Client sends token in Authorization header
4. Backend validates token with Firebase Admin SDK
5. Backend extracts `firebase_uid` and loads user from database

**Token Expiration:** 1 hour (Firebase default)
**Refresh:** Client must refresh token using Firebase SDK

### Device Authentication

**Method:** Device-specific API key

**Headers:**
```http
X-Device-ID: <device_id>
X-Device-Token: <device_token>
```

**Device Registration Flow:**
1. Device generates unique `device_id` (based on MAC address)
2. Device displays 6-digit pairing code
3. User enters code in mobile app
4. App calls `POST /devices/pair` with code
5. Backend validates code, issues `device_token`
6. Device stores token for future requests

---

## REST API Endpoints

### Authentication Endpoints

#### Register User

```http
POST /auth/register
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "securepassword",
    "display_name": "John Doe"
}
```

**Response (201 Created):**
```json
{
    "user": {
        "id": "uuid",
        "email": "user@example.com",
        "display_name": "John Doe",
        "firebase_uid": "firebase_uid_string"
    },
    "firebase_token": "firebase_id_token"
}
```

**Note:** This is a convenience wrapper around Firebase Auth. Can also register directly with Firebase client SDK.

---

#### Login

```http
POST /auth/login
Content-Type: application/json

{
    "email": "user@example.com",
    "password": "securepassword"
}
```

**Response (200 OK):**
```json
{
    "firebase_token": "firebase_id_token",
    "user": {
        "id": "uuid",
        "email": "user@example.com",
        "display_name": "John Doe"
    }
}
```

---

#### Refresh Token

```http
POST /auth/refresh
Authorization: Bearer <firebase_refresh_token>
```

**Response (200 OK):**
```json
{
    "firebase_token": "new_firebase_id_token"
}
```

---

### Device Management Endpoints

#### List User's Devices

```http
GET /devices
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "devices": [
        {
            "id": "uuid",
            "device_id": "unique_device_id",
            "name": "Nursery Monitor",
            "model": "pro",
            "status": "active",
            "firmware_version": "1.0.5",
            "last_seen_at": "2025-11-17T10:30:00Z",
            "settings": {
                "motion_sensitivity": 50,
                "sound_threshold": 60,
                "night_vision_enabled": true
            },
            "features_enabled": {
                "local_streaming": true,
                "remote_viewing": true,
                "cloud_storage": true,
                "ai_detection": true
            }
        }
    ]
}
```

---

#### Get Device Details

```http
GET /devices/{device_id}
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "id": "uuid",
    "device_id": "unique_device_id",
    "name": "Nursery Monitor",
    "model": "pro",
    "status": "active",
    "firmware_version": "1.0.5",
    "paired_at": "2025-11-01T14:00:00Z",
    "last_seen_at": "2025-11-17T10:30:00Z",
    "settings": { ... },
    "features_enabled": { ... },
    "current_sensors": {
        "temperature_celsius": 21.5,
        "humidity_percent": 45,
        "air_quality_index": 25,
        "light_level_lux": 5
    }
}
```

---

#### Pair Device

```http
POST /devices/pair
Authorization: Bearer <user_token>
Content-Type: application/json

{
    "registration_code": "123456"
}
```

**Response (201 Created):**
```json
{
    "device": {
        "id": "uuid",
        "device_id": "unique_device_id",
        "name": "Baby Monitor",
        "model": "pro",
        "paired_at": "2025-11-17T10:35:00Z"
    }
}
```

**Errors:**
- 404: Invalid or expired registration code
- 409: Device already paired to another user

---

#### Unpair Device (for resale)

```http
POST /devices/{device_id}/unpair
Authorization: Bearer <user_token>
Content-Type: application/json

{
    "confirm": true,
    "delete_data": false  // Keep videos for 30 days before purge
}
```

**Response (200 OK):**
```json
{
    "message": "Device unpaired successfully",
    "data_retention_days": 30
}
```

**Notes:**
- Removes owner association
- Device can be paired to new user
- Videos marked for deletion after 30 days (grace period)
- Device generates new registration code on next boot

---

#### Update Device Settings

```http
PATCH /devices/{device_id}/settings
Authorization: Bearer <user_token>
Content-Type: application/json

{
    "name": "Nursery Monitor",
    "settings": {
        "motion_sensitivity": 75,
        "sound_threshold": 55,
        "night_vision_enabled": true,
        "alert_preferences": {
            "motion": true,
            "sound": true,
            "temperature": false
        }
    }
}
```

**Response (200 OK):**
```json
{
    "device": {
        "id": "uuid",
        "name": "Nursery Monitor",
        "settings": { ... }
    }
}
```

---

#### Delete Device

```http
DELETE /devices/{device_id}
Authorization: Bearer <user_token>
```

**Response (204 No Content)**

**Notes:**
- Unpairs device (same as unpair endpoint)
- Soft delete (can be recovered for 30 days)

---

### Events Endpoints

#### List Events

```http
GET /devices/{device_id}/events?start_time=2025-11-01T00:00:00Z&end_time=2025-11-17T23:59:59Z&type=motion&limit=50&offset=0
Authorization: Bearer <user_token>
```

**Query Parameters:**
- `start_time` (optional): ISO 8601 timestamp
- `end_time` (optional): ISO 8601 timestamp
- `type` (optional): Filter by event type (motion, sound, cry_detected, etc.)
- `limit` (optional, default 50, max 100): Results per page
- `offset` (optional, default 0): Pagination offset

**Response (200 OK):**
```json
{
    "events": [
        {
            "id": "uuid",
            "device_id": "uuid",
            "event_type": "cry_detected",
            "timestamp": "2025-11-17T10:15:30Z",
            "confidence": 0.92,
            "metadata": {
                "duration_seconds": 15,
                "cry_type": "hungry"
            },
            "video_url": "https://cdn.example.com/videos/...",
            "thumbnail_url": "https://cdn.example.com/thumbnails/...",
            "video_duration_seconds": 150,
            "viewed": false,
            "saved": false
        }
    ],
    "total": 127,
    "limit": 50,
    "offset": 0
}
```

---

#### Get Event Details

```http
GET /events/{event_id}
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "id": "uuid",
    "device_id": "uuid",
    "event_type": "cry_detected",
    "timestamp": "2025-11-17T10:15:30Z",
    "confidence": 0.92,
    "metadata": { ... },
    "video_url": "https://cdn.example.com/videos/...",
    "thumbnail_url": "https://cdn.example.com/thumbnails/...",
    "viewed": true,
    "saved": false
}
```

---

#### Mark Event as Viewed

```http
POST /events/{event_id}/view
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "event_id": "uuid",
    "viewed": true,
    "viewed_at": "2025-11-17T10:20:00Z"
}
```

---

#### Save Event (prevent deletion)

```http
POST /events/{event_id}/save
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "event_id": "uuid",
    "saved": true,
    "expires_at": null
}
```

**Notes:**
- Saved events exempt from automatic deletion
- Count toward user's storage quota (100GB for Cloud Storage tier)

---

### Video Endpoints

#### List Videos

```http
GET /devices/{device_id}/videos?start_time=...&end_time=...&type=event&limit=50
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "videos": [
        {
            "id": "uuid",
            "device_id": "uuid",
            "event_id": "uuid",
            "video_type": "event",
            "file_path": "videos/device_id/2025/11/17/video.mp4",
            "file_size_bytes": 15728640,
            "duration_seconds": 150,
            "resolution": "3840x2160",
            "codec": "h265",
            "recorded_at": "2025-11-17T10:15:00Z",
            "expires_at": "2025-12-17T10:15:00Z"
        }
    ]
}
```

---

#### Get Video Upload URL (for device)

```http
POST /videos/upload
X-Device-ID: <device_id>
X-Device-Token: <device_token>
Content-Type: application/json

{
    "event_id": "uuid",
    "file_size_bytes": 15728640,
    "duration_seconds": 150,
    "resolution": "3840x2160",
    "codec": "h265",
    "recorded_at": "2025-11-17T10:15:00Z"
}
```

**Response (200 OK):**
```json
{
    "upload_url": "https://minio.example.com/presigned-url?...",
    "video_id": "uuid",
    "expires_in_seconds": 3600
}
```

**Notes:**
- Device receives pre-signed URL for direct upload to MinIO
- Avoids proxying large files through backend
- Upload URL expires in 1 hour

---

#### Confirm Video Upload

```http
POST /videos/{video_id}/confirm
X-Device-ID: <device_id>
X-Device-Token: <device_token>
```

**Response (200 OK):**
```json
{
    "video_id": "uuid",
    "status": "uploaded",
    "thumbnail_job_queued": true
}
```

---

#### Get Video Playback URL

```http
GET /videos/{video_id}/playback
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "video_id": "uuid",
    "hls_url": "https://cdn.example.com/hls/video_id/playlist.m3u8",
    "direct_url": "https://cdn.example.com/videos/video_id.mp4",
    "expires_in_seconds": 3600
}
```

**Notes:**
- Returns pre-signed URLs (expire in 1 hour)
- HLS for adaptive bitrate playback (better UX)
- Direct URL for download

---

### Sensor Data Endpoints

#### Get Current Sensor Readings

```http
GET /devices/{device_id}/sensors/current
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "device_id": "uuid",
    "timestamp": "2025-11-17T10:30:00Z",
    "temperature_celsius": 21.5,
    "humidity_percent": 45,
    "air_quality_index": 25,
    "light_level_lux": 5,
    "vibration_detected": false
}
```

---

#### Get Sensor History

```http
GET /devices/{device_id}/sensors/history?start_time=...&end_time=...&interval=5m
Authorization: Bearer <user_token>
```

**Query Parameters:**
- `start_time`: ISO 8601 timestamp
- `end_time`: ISO 8601 timestamp
- `interval` (optional, default `5m`): Aggregation interval (1m, 5m, 15m, 1h, 1d)

**Response (200 OK):**
```json
{
    "device_id": "uuid",
    "interval": "5m",
    "data": [
        {
            "timestamp": "2025-11-17T10:00:00Z",
            "temperature_celsius": {
                "avg": 21.3,
                "min": 21.0,
                "max": 21.5
            },
            "humidity_percent": {
                "avg": 44.5,
                "min": 43,
                "max": 46
            }
        }
    ]
}
```

**Notes:**
- Data aggregated using TimescaleDB `time_bucket()`
- Returns min/max/avg for each metric
- Used for charts in mobile app

---

### Subscription Endpoints

#### Get Subscription Status

```http
GET /subscription
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "user_id": "uuid",
    "tier": "complete",
    "status": "active",
    "current_period_start": "2025-11-01T00:00:00Z",
    "current_period_end": "2025-12-01T00:00:00Z",
    "cancel_at_period_end": false
}
```

---

#### Create Subscription (Stripe Checkout)

```http
POST /subscription/checkout
Authorization: Bearer <user_token>
Content-Type: application/json

{
    "tier": "complete",
    "billing_period": "annual"  // or "monthly"
}
```

**Response (200 OK):**
```json
{
    "checkout_url": "https://checkout.stripe.com/session_id_...",
    "session_id": "stripe_session_id"
}
```

**Notes:**
- Returns Stripe Checkout URL
- User completes payment on Stripe
- Webhook updates subscription status

---

#### Cancel Subscription

```http
POST /subscription/cancel
Authorization: Bearer <user_token>
Content-Type: application/json

{
    "cancel_immediately": false  // or true for immediate cancellation
}
```

**Response (200 OK):**
```json
{
    "subscription": {
        "tier": "complete",
        "status": "active",
        "cancel_at_period_end": true,
        "ends_at": "2025-12-01T00:00:00Z"
    }
}
```

---

### Sharing Endpoints

#### Share Device

```http
POST /devices/{device_id}/share
Authorization: Bearer <user_token>
Content-Type: application/json

{
    "email": "partner@example.com",
    "permission": "view",  // "view", "control", or "admin"
    "expires_at": "2026-11-17T00:00:00Z"  // optional
}
```

**Response (201 Created):**
```json
{
    "share_id": "uuid",
    "device_id": "uuid",
    "shared_with": "partner@example.com",
    "permission": "view",
    "expires_at": "2026-11-17T00:00:00Z"
}
```

---

#### List Device Shares

```http
GET /devices/{device_id}/shares
Authorization: Bearer <user_token>
```

**Response (200 OK):**
```json
{
    "shares": [
        {
            "share_id": "uuid",
            "shared_with": {
                "user_id": "uuid",
                "email": "partner@example.com",
                "display_name": "Jane Doe"
            },
            "permission": "view",
            "created_at": "2025-11-01T00:00:00Z",
            "expires_at": null
        }
    ]
}
```

---

#### Revoke Share

```http
DELETE /devices/{device_id}/shares/{share_id}
Authorization: Bearer <user_token>
```

**Response (204 No Content)**

---

### Firmware Update Endpoints (Device)

#### Check for Updates

```http
GET /firmware/check
X-Device-ID: <device_id>
X-Device-Token: <device_token>
X-Current-Version: 1.0.5
X-Model: pro
```

**Response (200 OK) - Update Available:**
```json
{
    "update_available": true,
    "version": "1.0.6",
    "download_url": "https://cdn.example.com/firmware/pro/1.0.6/firmware.bin",
    "signature_url": "https://cdn.example.com/firmware/pro/1.0.6/firmware.sig",
    "changelog": "- Fixed camera exposure bug\n- Improved AI detection\n- Security patches",
    "mandatory": false,
    "file_size_bytes": 52428800
}
```

**Response (200 OK) - No Update:**
```json
{
    "update_available": false,
    "current_version": "1.0.5"
}
```

---

#### Report Update Status

```http
POST /firmware/update-status
X-Device-ID: <device_id>
X-Device-Token: <device_token>
Content-Type: application/json

{
    "version": "1.0.6",
    "status": "success",  // "success", "failed", "in_progress"
    "error_message": null  // or error description if failed
}
```

**Response (200 OK):**
```json
{
    "acknowledged": true
}
```

---

## WebSocket API

### Connection

```javascript
const ws = new WebSocket('wss://api.babymonitor.example.com/ws');

// Authenticate after connection
ws.send(JSON.stringify({
    type: 'auth',
    token: '<firebase_id_token>'
}));
```

### Message Format

All messages use JSON:

```json
{
    "type": "event_type",
    "payload": { ... },
    "timestamp": "2025-11-17T10:30:00Z"
}
```

---

### Client → Server Events

#### Subscribe to Device

```json
{
    "type": "subscribe_device",
    "device_id": "uuid"
}
```

#### Unsubscribe from Device

```json
{
    "type": "unsubscribe_device",
    "device_id": "uuid"
}
```

#### Request Video Stream (WebRTC)

```json
{
    "type": "stream_request",
    "device_id": "uuid",
    "offer": {
        "type": "offer",
        "sdp": "v=0\r\no=- ..."
    }
}
```

#### Send ICE Candidate

```json
{
    "type": "ice_candidate",
    "device_id": "uuid",
    "candidate": {
        "candidate": "candidate:...",
        "sdpMLineIndex": 0,
        "sdpMid": "0"
    }
}
```

#### Send Audio (Two-Way Talk)

```json
{
    "type": "audio_data",
    "device_id": "uuid",
    "audio": "<base64_encoded_audio>"
}
```

---

### Server → Client Events

#### Authentication Result

```json
{
    "type": "auth_result",
    "success": true,
    "user_id": "uuid"
}
```

#### Device Status Update

```json
{
    "type": "device_status",
    "device_id": "uuid",
    "status": "online",
    "last_seen_at": "2025-11-17T10:30:00Z"
}
```

#### Sensor Update (Real-time)

```json
{
    "type": "sensor_update",
    "device_id": "uuid",
    "sensors": {
        "temperature_celsius": 21.5,
        "humidity_percent": 45,
        "timestamp": "2025-11-17T10:30:00Z"
    }
}
```

#### Event Notification

```json
{
    "type": "event_notification",
    "event": {
        "id": "uuid",
        "device_id": "uuid",
        "event_type": "cry_detected",
        "timestamp": "2025-11-17T10:15:30Z",
        "confidence": 0.92,
        "thumbnail_url": "https://cdn.example.com/thumbnails/..."
    }
}
```

#### WebRTC Answer (from device)

```json
{
    "type": "stream_answer",
    "device_id": "uuid",
    "answer": {
        "type": "answer",
        "sdp": "v=0\r\na=..."
    }
}
```

#### ICE Candidate (from device)

```json
{
    "type": "ice_candidate",
    "device_id": "uuid",
    "candidate": { ... }
}
```

---

## MQTT Topics

### Device → Server (Publish)

#### Sensor Data

```
Topic: devices/{device_id}/sensors
QoS: 0 (at most once)
Payload (JSON):
{
    "temperature_celsius": 21.5,
    "humidity_percent": 45,
    "air_quality_index": 25,
    "light_level_lux": 5,
    "timestamp": "2025-11-17T10:30:00Z"
}
```

#### Device Status

```
Topic: devices/{device_id}/status
QoS: 1 (at least once)
Payload (JSON):
{
    "status": "online",
    "uptime_seconds": 86400,
    "cpu_usage_percent": 45.2,
    "memory_usage_percent": 60.1,
    "storage_usage_percent": 30.5,
    "battery_level_percent": 85,
    "timestamp": "2025-11-17T10:30:00Z"
}
```

#### Event Detected

```
Topic: devices/{device_id}/events
QoS: 1 (at least once)
Payload (JSON):
{
    "event_type": "motion",
    "confidence": 0.85,
    "metadata": {
        "area": "crib",
        "intensity": 0.75
    },
    "timestamp": "2025-11-17T10:15:30Z"
}
```

---

### Server → Device (Subscribe)

#### Configuration Updates

```
Topic: devices/{device_id}/config
QoS: 1 (at least once)
Payload (JSON):
{
    "settings": {
        "motion_sensitivity": 75,
        "sound_threshold": 55,
        "night_vision_enabled": true
    }
}
```

#### Commands

```
Topic: devices/{device_id}/commands
QoS: 1 (at least once)
Payload (JSON):
{
    "command": "restart",
    "args": {}
}

// or
{
    "command": "play_lullaby",
    "args": {
        "track_id": "lullaby_01",
        "volume": 50
    }
}
```

#### Firmware Update Notification

```
Topic: devices/{device_id}/firmware
QoS: 1 (at least once)
Payload (JSON):
{
    "update_available": true,
    "version": "1.0.6",
    "mandatory": false,
    "download_url": "https://cdn.example.com/firmware/..."
}
```

---

## Error Responses

All error responses follow this format:

```json
{
    "error": {
        "code": "error_code",
        "message": "Human-readable error message",
        "details": { ... }  // Optional additional context
    }
}
```

### HTTP Status Codes

| Code | Meaning | Use Case |
|------|---------|----------|
| 200 | OK | Successful request |
| 201 | Created | Resource created successfully |
| 204 | No Content | Successful request, no response body |
| 400 | Bad Request | Invalid request format |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | User doesn't have permission |
| 404 | Not Found | Resource doesn't exist |
| 409 | Conflict | Resource conflict (e.g., device already paired) |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Temporary outage |

### Common Error Codes

```
AUTH_001: Invalid or expired token
AUTH_002: User not found
AUTH_003: Permission denied

DEVICE_001: Device not found
DEVICE_002: Device already paired
DEVICE_003: Invalid registration code
DEVICE_004: Device offline

VIDEO_001: Video not found
VIDEO_002: Upload failed
VIDEO_003: Insufficient storage quota

SUB_001: Invalid subscription tier
SUB_002: Payment required
```

---

## Rate Limiting

**Per User:**
- API requests: 1000/hour
- Video uploads: 100/hour
- WebSocket connections: 10 concurrent

**Per Device:**
- Sensor publishes: Unlimited (every 30s expected)
- Event publishes: 100/hour
- Status updates: 120/hour (every 30s expected)

**Headers:**
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 995
X-RateLimit-Reset: 1637164800
```

---

## Versioning

**Current Version:** v1

**URL Format:** `/v1/endpoint`

**Version Policy:**
- Breaking changes require new version (v2, v3, etc.)
- Backward-compatible changes don't require version bump
- Old versions supported for 12 months after deprecation notice

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
