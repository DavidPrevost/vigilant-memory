"""
Users API Endpoints
"""
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime

from ..models import db, User, ActivityLog
from ..utils.auth import require_auth, get_current_user
from ..utils.validators import validate_email

users_bp = Blueprint('users', __name__)


@users_bp.route('/', methods=['POST'])
def create_user():
    """Create a new user"""
    data = request.get_json()

    # Validate required fields
    if not data or not data.get('firebase_uid') or not data.get('email'):
        return jsonify({'error': 'firebase_uid and email are required'}), 400

    # Validate email format
    if not validate_email(data['email']):
        return jsonify({'error': 'Invalid email format'}), 400

    # Check if user already exists
    existing_user = User.query.filter_by(firebase_uid=data['firebase_uid']).first()
    if existing_user:
        return jsonify({'error': 'User already exists'}), 409

    try:
        # Create user
        user = User(
            firebase_uid=data['firebase_uid'],
            email=data['email'],
            display_name=data.get('display_name'),
            phone_number=data.get('phone_number'),
            avatar_url=data.get('avatar_url'),
            subscription_tier=data.get('subscription_tier', 'free')
        )

        db.session.add(user)
        db.session.commit()

        # Log activity
        log_activity(user.id, 'user_created', request)

        current_app.logger.info(f'User created: {user.email}')

        return jsonify(user.to_dict()), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error creating user: {str(e)}')
        return jsonify({'error': 'Failed to create user'}), 500


@users_bp.route('/<user_id>', methods=['GET'])
@require_auth
def get_user(user_id):
    """Get user by ID"""
    current_user = get_current_user()

    # Users can only view their own profile (unless admin in future)
    if current_user.id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    return jsonify(user.to_dict())


@users_bp.route('/<user_id>', methods=['PUT'])
@require_auth
def update_user(user_id):
    """Update user profile"""
    current_user = get_current_user()

    if current_user.id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    data = request.get_json()

    try:
        # Update allowed fields
        if 'display_name' in data:
            user.display_name = data['display_name']
        if 'phone_number' in data:
            user.phone_number = data['phone_number']
        if 'avatar_url' in data:
            user.avatar_url = data['avatar_url']
        if 'e2e_encryption_enabled' in data:
            user.e2e_encryption_enabled = data['e2e_encryption_enabled']
        if 'e2e_public_key' in data:
            user.e2e_public_key = data['e2e_public_key']

        db.session.commit()

        log_activity(user.id, 'user_updated', request)

        return jsonify(user.to_dict())

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error updating user: {str(e)}')
        return jsonify({'error': 'Failed to update user'}), 500


@users_bp.route('/<user_id>', methods=['DELETE'])
@require_auth
def delete_user(user_id):
    """Delete user account"""
    current_user = get_current_user()

    if current_user.id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    try:
        # Soft delete by updating status
        user.account_status = 'deleted'
        db.session.commit()

        log_activity(user.id, 'user_deleted', request)

        return jsonify({'message': 'User account deleted'})

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error deleting user: {str(e)}')
        return jsonify({'error': 'Failed to delete user'}), 500


@users_bp.route('/<user_id>/devices', methods=['GET'])
@require_auth
def get_user_devices(user_id):
    """Get all devices owned by user"""
    current_user = get_current_user()

    if current_user.id != user_id:
        return jsonify({'error': 'Unauthorized'}), 403

    user = User.query.get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404

    devices = [device.to_dict() for device in user.devices]

    return jsonify({
        'devices': devices,
        'count': len(devices)
    })


def log_activity(user_id, action, request):
    """Helper to log user activity"""
    try:
        log = ActivityLog(
            user_id=user_id,
            action=action,
            resource_type='user',
            resource_id=user_id,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent')
        )
        db.session.add(log)
        db.session.commit()
    except Exception as e:
        current_app.logger.warning(f'Failed to log activity: {str(e)}')
