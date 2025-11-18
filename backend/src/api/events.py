"""
Events API Endpoints
"""
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime, timedelta

from ..models import db, Event, Device
from ..utils.auth import require_auth, require_device_auth, get_current_user

events_bp = Blueprint('events', __name__)


@events_bp.route('/', methods=['POST'])
@require_device_auth
def create_event():
    """Create a new event (called by device)"""
    data = request.get_json()

    if not data or not data.get('device_id') or not data.get('event_type'):
        return jsonify({'error': 'device_id and event_type are required'}), 400

    device = Device.query.get(data['device_id'])
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    try:
        event = Event(
            device_id=data['device_id'],
            event_type=data['event_type'],
            severity=data.get('severity', 'info'),
            confidence_score=data.get('confidence_score'),
            metadata=data.get('metadata', {}),
            thumbnail_url=data.get('thumbnail_url'),
            video_clip_id=data.get('video_clip_id')
        )

        db.session.add(event)
        db.session.commit()

        current_app.logger.info(f'Event created: {event.event_type} for device {device.id}')

        return jsonify(event.to_dict()), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error creating event: {str(e)}')
        return jsonify({'error': 'Failed to create event'}), 500


@events_bp.route('/', methods=['GET'])
@require_auth
def get_events():
    """Get events for user's devices"""
    current_user = get_current_user()

    # Query parameters
    device_id = request.args.get('device_id')
    event_type = request.args.get('event_type')
    severity = request.args.get('severity')
    days = int(request.args.get('days', 7))
    limit = int(request.args.get('limit', 100))

    # Build query
    query = Event.query

    # Filter by device (must be user's device)
    if device_id:
        device = Device.query.get(device_id)
        if not device or not current_user.can_access_device(device_id):
            return jsonify({'error': 'Unauthorized'}), 403
        query = query.filter_by(device_id=device_id)
    else:
        # Get events from all user's devices
        device_ids = [d.id for d in current_user.devices]
        query = query.filter(Event.device_id.in_(device_ids))

    # Additional filters
    if event_type:
        query = query.filter_by(event_type=event_type)
    if severity:
        query = query.filter_by(severity=severity)

    # Time range
    since = datetime.utcnow() - timedelta(days=days)
    query = query.filter(Event.created_at >= since)

    # Order and limit
    events = query.order_by(Event.created_at.desc()).limit(limit).all()

    return jsonify({
        'events': [event.to_dict() for event in events],
        'count': len(events)
    })


@events_bp.route('/<event_id>', methods='GET'])
@require_auth
def get_event(event_id):
    """Get single event"""
    current_user = get_current_user()

    event = Event.query.get(event_id)
    if not event:
        return jsonify({'error': 'Event not found'}), 404

    # Check access to device
    if not current_user.can_access_device(event.device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    return jsonify(event.to_dict())


@events_bp.route('/<event_id>/acknowledge', methods=['POST'])
@require_auth
def acknowledge_event(event_id):
    """Acknowledge an event"""
    current_user = get_current_user()

    event = Event.query.get(event_id)
    if not event:
        return jsonify({'error': 'Event not found'}), 404

    if not current_user.can_access_device(event.device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    data = request.get_json() or {}

    try:
        event.acknowledged_by = current_user.id
        event.acknowledged_at = datetime.utcnow()
        event.user_notes = data.get('notes')

        db.session.commit()

        return jsonify(event.to_dict())

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error acknowledging event: {str(e)}')
        return jsonify({'error': 'Failed to acknowledge event'}), 500
