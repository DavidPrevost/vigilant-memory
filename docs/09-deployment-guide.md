# Deployment Guide

Quick reference for deploying the baby monitor system at different scales.

---

## Development Deployment (Local Machine)

### Requirements
- Mini PC or desktop computer
- Ubuntu Server 22.04 LTS
- Docker & Docker Compose installed
- 4GB+ RAM, 100GB+ storage

### Setup

```bash
# Clone repository
git clone https://github.com/your-org/baby-monitor.git
cd baby-monitor/backend

# Start services
docker-compose up -d

# Verify services running
docker-compose ps

# View logs
docker-compose logs -f
```

### Access Points
- **API:** http://localhost:8000
- **MinIO Console:** http://localhost:9001
- **PostgreSQL:** localhost:5432
- **Redis:** localhost:6379
- **MQTT:** localhost:1883

---

## Production Deployment (Single Server)

### Server Specifications
- **CPU:** 4+ cores
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 500GB SSD + 2-4TB HDD
- **Network:** Static IP, 100+ Mbps

### Initial Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt install docker-compose-plugin

# Create deployment user
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo su - deploy

# Clone repository
git clone https://github.com/your-org/baby-monitor.git
cd baby-monitor
```

### Configure Environment

```bash
# Create .env file
cat > backend/.env << 'EOF'
# Database
DATABASE_URL=postgresql://user:password@localhost/baby_monitor
TIMESERIES_DB_URL=postgresql://user:password@localhost:5433/baby_monitor_timeseries

# Redis
REDIS_URL=redis://localhost:6379

# MinIO
MINIO_ENDPOINT=localhost:9000
MINIO_ACCESS_KEY=your_access_key
MINIO_SECRET_KEY=your_secret_key

# Firebase
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_SERVICE_ACCOUNT=/path/to/service-account.json

# Security
SECRET_KEY=generate_random_key_here
ALLOWED_ORIGINS=https://yourdomain.com

# Environment
ENVIRONMENT=production
DEBUG=false
EOF
```

### SSL/TLS Setup

```bash
# Install Certbot
sudo apt install certbot

# Get certificate
sudo certbot certonly --standalone -d api.yourdomain.com

# Certificates will be in /etc/letsencrypt/live/api.yourdomain.com/
```

### Nginx Reverse Proxy

```bash
# Install Nginx
sudo apt install nginx

# Configure
sudo nano /etc/nginx/sites-available/baby-monitor

# Add configuration (see below)

# Enable site
sudo ln -s /etc/nginx/sites-available/baby-monitor /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

**Nginx Configuration:**
```nginx
server {
    listen 80;
    server_name api.yourdomain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/api.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.yourdomain.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

### Firewall Setup

```bash
# Configure UFW
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 1883/tcp # MQTT
sudo ufw enable
```

### Start Services

```bash
cd ~/baby-monitor/backend
docker-compose -f docker-compose.prod.yml up -d
```

### Monitoring

```bash
# View logs
docker-compose logs -f

# Check resource usage
docker stats

# System monitoring
htop
```

---

## Multi-Server Deployment (HA Setup)

### Architecture

```
┌─────────────┐      ┌─────────────┐
│  Server 1   │      │  Server 2   │
│  (Primary)  │◄────►│  (Replica)  │
└─────────────┘      └─────────────┘
       │                    │
       └────────┬───────────┘
                │
        ┌───────┴────────┐
        │  HAProxy       │
        │  (Floating IP) │
        └────────────────┘
```

### Server 1 (Primary)

```yaml
# docker-compose.prod.yml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_REPLICATION_MODE: master
      POSTGRES_REPLICATION_USER: replicator
      POSTGRES_REPLICATION_PASSWORD: repl_password
    volumes:
      - /data/postgres:/var/lib/postgresql/data

  api:
    image: baby-monitor-api:latest
    environment:
      DATABASE_URL: postgresql://localhost/baby_monitor
```

### Server 2 (Replica)

```yaml
# docker-compose.replica.yml
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_REPLICATION_MODE: slave
      POSTGRES_MASTER_HOST: server1.internal
      POSTGRES_REPLICATION_USER: replicator
      POSTGRES_REPLICATION_PASSWORD: repl_password

  api:
    image: baby-monitor-api:latest
    environment:
      DATABASE_URL: postgresql://localhost/baby_monitor
      READ_ONLY: true
