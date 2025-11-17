# Security Architecture

This document outlines the security design, threat model, and implementation details for protecting user data and system integrity.

## Security Principles

1. **Defense in Depth:** Multiple layers of security
2. **Least Privilege:** Minimal access rights by default
3. **Privacy by Design:** Data protection built into architecture
4. **Secure by Default:** Safe default settings
5. **Fail Secure:** System fails to secure state, not open state
6. **Transparency:** Clear privacy policies, user control

---

## Threat Model

### Assets to Protect

**High Value:**
- Video/audio feeds of babies (extremely sensitive)
- User credentials and authentication tokens
- Device authentication tokens
- Payment information (handled by Stripe)

**Medium Value:**
- User personal information (email, name)
- Device configuration and settings
- Sensor data history
- Usage analytics

**Low Value:**
- Public API documentation
- Firmware version numbers
- System status information

### Threat Actors

**External Attackers:**
- Script kiddies (automated attacks, opportunistic)
- Hackers (targeted attacks, data theft)
- Competitors (corporate espionage)
- State actors (surveillance, very low probability)

**Internal Threats:**
- Malicious employees (mitigated by access controls)
- Accidental data exposure (mitigated by training, audit logs)

**Physical Threats:**
- Device theft (encrypted storage, remote wipe)
- Unauthorized physical access to servers (colocation security)

### Attack Vectors

1. **Network Attacks:**
   - Man-in-the-middle (MITM)
   - DDoS
   - Port scanning
   - Packet sniffing

2. **Application Attacks:**
   - SQL injection
   - XSS (Cross-Site Scripting)
   - CSRF (Cross-Site Request Forgery)
   - API abuse/brute force

3. **Authentication Attacks:**
   - Credential stuffing
   - Password spraying
   - Token theft
   - Session hijacking

4. **Device Attacks:**
   - Firmware reverse engineering
   - Device impersonation
   - Malicious firmware updates
   - Physical device tampering

---

## Security Layers

### 1. Transport Security

#### TLS/HTTPS Everywhere

**Requirements:**
- All communications encrypted in transit
- TLS 1.3 minimum (TLS 1.2 acceptable)
- Strong cipher suites only
- Perfect Forward Secrecy (PFS)

**Implementation:**
```nginx
# Nginx configuration
ssl_protocols TLSv1.3 TLSv1.2;
ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384';
ssl_prefer_server_ciphers on;
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;

# HSTS (HTTP Strict Transport Security)
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

**Certificate Management:**
- Let's Encrypt for automatic renewal
- Wildcard certificate for subdomains
- Certificate pinning for device-to-server communication

#### WebRTC Security

**Built-in Encryption:**
- DTLS (Datagram Transport Layer Security) for data channels
- SRTP (Secure Real-time Transport Protocol) for media streams
- Mandatory encryption (cannot disable)

**Signaling Security:**
- WebSocket connection over TLS
- Authentication required before signaling

---

### 2. Authentication

#### User Authentication (Firebase)

**Method:** Firebase Authentication (OAuth 2.0 / OpenID Connect)

**Features:**
- Email/password authentication
- Multi-factor authentication (MFA) available
- Password strength requirements
- Account recovery via email

**Token Flow:**
```
1. User enters credentials in mobile app
2. Firebase validates credentials
3. Firebase issues ID token (JWT, 1-hour expiry)
4. Client sends token to our backend via Authorization header
5. Backend validates token with Firebase Admin SDK
6. Backend extracts firebase_uid and loads user from database
7. Request processed with user context
```

**Token Validation:**
```python
from firebase_admin import auth

async def verify_firebase_token(id_token: str) -> dict:
    try:
        decoded_token = auth.verify_id_token(id_token)
        firebase_uid = decoded_token['uid']
        email = decoded_token.get('email')
        return {'firebase_uid': firebase_uid, 'email': email}
    except auth.InvalidIdTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
    except auth.ExpiredIdTokenError:
        raise HTTPException(status_code=401, detail="Token expired")
```

**Password Requirements:**
- Minimum 8 characters
- Mix of uppercase, lowercase, numbers
- Firebase handles password hashing (bcrypt)
- Password breach detection (Firebase checks against known breaches)

**Multi-Factor Authentication:**
- SMS-based OTP
- Authenticator apps (TOTP)
- Optional but recommended

#### Device Authentication

**Device Registration Flow:**

```
1. Device First Boot:
   - Generate unique device_id (SHA256(MAC address + serial number))
   - Generate 6-digit registration code (random, 10-minute expiry)
   - Display code on device screen or speak via audio
   - Store code in database with expiry

