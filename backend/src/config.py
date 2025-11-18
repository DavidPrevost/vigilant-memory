"""
Backend Configuration
"""
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

class Config:
    """Base configuration"""

    # Flask
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = os.getenv('DEBUG', 'True').lower() == 'true'

    # Server
    HOST = os.getenv('HOST', '0.0.0.0')
    PORT = int(os.getenv('PORT', 5000))

    # PostgreSQL
    POSTGRES_HOST = os.getenv('POSTGRES_HOST', 'localhost')
    POSTGRES_PORT = int(os.getenv('POSTGRES_PORT', 5432))
    POSTGRES_DB = os.getenv('POSTGRES_DB', 'babymonitor')
    POSTGRES_USER = os.getenv('POSTGRES_USER', 'babymonitor')
    POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'dev_password_change_in_prod')

    @property
    def SQLALCHEMY_DATABASE_URI(self):
        return (f"postgresql://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}@"
                f"{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}")

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # TimescaleDB
    TIMESCALE_HOST = os.getenv('TIMESCALE_HOST', 'localhost')
    TIMESCALE_PORT = int(os.getenv('TIMESCALE_PORT', 5433))
    TIMESCALE_DB = os.getenv('TIMESCALE_DB', 'babymonitor_timeseries')
    TIMESCALE_USER = os.getenv('TIMESCALE_USER', 'babymonitor')
    TIMESCALE_PASSWORD = os.getenv('TIMESCALE_PASSWORD', 'dev_password_change_in_prod')

    @property
    def TIMESCALE_DATABASE_URI(self):
        return (f"postgresql://{self.TIMESCALE_USER}:{self.TIMESCALE_PASSWORD}@"
                f"{self.TIMESCALE_HOST}:{self.TIMESCALE_PORT}/{self.TIMESCALE_DB}")

    # Redis
    REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', '')
    REDIS_DB = int(os.getenv('REDIS_DB', 0))

    @property
    def REDIS_URL(self):
        if self.REDIS_PASSWORD:
            return f"redis://:{self.REDIS_PASSWORD}@{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"
        return f"redis://{self.REDIS_HOST}:{self.REDIS_PORT}/{self.REDIS_DB}"

    # MQTT
    MQTT_BROKER_HOST = os.getenv('MQTT_BROKER_HOST', 'localhost')
    MQTT_BROKER_PORT = int(os.getenv('MQTT_BROKER_PORT', 1883))
    MQTT_USERNAME = os.getenv('MQTT_USERNAME', '')
    MQTT_PASSWORD = os.getenv('MQTT_PASSWORD', '')
    MQTT_TLS_ENABLED = os.getenv('MQTT_TLS_ENABLED', 'False').lower() == 'true'

    # MinIO
    MINIO_ENDPOINT = os.getenv('MINIO_ENDPOINT', 'localhost:9000')
    MINIO_ACCESS_KEY = os.getenv('MINIO_ACCESS_KEY', 'minioadmin')
    MINIO_SECRET_KEY = os.getenv('MINIO_SECRET_KEY', 'minioadmin_change_in_prod')
    MINIO_BUCKET_VIDEOS = os.getenv('MINIO_BUCKET_VIDEOS', 'babymonitor-videos')
    MINIO_BUCKET_THUMBNAILS = os.getenv('MINIO_BUCKET_THUMBNAILS', 'babymonitor-thumbnails')
    MINIO_SECURE = os.getenv('MINIO_SECURE', 'False').lower() == 'true'

    # Firebase
    FIREBASE_CREDENTIALS_PATH = os.getenv('FIREBASE_CREDENTIALS_PATH', './config/firebase-credentials.json')
    FIREBASE_PROJECT_ID = os.getenv('FIREBASE_PROJECT_ID', '')

    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'change_this_jwt_secret_in_production')
    JWT_ALGORITHM = os.getenv('JWT_ALGORITHM', 'HS256')
    JWT_EXPIRATION_HOURS = int(os.getenv('JWT_EXPIRATION_HOURS', 24))

    # Video Settings
    MAX_VIDEO_SIZE_MB = int(os.getenv('MAX_VIDEO_SIZE_MB', 500))
    ALLOWED_VIDEO_FORMATS = os.getenv('ALLOWED_VIDEO_FORMATS', 'mp4,avi,mov,mkv').split(',')
    VIDEO_RETENTION_DAYS_FREE = int(os.getenv('VIDEO_RETENTION_DAYS_FREE', 7))
    VIDEO_RETENTION_DAYS_PAID = int(os.getenv('VIDEO_RETENTION_DAYS_PAID', 30))

    # Rate Limiting
    RATE_LIMIT_ENABLED = os.getenv('RATE_LIMIT_ENABLED', 'True').lower() == 'true'
    RATE_LIMIT_DEFAULT = os.getenv('RATE_LIMIT_DEFAULT', '100 per hour')

    # Monitoring
    PROMETHEUS_ENABLED = os.getenv('PROMETHEUS_ENABLED', 'True').lower() == 'true'
    PROMETHEUS_PORT = int(os.getenv('PROMETHEUS_PORT', 9090))

    # Logging
    LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
    LOG_FILE = os.getenv('LOG_FILE', './logs/backend.log')

    # CORS
    CORS_ORIGINS = os.getenv('CORS_ORIGINS', '*')


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False


class TestConfig(Config):
    """Testing configuration"""
    TESTING = True
    POSTGRES_DB = 'babymonitor_test'
    TIMESCALE_DB = 'babymonitor_timeseries_test'


# Config dictionary
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestConfig,
    'default': DevelopmentConfig
}


def get_config():
    """Get configuration based on environment"""
    env = os.getenv('FLASK_ENV', 'development')
    return config.get(env, config['default'])
