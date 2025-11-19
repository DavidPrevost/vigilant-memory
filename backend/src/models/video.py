"""
Video Model
"""
from datetime import datetime, timedelta
from .database import db
import uuid


class Video(db.Model):
    """Video recording model"""
    __tablename__ = 'videos'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = db.Column(db.String(36), db.ForeignKey('devices.id', ondelete='CASCADE'), nullable=False, index=True)

    # Video metadata
    filename = db.Column(db.String(255), nullable=False)
    storage_path = db.Column(db.Text, nullable=False)
    storage_backend = db.Column(db.String(20), default='minio')  # minio, s3, local

    # Video properties
    duration_seconds = db.Column(db.Float)
    resolution = db.Column(db.String(20))  # 720p, 1080p, 4k
    framerate = db.Column(db.Integer)
    codec = db.Column(db.String(20))  # h264, h265
    bitrate = db.Column(db.Integer)  # kbps
    file_size_bytes = db.Column(db.BigInteger)

    # Recording context
    recording_type = db.Column(db.String(20))  # continuous, event_triggered, manual
    trigger_event_id = db.Column(db.String(36), db.ForeignKey('events.id'))

    # Encryption
    is_encrypted = db.Column(db.Boolean, default=False)
    encryption_key_id = db.Column(db.String(100))

    # Processing status
    upload_status = db.Column(db.String(20), default='uploading', index=True)
    # uploading, processing, ready, failed
    thumbnail_generated = db.Column(db.Boolean, default=False)
    thumbnail_url = db.Column(db.Text)

    # Retention
    retention_days = db.Column(db.Integer, default=7)
    expires_at = db.Column(db.DateTime(timezone=True), index=True)
    is_archived = db.Column(db.Boolean, default=False)

    # Timestamps
    recorded_at = db.Column(db.DateTime(timezone=True), nullable=False, index=True)
    uploaded_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)
    processed_at = db.Column(db.DateTime(timezone=True))

    # Relationships
    device = db.relationship('Device', back_populates='videos')
    trigger_event = db.relationship('Event', foreign_keys=[trigger_event_id])

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'device_id': self.device_id,
            'filename': self.filename,
            'storage_path': self.storage_path,
            'storage_backend': self.storage_backend,
            'duration_seconds': self.duration_seconds,
            'resolution': self.resolution,
            'framerate': self.framerate,
            'codec': self.codec,
            'bitrate': self.bitrate,
            'file_size_bytes': self.file_size_bytes,
            'recording_type': self.recording_type,
            'trigger_event_id': self.trigger_event_id,
            'is_encrypted': self.is_encrypted,
            'upload_status': self.upload_status,
            'thumbnail_generated': self.thumbnail_generated,
            'thumbnail_url': self.thumbnail_url,
            'retention_days': self.retention_days,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'is_archived': self.is_archived,
            'recorded_at': self.recorded_at.isoformat() if self.recorded_at else None,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
            'processed_at': self.processed_at.isoformat() if self.processed_at else None
        }

    def calculate_expiry(self):
        """Calculate expiry date based on retention policy"""
        if self.retention_days:
            self.expires_at = self.recorded_at + timedelta(days=self.retention_days)

    def __repr__(self):
        return f'<Video {self.filename} ({self.id})>'