2. User Pairing:
   - User opens mobile app
   - Enters registration code
   - App calls POST /devices/pair with code

3. Backend Validation:
   - Verify code exists and not expired
   - Verify code not already used
   - Check device not already paired to another user

4. Token Issuance:
   - Generate device_token (secure random, 256-bit)
   - Store hashed token in database
   - Link device to user account
   - Return token to app

5. App → Device:
   - App sends device_token to device via local network
   - Device stores token in secure storage
   - Device uses token for all API requests
```

**Device Token Security:**
```python
import secrets
import hashlib

def generate_device_token() -> tuple[str, str]:
    """Generate device token and its hash"""
    token = secrets.token_urlsafe(32)  # 256 bits
    token_hash = hashlib.sha256(token.encode()).hexdigest()
    return token, token_hash

# Store only hash in database
# Return plaintext token only once during pairing
```

**Token Storage on Device:**
- Stored in encrypted filesystem partition
- Read-only root filesystem prevents tampering
- Token never logged or transmitted in plaintext

#### API Key Security (Future: Developer API)

For future third-party integrations:
- API keys with restricted scopes
- Rate limiting per API key
- Ability to revoke keys
- Separate from user/device authentication

---

### 3. Authorization

#### Role-Based Access Control (RBAC)

**Roles:**
- **Device Owner:** Full control (settings, sharing, deletion)
- **Shared User (view):** Can watch live, view events, no configuration
- **Shared User (control):** View + two-way audio + lullaby playback
- **Shared User (admin):** View + control + settings changes
- **Admin (internal):** Our support team, restricted access

**Implementation:**
```python
from enum import Enum

class Permission(Enum):
    VIEW_STREAM = "view_stream"
    VIEW_EVENTS = "view_events"
    TWO_WAY_AUDIO = "two_way_audio"
    MODIFY_SETTINGS = "modify_settings"
    SHARE_DEVICE = "share_device"
    DELETE_DEVICE = "delete_device"

class Role(Enum):
    OWNER = [Permission.VIEW_STREAM, Permission.VIEW_EVENTS,
             Permission.TWO_WAY_AUDIO, Permission.MODIFY_SETTINGS,
             Permission.SHARE_DEVICE, Permission.DELETE_DEVICE]
    VIEW = [Permission.VIEW_STREAM, Permission.VIEW_EVENTS]
    CONTROL = [Permission.VIEW_STREAM, Permission.VIEW_EVENTS,
               Permission.TWO_WAY_AUDIO]
    ADMIN = [Permission.VIEW_STREAM, Permission.VIEW_EVENTS,
             Permission.TWO_WAY_AUDIO, Permission.MODIFY_SETTINGS]

async def check_permission(user_id: UUID, device_id: UUID,
                          permission: Permission) -> bool:
    # Check if user owns device
    device = await db.fetch_one(
        "SELECT owner_id FROM devices WHERE id = $1", device_id
    )
    if device['owner_id'] == user_id:
        return True  # Owner has all permissions

    # Check if device is shared with user
    share = await db.fetch_one(
        "SELECT permission FROM shared_devices
         WHERE device_id = $1 AND shared_with_user_id = $2
         AND (expires_at IS NULL OR expires_at > NOW())",
        device_id, user_id
    )
    if share:
        role = Role[share['permission'].upper()]
        return permission in role.value

    return False
```

#### Row-Level Security (PostgreSQL)

**Enable RLS on sensitive tables:**
```sql
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only see their own devices or shared devices
CREATE POLICY device_access_policy ON devices
    FOR SELECT
    USING (
        owner_id = current_setting('app.current_user_id')::uuid
        OR id IN (
            SELECT device_id FROM shared_devices
            WHERE shared_with_user_id = current_setting('app.current_user_id')::uuid
        )
    );

-- Set user context in each request
SET app.current_user_id = 'user_uuid_here';
```

---

### 4. Data Encryption

#### In-Transit Encryption

**Always Encrypted:**
- HTTPS/TLS for REST API
- WSS (WebSocket Secure) for real-time
- TLS for MQTT
- DTLS/SRTP for WebRTC

**Implementation:**
- No option to disable encryption
- Reject non-TLS connections
- HSTS headers to prevent downgrade attacks

#### At-Rest Encryption

**Database:**
```bash
# Encrypt filesystem (LUKS on Linux)
cryptsetup luksFormat /dev/sdb
cryptsetup open /dev/sdb encrypted_db
mkfs.ext4 /dev/mapper/encrypted_db

