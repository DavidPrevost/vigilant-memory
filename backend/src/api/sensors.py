"""
Sensors API Endpoints (TimescaleDB)
"""
from flask import Blueprint, request, jsonify, current_app
from datetime import datetime, timedelta

from ..models import Device, timescale_db
from ..utils.auth import require_auth, require_device_auth, get_current_user

sensors_bp = Blueprint('sensors', __name__)


@sensors_bp.route('/readings', methods=['POST'])
@require_device_auth
def submit_sensor_reading():
    """Submit sensor reading from device"""
    data = request.get_json()

    if not data or not data.get('device_id') or not data.get('sensor_type') or 'value' not in data:
        return jsonify({'error': 'device_id, sensor_type, and value are required'}), 400

    device = Device.query.get(data['device_id'])
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    try:
        # Insert into TimescaleDB
        query = """
            INSERT INTO sensor_readings (time, device_id, sensor_type, value, unit, metadata)
            VALUES (NOW(), %s, %s, %s, %s, %s)
        """
        params = (
            data['device_id'],
            data['sensor_type'],
            float(data['value']),
            data.get('unit'),
            str(data.get('metadata', {}))
        )

        timescale_db.execute(query, params)

        return jsonify({'status': 'recorded'}), 201

    except Exception as e:
        current_app.logger.error(f'Error recording sensor reading: {str(e)}')
        return jsonify({'error': 'Failed to record reading'}), 500


@sensors_bp.route('/readings', methods=['GET'])
@require_auth
def get_sensor_readings():
    """Get sensor readings"""
    current_user = get_current_user()

    device_id = request.args.get('device_id')
    sensor_type = request.args.get('sensor_type')
    hours = int(request.args.get('hours', 24))
    limit = int(request.args.get('limit', 1000))

    if not device_id:
        return jsonify({'error': 'device_id is required'}), 400

    if not current_user.can_access_device(device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    try:
        query = """
            SELECT time, sensor_type, value, unit
            FROM sensor_readings
            WHERE device_id = %s
              AND time >= NOW() - INTERVAL '%s hours'
        """
        params = [device_id, hours]

        if sensor_type:
            query += " AND sensor_type = %s"
            params.append(sensor_type)

        query += " ORDER BY time DESC LIMIT %s"
        params.append(limit)

        results = timescale_db.execute(query, tuple(params))

        readings = []
        for row in results:
            readings.append({
                'time': row[0].isoformat(),
                'sensor_type': row[1],
                'value': float(row[2]),
                'unit': row[3]
            })

        return jsonify({
            'readings': readings,
            'count': len(readings)
        })

    except Exception as e:
        current_app.logger.error(f'Error fetching sensor readings: {str(e)}')
        return jsonify({'error': 'Failed to fetch readings'}), 500


@sensors_bp.route('/latest', methods=['GET'])
@require_auth
def get_latest_readings():
    """Get latest sensor readings for device"""
    current_user = get_current_user()

    device_id = request.args.get('device_id')
    if not device_id:
        return jsonify({'error': 'device_id is required'}), 400

    if not current_user.can_access_device(device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    try:
        query = """
            SELECT DISTINCT ON (sensor_type)
                sensor_type, value, unit, time
            FROM sensor_readings
            WHERE device_id = %s
            ORDER BY sensor_type, time DESC
        """

        results = timescale_db.execute(query, (device_id,))

        latest = {}
        for row in results:
            latest[row[0]] = {
                'value': float(row[1]),
                'unit': row[2],
                'time': row[3].isoformat()
            }

        return jsonify(latest)

    except Exception as e:
        current_app.logger.error(f'Error fetching latest readings: {str(e)}')
        return jsonify({'error': 'Failed to fetch latest readings'}), 500
