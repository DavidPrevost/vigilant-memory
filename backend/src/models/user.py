"""
User Model
"""
from datetime import datetime
from .database import db
import uuid


class User(db.Model):
    """User account model"""
    __tablename__ = 'users'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    firebase_uid = db.Column(db.String(128), unique=True, nullable=False, index=True)
    email = db.Column(db.String(255), unique=True, nullable=False, index=True)
    display_name = db.Column(db.String(255))
    phone_number = db.Column(db.String(20))
    avatar_url = db.Column(db.Text)

    # Subscription
    subscription_tier = db.Column(db.String(20), default='free', index=True)
    # Tiers: free, cloud_storage, ai_insights, complete
    subscription_expires_at = db.Column(db.DateTime(timezone=True))

    # Encryption
    e2e_encryption_enabled = db.Column(db.Boolean, default=False)
    e2e_public_key = db.Column(db.Text)

    # Timestamps
    created_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login_at = db.Column(db.DateTime(timezone=True))

    # Status
    account_status = db.Column(db.String(20), default='active')
    # Status: active, suspended, deleted

    # Relationships
    devices = db.relationship('Device', back_populates='owner', lazy='dynamic', cascade='all, delete-orphan')
    shared_devices = db.relationship('SharedDevice', back_populates='user', lazy='dynamic')
    notifications = db.relationship('Notification', back_populates='user', lazy='dynamic', cascade='all, delete-orphan')
    subscriptions = db.relationship('Subscription', back_populates='user', lazy='dynamic', cascade='all, delete-orphan')
    activity_logs = db.relationship('ActivityLog', back_populates='user', lazy='dynamic')

    def to_dict(self, include_sensitive=False):
        """Convert to dictionary"""
        data = {
            'id': self.id,
            'email': self.email,
            'display_name': self.display_name,
            'phone_number': self.phone_number,
            'avatar_url': self.avatar_url,
            'subscription_tier': self.subscription_tier,
            'subscription_expires_at': self.subscription_expires_at.isoformat() if self.subscription_expires_at else None,
            'e2e_encryption_enabled': self.e2e_encryption_enabled,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'last_login_at': self.last_login_at.isoformat() if self.last_login_at else None,
            'account_status': self.account_status
        }

        if include_sensitive:
            data['firebase_uid'] = self.firebase_uid
            data['e2e_public_key'] = self.e2e_public_key

        return data

    def has_active_subscription(self, tier=None):
        """Check if user has active subscription"""
        if tier:
            return self.subscription_tier == tier and (
                not self.subscription_expires_at or
                self.subscription_expires_at > datetime.utcnow()
            )
        return self.subscription_tier != 'free' and (
            not self.subscription_expires_at or
            self.subscription_expires_at > datetime.utcnow()
        )

    def can_access_device(self, device_id):
        """Check if user can access a device"""
        # Check if owner
        if self.devices.filter_by(id=device_id).first():
            return True

        # Check if shared
        from .device import SharedDevice
        shared = SharedDevice.query.filter_by(
            device_id=device_id,
            user_id=self.id,
            is_active=True
        ).first()

        if shared and (not shared.expires_at or shared.expires_at > datetime.utcnow()):
            return True

        return False

    def __repr__(self):
        return f'<User {self.email}>'
