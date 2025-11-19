"""
Subscription Model
"""
from datetime import datetime
from .database import db
import uuid


class Subscription(db.Model):
    """Subscription model"""
    __tablename__ = 'subscriptions'

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = db.Column(db.String(36), db.ForeignKey('users.id', ondelete='CASCADE'), nullable=False, index=True)

    # Subscription details
    tier = db.Column(db.String(20), nullable=False)  # free, cloud_storage, ai_insights, complete
    status = db.Column(db.String(20), default='active', index=True)  # active, cancelled, expired, failed

    # Billing
    stripe_subscription_id = db.Column(db.String(100), unique=True)
    stripe_customer_id = db.Column(db.String(100))
    billing_period = db.Column(db.String(20))  # monthly, yearly
    price_cents = db.Column(db.Integer)
    currency = db.Column(db.String(3), default='USD')

    # Dates
    started_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)
    current_period_start = db.Column(db.DateTime(timezone=True))
    current_period_end = db.Column(db.DateTime(timezone=True))
    cancelled_at = db.Column(db.DateTime(timezone=True))
    ended_at = db.Column(db.DateTime(timezone=True))

    # Trial
    trial_end = db.Column(db.DateTime(timezone=True))

    created_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow)
    updated_at = db.Column(db.DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = db.relationship('User', back_populates='subscriptions')

    def to_dict(self):
        """Convert to dictionary"""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'tier': self.tier,
            'status': self.status,
            'billing_period': self.billing_period,
            'price_cents': self.price_cents,
            'currency': self.currency,
            'started_at': self.started_at.isoformat() if self.started_at else None,
            'current_period_start': self.current_period_start.isoformat() if self.current_period_start else None,
            'current_period_end': self.current_period_end.isoformat() if self.current_period_end else None,
            'cancelled_at': self.cancelled_at.isoformat() if self.cancelled_at else None,
            'ended_at': self.ended_at.isoformat() if self.ended_at else None,
            'trial_end': self.trial_end.isoformat() if self.trial_end else None,
            'created_at': self.created_at.isoformat() if self.created_at else None
        }

    def __repr__(self):
        return f'<Subscription {self.tier} for {self.user_id}>'
