"""
Event Model
"""
from datetime import datetime
from .database import db
import uuid


class Event(db.Model):
    """Event detection model"""
    __tablename__ = 'events'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = db.Column(db.String(36), db.ForeignKey('devices.id', ondelete='CASCADE'), nullable=False, index=True)
    event_type = db.Column(db.String(50), nullable=False, index=True)
    # Types: motion_detected, sound_detected, person_detected, cry_detected, etc.
    severity = db.Column(db.String(20), default='info', index=True)
    # Levels: info, warning, alert, critical

    # Event data
    confidence_score = db.Column(db.Float)  # 0.0-1.0
    metadata = db.Column(db.JSON, default={})

    # Associated media
    thumbnail_url = db.Column(db.Text)
    video_clip_id = db.Column(db.String(36), db.ForeignKey('videos.id'))
    timestamp_in_video = db.Column(db.Float)

    # Notification status
    notification_sent = db.Column(db.Boolean, default=False)
    notification_sent_at = db.Column(db.DateTime(timezone=True))

    # User interaction
    acknowledged_by = db.Column(db.String(36), db.ForeignKey('users.id'))
    acknowledged_at = db.Column(db.DateTime(timezone=True))
    user_notes = db.Column(db.Text)

    created_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow, index=True)

    # Relationships
    device = db.relationship('Device', back_populates='events')
    video_clip = db.relationship('Video', foreign_keys=[video_clip_id])
    acknowledged_by_user = db.relationship('User', foreign_keys=[acknowledged_by])

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'device_id': self.device_id,
            'event_type': self.event_type,
            'severity': self.severity,
            'confidence_score': self.confidence_score,
            'metadata': self.metadata,
            'thumbnail_url': self.thumbnail_url,
            'video_clip_id': self.video_clip_id,
            'timestamp_in_video': self.timestamp_in_video,
            'notification_sent': self.notification_sent,
            'notification_sent_at': self.notification_sent_at.isoformat() if self.notification_sent_at else None,
            'acknowledged_by': self.acknowledged_by,
            'acknowledged_at': self.acknowledged_at.isoformat() if self.acknowledged_at else None,
            'user_notes': self.user_notes,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

    def __repr__(self):
        return f'<Event {self.event_type} at {self.created_at}>'
