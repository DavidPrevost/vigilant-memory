# Baby Monitor Backend

Flask-based backend API for the baby monitor system.

## Features

- **REST API** - Complete RESTful API for users, devices, events, and videos
- **WebSocket** - Real-time updates via Socket.IO
- **MQTT** - Device communication protocol
- **PostgreSQL** - Primary database for user data and metadata
- **TimescaleDB** - Time-series database for sensor data
- **MinIO** - S3-compatible object storage for videos
- **Redis** - Caching and session management

## Architecture

```
backend/
├── src/
│   ├── api/           # API endpoints
│   │   ├── users.py
│   │   ├── devices.py
│   │   ├── events.py
│   │   ├── videos.py
│   │   └── sensors.py
│   ├── models/        # Database models
│   │   ├── user.py
│   │   ├── device.py
│   │   ├── event.py
│   │   ├── video.py
│   │   └── ...
│   ├── services/      # External services
│   │   ├── storage.py # MinIO/S3
│   │   └── mqtt.py    # MQTT broker
│   ├── utils/         # Utilities
│   │   ├── auth.py
│   │   └── validators.py
│   ├── config.py      # Configuration
│   └── app.py         # Main application
├── migrations/        # Database migrations
├── tests/             # Unit tests
├── docker-compose.yml # Infrastructure
├── requirements.txt   # Python dependencies
└── .env              # Environment variables
```

## Quick Start

### 1. Prerequisites

- Python 3.10+
- Docker & Docker Compose
- Git

### 2. Setup

```bash
# Clone repository
git clone https://github.com/DavidPrevost/vigilant-memory.git
cd vigilant-memory/backend

# Copy environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

### 3. Start Infrastructure

```bash
# Start databases, MQTT, MinIO, Redis
docker-compose up -d

# Wait for services to be healthy
docker-compose ps
```

### 4. Install Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

### 5. Run Backend

```bash
# Development mode
python src/app.py

# Or with gunicorn (production)
gunicorn -w 4 -b 0.0.0.0:5000 --worker-class gevent src.app:create_app()
```

The API will be available at `http://localhost:5000`

## API Endpoints

### Health Check
```
GET /health
GET /
```

### Users
```
POST   /api/users              # Create user
GET    /api/users/{id}         # Get user
PUT    /api/users/{id}         # Update user
DELETE /api/users/{id}         # Delete user
GET    /api/users/{id}/devices # Get user's devices
```

### Devices
```
POST   /api/devices                  # Register device
GET    /api/devices/{id}             # Get device
PUT    /api/devices/{id}             # Update device
DELETE /api/devices/{id}             # Delete device
POST   /api/devices/{id}/status      # Update status (device)
POST   /api/devices/{id}/share       # Share device
```

### Events
```
POST   /api/events                # Create event (device)
GET    /api/events                # Get events
GET    /api/events/{id}           # Get event
POST   /api/events/{id}/acknowledge # Acknowledge event
```

### Videos
```
POST   /api/videos/upload         # Upload video (device)
GET    /api/videos                # Get videos
GET    /api/videos/{id}           # Get video metadata
GET    /api/videos/{id}/download  # Get download URL
DELETE /api/videos/{id}           # Delete video
```

### Sensors
```
POST   /api/sensors/readings      # Submit reading (device)
GET    /api/sensors/readings      # Get readings
GET    /api/sensors/latest        # Get latest readings
```

## Authentication

### User Authentication
Send JWT token in Authorization header:
```
Authorization: Bearer <token>
```

### Device Authentication
Send device credentials in headers:
```
X-Device-ID: <device_id>
X-Device-Secret: <device_secret>
```

## Database Schema

### PostgreSQL Tables
- `users` - User accounts
- `devices` - Baby monitor devices
- `shared_devices` - Device sharing
- `events` - Detection events
- `videos` - Video recordings
- `notifications` - User notifications
- `subscriptions` - Subscription management
- `activity_logs` - Audit logs

### TimescaleDB Tables
- `sensor_readings` - Time-series sensor data
- `device_metrics` - Device performance metrics
- `analytics_events` - Analytics tracking

## Environment Variables

See `.env.example` for all configuration options.

Key variables:
- `POSTGRES_*` - PostgreSQL connection
- `TIMESCALE_*` - TimescaleDB connection
- `MQTT_*` - MQTT broker settings
- `MINIO_*` - Object storage settings
- `FIREBASE_*` - Firebase auth settings
- `JWT_SECRET_KEY` - JWT signing key

## Development

### Running Tests
```bash
pytest tests/ -v
pytest tests/ --cov=src
```

### Code Quality
```bash
# Format code
black src/

# Lint
flake8 src/
pylint src/

# Type checking
mypy src/
```

### Database Migrations
```bash
# Create migration
alembic revision -m "description"

# Run migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

## Docker Services

### PostgreSQL
- Port: 5432
- Database: babymonitor
- User: babymonitor

### TimescaleDB
- Port: 5433
- Database: babymonitor_timeseries
- User: babymonitor

### MQTT (Mosquitto)
- Port: 1883 (MQTT)
- Port: 9001 (WebSocket)

### Redis
- Port: 6379

### MinIO
- Port: 9000 (API)
- Port: 9001 (Console)
- Console: http://localhost:9001

## Production Deployment

### Using Docker
```bash
# Build image
docker build -t babymonitor-backend .

# Run container
docker run -p 5000:5000 babymonitor-backend
```

### Using Gunicorn
```bash
gunicorn -w 4 -b 0.0.0.0:5000 \
  --worker-class gevent \
  --access-logfile - \
  --error-logfile - \
  src.app:create_app()
```

### Environment
- Set `FLASK_ENV=production`
- Use strong secrets for `SECRET_KEY` and `JWT_SECRET_KEY`
- Enable HTTPS
- Configure proper database credentials
- Set up backups and monitoring

## Monitoring

### Prometheus Metrics
Available at `/metrics` (if enabled)

### Health Check
```bash
curl http://localhost:5000/health
```

### Logs
Logs are written to:
- Console (stdout/stderr)
- File (if `LOG_FILE` configured)

## Troubleshooting

### Database Connection Issues
```bash
# Check if PostgreSQL is running
docker-compose ps postgres

# Check logs
docker-compose logs postgres

# Test connection
psql -h localhost -U babymonitor -d babymonitor
```

### MQTT Connection Issues
```bash
# Check Mosquitto
docker-compose ps mosquitto
docker-compose logs mosquitto

# Test with mosquitto_pub/sub
mosquitto_sub -h localhost -t 'devices/#'
```

### MinIO Issues
```bash
# Access MinIO console
http://localhost:9001

# Check buckets
docker-compose exec minio mc ls local
```

## Contributing

1. Create feature branch
2. Write tests
3. Format code with black
4. Run linters
5. Submit pull request

## License

Proprietary - All rights reserved

## Support

For issues and questions, contact the development team.
