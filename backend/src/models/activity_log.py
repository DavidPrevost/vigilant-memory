"""
Activity Log Model
"""
from datetime import datetime
from .database import db
import uuid


class ActivityLog(db.Model):
    """Activity log model"""
    __tablename__ = 'activity_logs'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id', ondelete='SET NULL'))
    device_id = db.Column(db.String(36), db.ForeignKey('devices.id', ondelete='SET NULL'))

    # Activity details
    action = db.Column(db.String(100), nullable=False, index=True)
    resource_type = db.Column(db.String(50))
    resource_id = db.Column(db.String(36))

    # Context
    ip_address = db.Column(db.String(45))
    user_agent = db.Column(db.Text)
    metadata = db.Column(db.JSON, default={})

    created_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow, index=True)

    # Relationships
    user = db.relationship('User', back_populates='activity_logs')
    device = db.relationship('Device', back_populates='activity_logs')

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'device_id': self.device_id,
            'action': self.action,
            'resource_type': self.resource_type,
            'resource_id': self.resource_id,
            'ip_address': self.ip_address,
            'user_agent': self.user_agent,
            'metadata': self.metadata,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

    def __repr__(self):
        return f'<ActivityLog {self.action} at {self.created_at}>'
