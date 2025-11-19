-- TimescaleDB Schema for Baby Monitor
-- Time-series data storage

-- Enable TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Sensor readings table (hypertable)
CREATE TABLE sensor_readings (
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    device_id UUID NOT NULL,
    sensor_type VARCHAR(50) NOT NULL,
    -- Types: temperature, humidity, pressure, air_quality, light, vibration

    -- Sensor values
    value FLOAT NOT NULL,
    unit VARCHAR(20),
    -- celsius, fahrenheit, percent, lux, pa, iaq, etc.

    -- Metadata
    quality VARCHAR(20) DEFAULT 'good',
    -- good, fair, poor (data quality indicator)
    metadata JSONB DEFAULT '{}'
);

-- Convert to hypertable (partitioned by time)
SELECT create_hypertable('sensor_readings', 'time');

-- Create indexes
CREATE INDEX idx_sensor_readings_device_time ON sensor_readings (device_id, time DESC);
CREATE INDEX idx_sensor_readings_type ON sensor_readings (sensor_type, time DESC);

-- Device metrics table (hypertable)
CREATE TABLE device_metrics (
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    device_id UUID NOT NULL,

    -- System metrics
    cpu_usage_percent FLOAT,
    memory_usage_percent FLOAT,
    storage_usage_percent FLOAT,
    temperature_celsius FLOAT,
    -- Device internal temperature

    -- Network metrics
    wifi_signal_strength INTEGER,
    -- dBm
    network_latency_ms INTEGER,
    bandwidth_usage_mbps FLOAT,

    -- Power metrics
    battery_level INTEGER,
    battery_voltage FLOAT,
    power_consumption_mw INTEGER,
    charging_status VARCHAR(20),
    -- charging, discharging, full

    -- Camera metrics
    camera_fps INTEGER,
    camera_dropped_frames INTEGER,
    video_bitrate_kbps INTEGER,

    -- Error counts
    error_count INTEGER DEFAULT 0,
    warning_count INTEGER DEFAULT 0
);

SELECT create_hypertable('device_metrics', 'time');

CREATE INDEX idx_device_metrics_device_time ON device_metrics (device_id, time DESC);

-- Analytics events table (hypertable)
CREATE TABLE analytics_events (
    time TIMESTAMP WITH TIME ZONE NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    -- user_action, system_event, performance_metric, etc.

    -- Context
    user_id UUID,
    device_id UUID,
    session_id VARCHAR(100),

    -- Event properties
    properties JSONB DEFAULT '{}',

    -- Performance tracking
    duration_ms INTEGER,
    success BOOLEAN DEFAULT TRUE
);

SELECT create_hypertable('analytics_events', 'time');

CREATE INDEX idx_analytics_events_type_time ON analytics_events (event_type, time DESC);
CREATE INDEX idx_analytics_events_user ON analytics_events (user_id, time DESC);
CREATE INDEX idx_analytics_events_device ON analytics_events (device_id, time DESC);

-- Continuous aggregates for common queries

-- 1. Hourly sensor averages
CREATE MATERIALIZED VIEW sensor_readings_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    device_id,
    sensor_type,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    COUNT(*) as reading_count
FROM sensor_readings
GROUP BY bucket, device_id, sensor_type
WITH NO DATA;

-- Refresh policy (update every hour)
SELECT add_continuous_aggregate_policy('sensor_readings_hourly',
    start_offset => INTERVAL '2 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour');

-- 2. Daily device metrics summary
CREATE MATERIALIZED VIEW device_metrics_daily
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 day', time) AS bucket,
    device_id,
    AVG(cpu_usage_percent) as avg_cpu,
    MAX(cpu_usage_percent) as max_cpu,
    AVG(memory_usage_percent) as avg_memory,
    AVG(battery_level) as avg_battery,
    MIN(battery_level) as min_battery,
    SUM(error_count) as total_errors,
    SUM(warning_count) as total_warnings,
    COUNT(*) as metric_count
FROM device_metrics
GROUP BY bucket, device_id
WITH NO DATA;

SELECT add_continuous_aggregate_policy('device_metrics_daily',
    start_offset => INTERVAL '3 days',
    end_offset => INTERVAL '1 day',
    schedule_interval => INTERVAL '1 day');

-- Data retention policies

-- Keep raw sensor readings for 30 days
SELECT add_retention_policy('sensor_readings', INTERVAL '30 days');

-- Keep raw device metrics for 90 days
SELECT add_retention_policy('device_metrics', INTERVAL '90 days');

-- Keep analytics events for 180 days
SELECT add_retention_policy('analytics_events', INTERVAL '180 days');

-- Compression policies (compress data older than 7 days)
ALTER TABLE sensor_readings SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id,sensor_type'
);

SELECT add_compression_policy('sensor_readings', INTERVAL '7 days');

ALTER TABLE device_metrics SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'device_id'
);

SELECT add_compression_policy('device_metrics', INTERVAL '7 days');

-- Helper function to insert sensor reading
CREATE OR REPLACE FUNCTION insert_sensor_reading(
    p_device_id UUID,
    p_sensor_type VARCHAR(50),
    p_value FLOAT,
    p_unit VARCHAR(20) DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO sensor_readings (time, device_id, sensor_type, value, unit)
    VALUES (NOW(), p_device_id, p_sensor_type, p_value, p_unit);
END;
$$ LANGUAGE plpgsql;

-- Helper function to get latest sensor reading
CREATE OR REPLACE FUNCTION get_latest_sensor_reading(
    p_device_id UUID,
    p_sensor_type VARCHAR(50)
)
RETURNS TABLE (
    reading_time TIMESTAMP WITH TIME ZONE,
    value FLOAT,
    unit VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT time, sensor_readings.value, sensor_readings.unit
    FROM sensor_readings
    WHERE device_id = p_device_id
      AND sensor_type = p_sensor_type
    ORDER BY time DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;
