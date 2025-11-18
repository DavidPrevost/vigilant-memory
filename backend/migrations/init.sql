-- Baby Monitor Database Schema
-- PostgreSQL 16

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    phone_number VARCHAR(20),
    avatar_url TEXT,
    subscription_tier VARCHAR(20) DEFAULT 'free',
    -- Tiers: free, cloud_storage, ai_insights, complete
    subscription_expires_at TIMESTAMP WITH TIME ZONE,
    e2e_encryption_enabled BOOLEAN DEFAULT FALSE,
    e2e_public_key TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    account_status VARCHAR(20) DEFAULT 'active'
    -- Status: active, suspended, deleted
);

CREATE INDEX idx_users_firebase_uid ON users(firebase_uid);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_subscription_tier ON users(subscription_tier);

-- Devices table
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_name VARCHAR(255) NOT NULL,
    device_type VARCHAR(20) DEFAULT 'monitor',
    -- Types: monitor, sensor_hub
    model VARCHAR(50),
    -- Model: prototype, core, pro
    firmware_version VARCHAR(50),
    hardware_version VARCHAR(50),
    serial_number VARCHAR(100) UNIQUE,

    -- Device credentials
    device_secret_hash TEXT NOT NULL,
    mqtt_client_id VARCHAR(100) UNIQUE NOT NULL,

    -- Configuration
    settings JSONB DEFAULT '{}',
    capabilities JSONB DEFAULT '{}',
    -- Example: {"video": "4k", "audio": true, "sensors": ["temp", "humidity"]}

    -- Location and status
    location_name VARCHAR(255),
    timezone VARCHAR(50) DEFAULT 'UTC',
    online_status BOOLEAN DEFAULT FALSE,
    last_seen_at TIMESTAMP WITH TIME ZONE,
    battery_level INTEGER,
    -- 0-100 percentage
    power_source VARCHAR(20),
    -- ac_power, battery, both

    -- Network info
    ip_address INET,
    wifi_ssid VARCHAR(100),
    signal_strength INTEGER,

    -- Timestamps
    registered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    activated_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_devices_owner ON devices(owner_id);
CREATE INDEX idx_devices_mqtt_client ON devices(mqtt_client_id);
CREATE INDEX idx_devices_online_status ON devices(online_status);
CREATE INDEX idx_devices_last_seen ON devices(last_seen_at);

-- Shared devices table (for multiple users accessing same device)
CREATE TABLE shared_devices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) DEFAULT 'viewer',
    -- Levels: viewer, controller, admin
    shared_by UUID NOT NULL REFERENCES users(id),
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(device_id, user_id)
);

CREATE INDEX idx_shared_devices_device ON shared_devices(device_id);
CREATE INDEX idx_shared_devices_user ON shared_devices(user_id);

-- Events table (partitioned by date for performance)
CREATE TABLE events (
    id UUID DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,
    event_type VARCHAR(50) NOT NULL,
    -- Types: motion_detected, sound_detected, person_detected, cry_detected, etc.
    severity VARCHAR(20) DEFAULT 'info',
    -- Levels: info, warning, alert, critical

    -- Event data
    confidence_score FLOAT,
    -- AI confidence 0.0-1.0
    metadata JSONB DEFAULT '{}',
    -- Event-specific data

    -- Associated media
    thumbnail_url TEXT,
    video_clip_id UUID,

    -- Location in video
    timestamp_in_video FLOAT,

    -- Notification status
    notification_sent BOOLEAN DEFAULT FALSE,
    notification_sent_at TIMESTAMP WITH TIME ZONE,

    -- User interaction
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    user_notes TEXT,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
) PARTITION BY RANGE (created_at);

-- Create partitions for events (last month, current month, next month)
CREATE TABLE events_2025_11 PARTITION OF events
    FOR VALUES FROM ('2025-11-01') TO ('2025-12-01');

CREATE TABLE events_2025_12 PARTITION OF events
    FOR VALUES FROM ('2025-12-01') TO ('2026-01-01');

CREATE TABLE events_2026_01 PARTITION OF events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE INDEX idx_events_device ON events(device_id, created_at DESC);
CREATE INDEX idx_events_type ON events(event_type);
CREATE INDEX idx_events_severity ON events(severity);

