"""
Authentication and Authorization Utilities
"""
from functools import wraps
from flask import request, jsonify, current_app, g
import jwt
import hashlib

from ..models import User, Device


def get_current_user():
    """Get current authenticated user from request context"""
    return getattr(g, 'current_user', None)


def require_auth(f):
    """Decorator to require user authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get token from Authorization header
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'error': 'No authorization token provided'}), 401

        try:
            # Expected format: "Bearer <token>"
            token_type, token = auth_header.split(' ')
            if token_type.lower() != 'bearer':
                return jsonify({'error': 'Invalid authorization type'}), 401

            # Decode JWT token
            payload = jwt.decode(
                token,
                current_app.config['JWT_SECRET_KEY'],
                algorithms=[current_app.config['JWT_ALGORITHM']]
            )

            # Get user from database
            user_id = payload.get('user_id')
            user = User.query.get(user_id)

            if not user or user.account_status != 'active':
                return jsonify({'error': 'Invalid or inactive user'}), 401

            # Store user in request context
            g.current_user = user

            return f(*args, **kwargs)

        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid token'}), 401
        except Exception as e:
            current_app.logger.error(f'Auth error: {str(e)}')
            return jsonify({'error': 'Authentication failed'}), 401

    return decorated_function


def require_device_auth(f):
    """Decorator to require device authentication"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Get device credentials from headers
        device_id = request.headers.get('X-Device-ID')
        device_secret = request.headers.get('X-Device-Secret')

        if not device_id or not device_secret:
            return jsonify({'error': 'Device credentials required'}), 401

        try:
            # Get device from database
            device = Device.query.get(device_id)
            if not device:
                return jsonify({'error': 'Device not found'}), 404

            # Verify device secret
            secret_hash = hashlib.sha256(device_secret.encode()).hexdigest()
            if secret_hash != device.device_secret_hash:
                return jsonify({'error': 'Invalid device credentials'}), 401

            # Store device in request context
            g.current_device = device

            return f(*args, **kwargs)

        except Exception as e:
            current_app.logger.error(f'Device auth error: {str(e)}')
            return jsonify({'error': 'Device authentication failed'}), 401

    return decorated_function


def generate_user_token(user_id):
    """Generate JWT token for user"""
    from datetime import datetime, timedelta

    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=current_app.config['JWT_EXPIRATION_HOURS']),
        'iat': datetime.utcnow()
    }

    token = jwt.encode(
        payload,
        current_app.config['JWT_SECRET_KEY'],
        algorithm=current_app.config['JWT_ALGORITHM']
    )

    return token