```

### HAProxy Configuration

```bash
# /etc/haproxy/haproxy.cfg
frontend http_front
   bind *:80
   bind *:443 ssl crt /etc/ssl/certs/baby-monitor.pem
   default_backend api_servers

backend api_servers
   balance roundrobin
   server server1 10.0.0.1:8000 check
   server server2 10.0.0.2:8000 check backup
```

---

## Backup & Recovery

### Automated Backups

```bash
# Create backup script
cat > /home/deploy/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR=/backups/$(date +%Y%m%d)
mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec postgres pg_dump -U postgres baby_monitor > $BACKUP_DIR/postgres.sql

# Backup TimescaleDB
docker exec timescaledb pg_dump -U postgres baby_monitor_timeseries > $BACKUP_DIR/timeseries.sql

# Backup Redis
docker exec redis redis-cli SAVE
docker cp redis:/data/dump.rdb $BACKUP_DIR/redis.rdb

# Compress
tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
rm -rf $BACKUP_DIR

# Upload to Backblaze B2
b2 upload-file bucket-name $BACKUP_DIR.tar.gz backups/$(date +%Y%m%d).tar.gz

# Delete old backups (keep 30 days)
find /backups -name "*.tar.gz" -mtime +30 -delete
EOF

chmod +x /home/deploy/backup.sh

# Add to crontab (run daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/deploy/backup.sh") | crontab -
```

### Recovery Procedure

```bash
# Stop services
docker-compose down

# Restore PostgreSQL
gunzip -c backup.tar.gz | tar -xf -
docker exec -i postgres psql -U postgres -d baby_monitor < 20251117/postgres.sql

# Restore TimescaleDB
docker exec -i timescaledb psql -U postgres -d baby_monitor_timeseries < 20251117/timeseries.sql

# Restore Redis
docker cp 20251117/redis.rdb redis:/data/dump.rdb
docker restart redis

# Start services
docker-compose up -d
```

---

## Cloudflare Setup (Recommended)

### Benefits
- DDoS protection
- SSL/TLS
- DNS management
- CDN for static assets

### Configuration

1. **Add Domain to Cloudflare:**
   - Sign up at cloudflare.com
   - Add your domain
   - Update nameservers at domain registrar

2. **DNS Records:**
   ```
   Type  Name      Content              Proxy
   A     api       your.server.ip       Yes
   A     mqtt      your.server.ip       Yes
   A     www       your.server.ip       Yes
   ```

3. **SSL/TLS Settings:**
   - SSL/TLS encryption mode: Full (strict)
   - Always Use HTTPS: On
   - Minimum TLS Version: 1.2

4. **Firewall Rules:**
   - Block known bots
   - Challenge suspicious traffic
   - Rate limiting (1000 requests/hour per IP)

---

## Monitoring Setup

### Prometheus & Grafana

```yaml
# Add to docker-compose.yml
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    volumes:
      - grafana_data:/var/lib/grafana
    ports:
      - "3000:3000"
    environment:
      GF_SECURITY_ADMIN_PASSWORD: admin_password
```

**Prometheus Configuration:**
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'api'
    static_configs:
      - targets: ['api:8000']

  - job_name: 'postgres'
    static_configs:
      - targets: ['postgres-exporter:9187']
```

---

## Scaling Checklist

### 500 → 1,000 Users
- [ ] Add second server (replica)
- [ ] Set up HAProxy load balancer
- [ ] Increase storage capacity
- [ ] Monitor performance metrics

### 1,000 → 5,000 Users
- [ ] Split database to dedicated server
- [ ] Add dedicated storage server (MinIO distributed)
- [ ] Implement Redis cluster
- [ ] Consider CDN for video delivery

### 5,000 → 10,000 Users
- [ ] Full cluster setup (3+ servers)
- [ ] Database sharding (if needed)
- [ ] Multiple TURN servers (geographic distribution)
- [ ] Dedicated monitoring infrastructure

---

## Maintenance

### Regular Tasks

**Daily:**
- [ ] Check service status
- [ ] Review error logs
- [ ] Monitor resource usage

**Weekly:**
- [ ] Review backup success
- [ ] Check disk space
- [ ] Update security patches

**Monthly:**
- [ ] Review performance metrics
- [ ] Optimize slow queries
- [ ] Update dependencies
- [ ] Test disaster recovery

---

**Last Updated:** 2025-11-17
**Document Version:** 1.0
**Status:** Approved