-- Videos table
CREATE TABLE videos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id UUID NOT NULL REFERENCES devices(id) ON DELETE CASCADE,

    -- Video metadata
    filename VARCHAR(255) NOT NULL,
    storage_path TEXT NOT NULL,
    -- S3/MinIO path
    storage_backend VARCHAR(20) DEFAULT 'minio',
    -- minio, s3, local

    -- Video properties
    duration_seconds FLOAT,
    resolution VARCHAR(20),
    -- 720p, 1080p, 4k
    framerate INTEGER,
    codec VARCHAR(20),
    -- h264, h265
    bitrate INTEGER,
    -- in kbps
    file_size_bytes BIGINT,

    -- Recording context
    recording_type VARCHAR(20),
    -- continuous, event_triggered, manual
    trigger_event_id UUID REFERENCES events(id),

    -- Encryption
    is_encrypted BOOLEAN DEFAULT FALSE,
    encryption_key_id VARCHAR(100),

    -- Processing status
    upload_status VARCHAR(20) DEFAULT 'uploading',
    -- uploading, processing, ready, failed
    thumbnail_generated BOOLEAN DEFAULT FALSE,
    thumbnail_url TEXT,

    -- Retention
    retention_days INTEGER DEFAULT 7,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_archived BOOLEAN DEFAULT FALSE,

    -- Timestamps
    recorded_at TIMESTAMP WITH TIME ZONE NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_videos_device ON videos(device_id, recorded_at DESC);
CREATE INDEX idx_videos_status ON videos(upload_status);
CREATE INDEX idx_videos_expires ON videos(expires_at) WHERE NOT is_archived;

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE SET NULL,

    -- Notification content
    notification_type VARCHAR(50) NOT NULL,
    -- types: event_alert, device_offline, low_battery, etc.
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    priority VARCHAR(20) DEFAULT 'normal',
    -- low, normal, high, urgent

    -- Delivery
    delivery_channels JSONB DEFAULT '["app"]',
    -- app, email, sms, push
    sent_at TIMESTAMP WITH TIME ZONE,
    delivery_status VARCHAR(20) DEFAULT 'pending',
    -- pending, sent, failed, cancelled

    -- User interaction
    read_at TIMESTAMP WITH TIME ZONE,
    action_taken VARCHAR(50),
    -- dismissed, viewed_video, acknowledged, etc.

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_status ON notifications(delivery_status);
CREATE INDEX idx_notifications_unread ON notifications(user_id, read_at) WHERE read_at IS NULL;

-- Subscriptions table
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Subscription details
    tier VARCHAR(20) NOT NULL,
    -- free, cloud_storage, ai_insights, complete
    status VARCHAR(20) DEFAULT 'active',
    -- active, cancelled, expired, failed

    -- Billing
    stripe_subscription_id VARCHAR(100) UNIQUE,
    stripe_customer_id VARCHAR(100),
    billing_period VARCHAR(20),
    -- monthly, yearly
    price_cents INTEGER,
    currency VARCHAR(3) DEFAULT 'USD',

    -- Dates
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    current_period_start TIMESTAMP WITH TIME ZONE,
    current_period_end TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,

    -- Trial
    trial_end TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_user ON subscriptions(user_id);
CREATE INDEX idx_subscriptions_stripe ON subscriptions(stripe_subscription_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);

-- Activity log table
CREATE TABLE activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    device_id UUID REFERENCES devices(id) ON DELETE SET NULL,

    -- Activity details
    action VARCHAR(100) NOT NULL,
    -- login, device_added, settings_changed, video_viewed, etc.
    resource_type VARCHAR(50),
    resource_id UUID,

    -- Context
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_activity_logs_user ON activity_logs(user_id, created_at DESC);
CREATE INDEX idx_activity_logs_device ON activity_logs(device_id, created_at DESC);
CREATE INDEX idx_activity_logs_action ON activity_logs(action);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_devices_updated_at BEFORE UPDATE ON devices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default data for development
INSERT INTO users (firebase_uid, email, display_name, subscription_tier) VALUES
    ('dev_user_1', 'dev@example.com', 'Development User', 'complete');