# PostgreSQL runs on encrypted filesystem
# Keys stored in secure key management system
```

**Object Storage (MinIO):**
- Server-side encryption (SSE-S3)
- AES-256-GCM
- Encryption keys managed by MinIO
- Optional: Customer-managed keys (future)

**Device Storage:**
```bash
# Encrypted partition for sensitive data
cryptsetup luksFormat /dev/mmcblk0p2
cryptsetup open /dev/mmcblk0p2 encrypted_storage

# Key derived from hardware unique ID + passphrase
# Automatically unlocked on boot
```

#### End-to-End Encryption (Optional, User-Controlled)

**User Choice:**
- Disabled by default (allows support access and AI training)
- User can enable in settings
- Once enabled, only user can decrypt videos

**Key Management:**
```
1. User Enables E2E:
   - Generate encryption key pair (RSA-4096 or X25519)
   - Private key encrypted with user's password (PBKDF2, 100k iterations)
   - Encrypted private key stored in user's browser/app
   - Public key stored on server

2. Video Upload (E2E Enabled):
   - Device generates symmetric key (AES-256)
   - Device encrypts video with symmetric key
   - Device encrypts symmetric key with user's public key
   - Upload encrypted video + encrypted symmetric key

3. Video Playback:
   - Download encrypted video + encrypted key
   - Decrypt symmetric key with user's private key (requires password)
   - Decrypt video with symmetric key
   - Play in browser/app

