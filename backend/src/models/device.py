"""
Device Models
"""
from datetime import datetime
from .database import db
import uuid


class Device(db.Model):
    """Baby monitor device model"""
    __tablename__ = 'devices'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    owner_id = db.Column(db.String(36), db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    device_name = db.Column(db.String(255), nullable=False)
    device_type = db.Column(db.String(20), default='monitor')  # monitor, sensor_hub
    model = db.Column(db.String(50))  # prototype, core, pro
    firmware_version = db.Column(db.String(50))
    hardware_version = db.Column(db.String(50))
    serial_number = db.Column(db.String(100), unique=True)

    # Device credentials
    device_secret_hash = db.Column(db.Text, nullable=False)
    mqtt_client_id = db.Column(db.String(100), unique=True, nullable=False, index=True)

    # Configuration
    settings = db.Column(db.JSON, default={})
    capabilities = db.Column(db.JSON, default={})

    # Location
    location_name = db.Column(db.String(255))
    timezone = db.Column(db.String(50), default='UTC')

    # Status
    online_status = db.Column(db.Boolean, default=False, index=True)
    last_seen_at = db.Column(db.DateTime(timezone=True), index=True)
    battery_level = db.Column(db.Integer)  # 0-100
    power_source = db.Column(db.String(20))  # ac_power, battery, both

    # Network
    ip_address = db.Column(db.String(45))  # IPv6 support
    wifi_ssid = db.Column(db.String(100))
    signal_strength = db.Column(db.Integer)

    # Timestamps
    registered_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)
    activated_at = db.Column(db.DateTime(timezone=True))
    updated_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    owner = db.relationship('User', back_populates='devices')
    shared_with = db.relationship('SharedDevice', back_populates='device', lazy='dynamic', cascade='all, delete-orphan')
    events = db.relationship('Event', back_populates='device', lazy='dynamic', cascade='all, delete-orphan')
    videos = db.relationship('Video', back_populates='device', lazy='dynamic', cascade='all, delete-orphan')
    notifications = db.relationship('Notification', back_populates='device', lazy='dynamic')
    activity_logs = db.relationship('ActivityLog', back_populates='device', lazy='dynamic')

    def to_dict(self, include_credentials=False):
        """Convert to dictionary"""
        data = {
            'id': self.id,
            'owner_id': self.owner_id,
            'device_name': self.device_name,
            'device_type': self.device_type,
            'model': self.model,
            'firmware_version': self.firmware_version,
            'hardware_version': self.hardware_version,
            'serial_number': self.serial_number,
            'settings': self.settings,
            'capabilities': self.capabilities,
            'location_name': self.location_name,
            'timezone': self.timezone,
            'online_status': self.online_status,
            'last_seen_at': self.last_seen_at.isoformat() if self.last_seen_at else None,
            'battery_level': self.battery_level,
            'power_source': self.power_source,
            'ip_address': self.ip_address,
            'wifi_ssid': self.wifi_ssid,
            'signal_strength': self.signal_strength,
            'registered_at': self.registered_at.isoformat() if self.registered_at else None,
            'activated_at': self.activated_at.isoformat() if self.activated_at else None,
        }

        if include_credentials:
            data['mqtt_client_id'] = self.mqtt_client_id

        return data

    def is_online(self):
        """Check if device is currently online"""
        if not self.online_status:
            return False

        if not self.last_seen_at:
            return False

        # Consider offline if not seen in last 5 minutes
        timeout = datetime.utcnow() - self.last_seen_at
        return timeout.total_seconds() < 300

    def __repr__(self):
        return f'<Device {self.device_name} ({self.id})>'


class SharedDevice(db.Model):
    """Shared device access model"""
    __tablename__ = 'shared_devices'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    device_id = db.Column(db.String(36), db.ForeignKey('devices.id', ondelete='CASCADE'), nullable=False, index=True)
    user_id = db.Column(db.String(36), db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)
    permission_level = db.Column(db.String(20), default='viewer')  # viewer, controller, admin
    shared_by = db.Column(db.String(36), db.ForeignKey('users.id'), nullable=False)
    shared_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)
    expires_at = db.Column(db.DateTime(timezone=True))
    is_active = db.Column(db.Boolean, default=True)

    # Relationships
    device = db.relationship('Device', back_populates='shared_with')
    user = db.relationship('User', foreign_keys=[user_id], back_populates='shared_devices')
    shared_by_user = db.relationship('User', foreign_keys=[shared_by])

    # Unique constraint
    __table_args__ = (
        db.UniqueConstraint('device_id', 'user_id', name='unique_device_user'),
    )

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'device_id': self.device_id,
            'user_id': self.user_id,
            'permission_level': self.permission_level,
            'shared_by': self.shared_by,
            'shared_at': self.shared_at.isoformat() if self.shared_at else None,
            'expires_at': self.expires_at.isoformat() if self.expires_at else None,
            'is_active': self.is_active
        }

    def is_valid(self):
        """Check if share is valid"""
        if not self.is_active:
            return False

        if self.expires_at and self.expires_at < datetime.utcnow():
            return False

        return True

    def __repr__(self):
        return f'<SharedDevice {self.device_id} -> {self.user_id}>'
