"""
Notification Model
"""
from datetime import datetime
from .database import db
import uuid


class Notification(db.Model):
    """Notification model"""
    __tablename__ = 'notifications'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    device_id = db.Column(db.String(36), db.ForeignKey('devices.id', ondelete='CASCADE'))
    event_id = db.Column(db.String(36), db.ForeignKey('events.id', ondelete='SET NULL'))

    # Content
    notification_type = db.Column(db.String(50), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    message = db.Column(db.Text, nullable=False)
    priority = db.Column(db.String(20), default='normal')  # low, normal, high, urgent

    # Delivery
    delivery_channels = db.Column(db.JSON, default=['app'])
    sent_at = db.Column(db.DateTime(timezone=True))
    delivery_status = db.Column(db.String(20), default='pending', index=True)

    # User interaction
    read_at = db.Column(db.DateTime(timezone=True), index=True)
    action_taken = db.Column(db.String(50))

    created_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow, index=True)
    expires_at = db.Column(db.DateTime(timezone=True))

    # Relationships
    user = db.relationship('User', back_populates='notifications')
    device = db.relationship('Device', back_populates='notifications')
    event = db.relationship('Event')

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'device_id': self.device_id,
            'event_id': self.event_id,
            'notification_type': self.notification_type,
            'title': self.title,
            'message': self.message,
            'priority': self.priority,
            'delivery_channels': self.delivery_channels,
            'sent_at': self.sent_at.isoformat() if self.sent_at else None,
            'delivery_status': self.delivery_status,
            'read_at': self.read_at.isoformat() if self.read_at else None,
            'action_taken': self.action_taken,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None
        }

    def mark_as_read(self):
        """Mark notification as read"""
        if not self.read_at:
            self.read_at = datetime.utcnow()

    def __repr__(self):
        return f'<Notification {self.notification_type} to {self.user_id}>'
