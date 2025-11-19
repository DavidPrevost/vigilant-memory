"""
Devices API Endpoints
"""
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime
import uuid
import hashlib

from ..models import db, Device, User, SharedDevice, ActivityLog
from ..utils.auth import require_auth, require_device_auth, get_current_user

devices_bp = Blueprint('devices', __name__)


@devices_bp.route('/', methods=['POST'])
@require_auth
def register_device():
    """Register a new device"""
    current_user = get_current_user()
    data = request.get_json()

    # Validate required fields
    if not data or not data.get('device_name'):
        return jsonify({'error': 'device_name is required'}), 400

    try:
        # Generate device credentials
        device_secret = str(uuid.uuid4())
        device_secret_hash = hashlib.sha256(device_secret.encode()).hexdigest()
        mqtt_client_id = f"device_{uuid.uuid4().hex[:12]}"

        # Create device
        device = Device(
            owner_id=current_user.id,
            device_name=data['device_name'],
            device_type=data.get('device_type', 'monitor'),
            model=data.get('model', 'prototype'),
            serial_number=data.get('serial_number'),
            device_secret_hash=device_secret_hash,
            mqtt_client_id=mqtt_client_id,
            settings=data.get('settings', {}),
            capabilities=data.get('capabilities', {}),
            location_name=data.get('location_name'),
            timezone=data.get('timezone', 'UTC')
        )

        db.session.add(device)
        db.session.commit()

        # Log activity
        log = ActivityLog(
            user_id=current_user.id,
            device_id=device.id,
            action='device_registered',
            resource_type='device',
            resource_id=device.id,
            ip_address=request.remote_addr
        )
        db.session.add(log)
        db.session.commit()

        current_app.logger.info(f'Device registered: {device.id} by user {current_user.id}')

        # Return device info with credentials (only shown once!)
        response = device.to_dict(include_credentials=True)
        response['device_secret'] = device_secret  # Only returned once

        return jsonify(response), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error registering device: {str(e)}')
        return jsonify({'error': 'Failed to register device'}), 500


@devices_bp.route('/<device_id>', methods=['GET'])
@require_auth
def get_device(device_id):
    """Get device by ID"""
    current_user = get_current_user()

    device = Device.query.get(device_id)
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    # Check access permission
    if not current_user.can_access_device(device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    return jsonify(device.to_dict())


@devices_bp.route('/<device_id>', methods=['PUT'])
@require_auth
def update_device(device_id):
    """Update device settings"""
    current_user = get_current_user()

    device = Device.query.get(device_id)
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    # Only owner can update device
    if device.owner_id != current_user.id:
        return jsonify({'error': 'Unauthorized'}), 403

    data = request.get_json()

    try:
        # Update allowed fields
        if 'device_name' in data:
            device.device_name = data['device_name']
        if 'settings' in data:
            device.settings = data['settings']
        if 'location_name' in data:
            device.location_name = data['location_name']
        if 'timezone' in data:
            device.timezone = data['timezone']

        db.session.commit()

        return jsonify(device.to_dict())

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error updating device: {str(e)}')
        return jsonify({'error': 'Failed to update device'}), 500


@devices_bp.route('/<device_id>', methods=['DELETE'])
@require_auth
def delete_device(device_id):
    """Delete device"""
    current_user = get_current_user()

    device = Device.query.get(device_id)
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    if device.owner_id != current_user.id:
        return jsonify({'error': 'Unauthorized'}), 403

    try:
        db.session.delete(device)
        db.session.commit()

        current_app.logger.info(f'Device deleted: {device_id}')

        return jsonify({'message': 'Device deleted'})

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error deleting device: {str(e)}')
        return jsonify({'error': 'Failed to delete device'}), 500


@devices_bp.route('/<device_id>/status', methods=['POST'])
@require_device_auth
def update_device_status(device_id):
    """Update device status (called by device)"""
    device = Device.query.get(device_id)
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    data = request.get_json() or {}

    try:
        # Update status fields
        device.online_status = True
        device.last_seen_at = datetime.utcnow()

        if 'battery_level' in data:
            device.battery_level = data['battery_level']
        if 'power_source' in data:
            device.power_source = data['power_source']
        if 'signal_strength' in data:
            device.signal_strength = data['signal_strength']
        if 'ip_address' in data:
            device.ip_address = data['ip_address']
        if 'firmware_version' in data:
            device.firmware_version = data['firmware_version']

        db.session.commit()

        return jsonify({'status': 'updated'})

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error updating device status: {str(e)}')
        return jsonify({'error': 'Failed to update status'}), 500


@devices_bp.route('/<device_id>/share', methods=['POST'])
@require_auth
def share_device(device_id):
    """Share device with another user"""
    current_user = get_current_user()

    device = Device.query.get(device_id)
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    if device.owner_id != current_user.id:
        return jsonify({'error': 'Only device owner can share'}), 403

    data = request.get_json()
    if not data or not data.get('email'):
        return jsonify({'error': 'User email is required'}), 400

    # Find user to share with
    share_user = User.query.filter_by(email=data['email']).first()
    if not share_user:
        return jsonify({'error': 'User not found'}), 404

    try:
        # Create share
        share = SharedDevice(
            device_id=device_id,
            user_id=share_user.id,
            shared_by=current_user.id,
            permission_level=data.get('permission_level', 'viewer'),
            expires_at=data.get('expires_at')
        )

        db.session.add(share)
        db.session.commit()

        return jsonify(share.to_dict()), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error sharing device: {str(e)}')
        return jsonify({'error': 'Failed to share device'}), 500