4. Key Recovery:
   - User can back up private key to iCloud/Google Drive (encrypted)
   - Or export to file (user's responsibility)
   - Lost key = lost videos (cannot recover)
```

**Implementation:**
```javascript
// Client-side (Flutter/Dart)
import 'package:encrypt/encrypt.dart';

// Generate key pair
final key = Key.fromSecureRandom(32); // AES-256
final iv = IV.fromSecureRandom(16);

// Encrypt video file
final encrypter = Encrypter(AES(key));
final encryptedVideo = encrypter.encryptBytes(videoBytes, iv: iv);

// Encrypt key with user's public RSA key
final rsaEncrypter = Encrypter(RSA(publicKey: userPublicKey));
final encryptedKey = rsaEncrypter.encrypt(key.base64);

// Upload both to server
```

**Trade-offs:**
- **Pro:** Maximum privacy, we cannot access user videos
- **Con:** Cannot help with playback issues
- **Con:** Cannot use for AI training
- **Con:** User loses key = loses all videos

---

### 5. Input Validation & Sanitization

#### API Input Validation

**Using Pydantic (FastAPI):**
```python
from pydantic import BaseModel, Field, validator

class DeviceSettings(BaseModel):
    name: str = Field(..., min_length=1, max_length=255)
    motion_sensitivity: int = Field(..., ge=0, le=100)
    sound_threshold: int = Field(..., ge=0, le=100)

    @validator('name')
    def validate_name(cls, v):
        # Prevent XSS
        if '<' in v or '>' in v:
            raise ValueError('Invalid characters in name')
        return v
```

#### SQL Injection Prevention

**Always use parameterized queries:**
```python
# GOOD: Parameterized query
await db.fetch_all(
    "SELECT * FROM devices WHERE owner_id = $1", user_id
)

# BAD: String concatenation (NEVER DO THIS)
await db.fetch_all(
    f"SELECT * FROM devices WHERE owner_id = '{user_id}'"
)
```

**ORM/Query Builder:**
- Use SQLAlchemy or similar
- Automatic parameterization
- Protection against SQL injection

#### XSS Prevention

**Content Security Policy (CSP):**
```http
Content-Security-Policy:
    default-src 'self';
    script-src 'self';
    style-src 'self' 'unsafe-inline';
    img-src 'self' data: https:;
    connect-src 'self' wss://api.babymonitor.example.com;
```

**Output Encoding:**
- Escape HTML in user-generated content
- Flutter/React automatically escape by default
- Be careful with `innerHTML` or similar

#### CSRF Protection

**Double Submit Cookie:**
```python
# Generate CSRF token on login
csrf_token = secrets.token_urlsafe(32)

# Set in cookie (HttpOnly, SameSite=Strict)
response.set_cookie(
    "csrf_token",
    csrf_token,
    httponly=True,
    secure=True,
    samesite="strict"
)

# Require token in POST/PUT/DELETE headers
@app.post("/devices/{device_id}/settings")
async def update_settings(
    device_id: UUID,
    settings: DeviceSettings,
    csrf_token: str = Header(...)
):
    # Validate CSRF token matches cookie
    if csrf_token != request.cookies.get("csrf_token"):
        raise HTTPException(403, "Invalid CSRF token")
```

---

### 6. Secure Device Communication

#### Device Certificate Pinning

**Prevent MITM Attacks:**
```c
// Device firmware (C)
#include <openssl/ssl.h>

// Pin server's public key
const char* server_cert_fingerprint =
    "sha256//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

int verify_callback(int preverify_ok, X509_STORE_CTX* ctx) {
    X509* cert = X509_STORE_CTX_get_current_cert(ctx);

    // Verify certificate fingerprint matches
    char fingerprint[65];
    get_cert_fingerprint(cert, fingerprint);

    if (strcmp(fingerprint, server_cert_fingerprint) != 0) {
        return 0; // Reject connection
    }
    return preverify_ok;
}
```

#### Firmware Signing

**Ensure firmware authenticity:**
```bash
# Sign firmware during build
openssl dgst -sha256 -sign private_key.pem -out firmware.sig firmware.bin

# Device verifies signature before installing
openssl dgst -sha256 -verify public_key.pem -signature firmware.sig firmware.bin
```

**Public key embedded in bootloader:**
- Cannot be modified without physical access
- Prevents malicious firmware updates

#### Secure Boot (Production Devices)

**Boot Chain:**
1. ROM bootloader (immutable, in silicon)
2. Verifies bootloader signature
3. Bootloader verifies kernel signature
4. Kernel verifies root filesystem signature
5. Only boot if all signatures valid

**Implementation:**
- Use U-Boot with secure boot
- Rockchip SecureBoot feature
- Keys burned into OTP (One-Time Programmable) fuses

---

### 7. Rate Limiting & DDoS Protection

#### Application-Level Rate Limiting

**Using Redis:**
```python
import redis
from datetime import datetime, timedelta

r = redis.Redis()

async def check_rate_limit(user_id: str, endpoint: str,
                          limit: int, window: int) -> bool:
    """
    Check if user has exceeded rate limit

    Args:
        user_id: User identifier
        endpoint: API endpoint
        limit: Max requests in window
        window: Time window in seconds
    """
    key = f"rate_limit:{user_id}:{endpoint}"
    current = r.get(key)

    if current is None:
        # First request in window
        r.setex(key, window, 1)
        return True
    elif int(current) < limit:
        # Within limit
        r.incr(key)
        return True
    else:
        # Exceeded limit
        return False

# Middleware
@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    user_id = get_user_id_from_request(request)

    if not await check_rate_limit(user_id, request.url.path,
                                   limit=1000, window=3600):
        return JSONResponse(
            status_code=429,
            content={"error": "Rate limit exceeded"},
            headers={"Retry-After": "3600"}
        )

    response = await call_next(request)
    return response
```

#### Cloudflare DDoS Protection

**Free Tier Features:**
- DDoS mitigation (automatic)
- Web Application Firewall (WAF)
- Rate limiting (configurable)
- Bot detection
- IP reputation filtering

**Configuration:**
```
# Cloudflare dashboard settings
Security > DDoS > Enabled
Firewall > Rules > Block known bots
Speed > Optimization > Auto Minify (JS/CSS/HTML)
SSL/TLS > Full (strict)
```

---

### 8. Logging & Monitoring

#### Security Event Logging

**Events to Log:**
- Authentication attempts (success/failure)
- Authorization failures
- Suspicious activity (multiple failed logins, unusual access patterns)
- Configuration changes
- Firmware updates
- Device pairing/unpairing

**Log Format:**
```json
{
    "timestamp": "2025-11-17T10:30:00Z",
    "event_type": "auth_failure",
    "user_id": "uuid",
    "ip_address": "192.0.2.1",
    "user_agent": "BabyMonitor/1.0.0 (iOS 17.0)",
    "details": {
        "reason": "invalid_password",
        "email": "user@example.com"
    }
}
```

**Log Storage:**
- Centralized logging (syslog or equivalent)
- Retention: 90 days
- Encrypted at rest
- Access controls (only admins)

#### Anomaly Detection

**Automated Alerts:**
- 5+ failed login attempts from same IP in 5 minutes
- Device accessing API from new IP/location
- Unusual data transfer volumes
- Multiple devices with same token
- Firmware update failures

**Alert Channels:**
- Email to admin team
- Slack/Discord webhook
- SMS for critical alerts (future)

---

### 9. Incident Response

#### Incident Response Plan

**Severity Levels:**
- **P0 (Critical):** Active breach, data exposed, system down
- **P1 (High):** Potential breach, vulnerability discovered
- **P2 (Medium):** Security issue, limited impact
- **P3 (Low):** Minor security concern

**Response Procedure:**

**P0 - Critical Incident:**
1. **Immediate (0-15 minutes):**
   - Alert entire team
   - Isolate affected systems
   - Enable read-only mode if possible
   - Document everything

2. **Short-term (15-60 minutes):**
   - Identify scope of breach
   - Notify affected users (if data exposed)
   - Change all credentials
   - Apply emergency patches

3. **Medium-term (1-24 hours):**
   - Root cause analysis
   - Implement fixes
   - Verify no ongoing access
   - Restore services

4. **Long-term (24+ hours):**
   - Post-mortem report
   - Notify authorities if required (GDPR, etc.)
   - Improve security measures
   - Update incident response plan

#### Data Breach Notification

**Legal Requirements:**
- GDPR: 72 hours to notify authorities
- State laws (California, etc.): Varies
- User notification: As soon as possible

**Notification Template:**
```
Subject: Security Incident Notification

Dear [User],

We are writing to inform you of a security incident involving your
Baby Monitor account.

What Happened:
[Brief description of incident]

What Information Was Involved:
[Specific data types]

What We're Doing:
[Steps taken to secure system]

What You Should Do:
[Actions user should take]

Questions:
Contact security@babymonitor.example.com

Sincerely,
[Company Name] Security Team
```

---

### 10. Compliance & Privacy

#### GDPR Compliance (if applicable)

**User Rights:**
- Right to access (export data)
- Right to erasure (delete account)
- Right to rectification (correct data)
- Right to data portability

**Implementation:**
```python
# Data export
@app.get("/users/me/export")
async def export_user_data(user: User):
    """Export all user data in machine-readable format"""
    data = {
        "user": user.dict(),
        "devices": await get_user_devices(user.id),
        "events": await get_user_events(user.id),
        "videos": await get_user_videos(user.id),
        # Include all personal data
    }
    return JSONResponse(data)

# Account deletion
@app.delete("/users/me")
async def delete_account(user: User):
    """Delete user account and all associated data"""
    # Anonymize or delete all data
    await anonymize_user_data(user.id)
    await delete_user(user.id)
    return {"message": "Account deleted"}
```

**Data Processing Agreement:**
- Clear privacy policy
- Explicit consent for data collection
- Opt-in for AI training
- Opt-in for marketing emails

#### COPPA Considerations

**Issue:** We're recording videos of children (under 13)

**Mitigation:**
- We're not collecting data "from" children
- We're collecting data "about" children (parental monitoring)
- Parents own and control the data
- Clear disclosures in privacy policy

**Consult legal counsel on COPPA compliance.**

#### Video Storage Jurisdiction

**Data Residency:**
- Store data in same country/region as user (if possible)
- GDPR: EU data stays in EU
- Chinese law: China data stays in China
- For MVP: All data in US (note in privacy policy)

---

## Security Checklist

### Development Phase
- [ ] All dependencies up to date
- [ ] No hardcoded credentials in code
- [ ] Secrets in environment variables
- [ ] .gitignore includes .env, credentials
- [ ] Static analysis tool configured (Bandit for Python)

### Pre-Production
- [ ] Penetration testing completed
- [ ] Vulnerability scanning (OWASP ZAP, Nessus)
- [ ] Code review with security focus
- [ ] All sensitive data encrypted
- [ ] Rate limiting implemented
- [ ] HTTPS enforced everywhere
- [ ] Firmware signing implemented

### Production
- [ ] Security monitoring enabled
- [ ] Incident response plan documented
- [ ] Backups tested and verified
- [ ] Access controls audited
- [ ] Privacy policy published
- [ ] Terms of service published
- [ ] GDPR compliance verified (if applicable)

### Ongoing
- [ ] Monthly security audits
- [ ] Quarterly penetration tests
- [ ] Review access logs weekly
- [ ] Update dependencies monthly
- [ ] Security training for team annually

---

## Security Resources

**Tools:**
- OWASP ZAP (web vulnerability scanner)
- Bandit (Python security linter)
- npm audit (Node.js dependency check)
- Trivy (container vulnerability scanner)

**References:**
- OWASP Top 10: https://owasp.org/www-project-top-ten/
- NIST Cybersecurity Framework: https://www.nist.gov/cyberframework
- CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks/

**Reporting Security Issues:**
- Email: security@babymonitor.example.com
- Bug bounty program (future)

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
