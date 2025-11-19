"""
Videos API Endpoints
"""
from flask import Blueprint, request, jsonify, current_app, send_file
from datetime import datetime, timedelta
from werkzeug.utils import secure_filename
import os

from ..models import db, Video, Device
from ..utils.auth import require_auth, require_device_auth, get_current_user
from ..services.storage import storage_service

videos_bp = Blueprint('videos', __name__)


@videos_bp.route('/upload', methods=['POST'])
@require_device_auth
def upload_video():
    """Upload video from device"""
    if 'video' not in request.files:
        return jsonify({'error': 'No video file provided'}), 400

    video_file = request.files['video']
    if video_file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    # Get metadata from form data
    device_id = request.form.get('device_id')
    recording_type = request.form.get('recording_type', 'event_triggered')
    recorded_at = request.form.get('recorded_at')

    if not device_id:
        return jsonify({'error': 'device_id is required'}), 400

    device = Device.query.get(device_id)
    if not device:
        return jsonify({'error': 'Device not found'}), 404

    try:
        # Generate unique filename
        filename = secure_filename(video_file.filename)
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        unique_filename = f"{device_id}_{timestamp}_{filename}"

        # Upload to storage
        storage_path = storage_service.upload_video(video_file, unique_filename)

        # Create video record
        video = Video(
            device_id=device_id,
            filename=unique_filename,
            storage_path=storage_path,
            storage_backend='minio',
            recording_type=recording_type,
            recorded_at=datetime.fromisoformat(recorded_at) if recorded_at else datetime.utcnow(),
            upload_status='processing'
        )

        # Calculate expiry based on user's subscription
        owner = device.owner
        retention_days = 30 if owner.has_active_subscription() else 7
        video.retention_days = retention_days
        video.calculate_expiry()

        db.session.add(video)
        db.session.commit()

        current_app.logger.info(f'Video uploaded: {video.id} from device {device_id}')

        return jsonify(video.to_dict()), 201

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error uploading video: {str(e)}')
        return jsonify({'error': 'Failed to upload video'}), 500


@videos_bp.route('/', methods=['GET'])
@require_auth
def get_videos():
    """Get videos for user's devices"""
    current_user = get_current_user()

    device_id = request.args.get('device_id')
    days = int(request.args.get('days', 7))
    limit = int(request.args.get('limit', 50))

    query = Video.query

    if device_id:
        if not current_user.can_access_device(device_id):
            return jsonify({'error': 'Unauthorized'}), 403
        query = query.filter_by(device_id=device_id)
    else:
        device_ids = [d.id for d in current_user.devices]
        query = query.filter(Video.device_id.in_(device_ids))

    # Time range
    since = datetime.utcnow() - timedelta(days=days)
    query = query.filter(Video.recorded_at >= since)

    # Filter out expired
    query = query.filter(Video.is_archived == False)

    videos = query.order_by(Video.recorded_at.desc()).limit(limit).all()

    return jsonify({
        'videos': [video.to_dict() for video in videos],
        'count': len(videos)
    })


@videos_bp.route('/<video_id>', methods=['GET'])
@require_auth
def get_video(video_id):
    """Get video metadata"""
    current_user = get_current_user()

    video = Video.query.get(video_id)
    if not video:
        return jsonify({'error': 'Video not found'}), 404

    if not current_user.can_access_device(video.device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    return jsonify(video.to_dict())


@videos_bp.route('/<video_id>/download', methods=['GET'])
@require_auth
def download_video(video_id):
    """Download video file"""
    current_user = get_current_user()

    video = Video.query.get(video_id)
    if not video:
        return jsonify({'error': 'Video not found'}), 404

    if not current_user.can_access_device(video.device_id):
        return jsonify({'error': 'Unauthorized'}), 403

    try:
        # Get presigned download URL from storage service
        download_url = storage_service.get_download_url(video.storage_path)

        return jsonify({
            'download_url': download_url,
            'expires_in': 3600  # 1 hour
        })

    except Exception as e:
        current_app.logger.error(f'Error generating download URL: {str(e)}')
        return jsonify({'error': 'Failed to generate download URL'}), 500


@videos_bp.route('/<video_id>', methods=['DELETE'])
@require_auth
def delete_video(video_id):
    """Delete video"""
    current_user = get_current_user()

    video = Video.query.get(video_id)
    if not video:
        return jsonify({'error': 'Video not found'}), 404

    # Only device owner can delete videos
    device = Device.query.get(video.device_id)
    if device.owner_id != current_user.id:
        return jsonify({'error': 'Unauthorized'}), 403

    try:
        # Delete from storage
        storage_service.delete_video(video.storage_path)

        # Delete record
        db.session.delete(video)
        db.session.commit()

        current_app.logger.info(f'Video deleted: {video_id}')

        return jsonify({'message': 'Video deleted'})

    except Exception as e:
        db.session.rollback()
        current_app.logger.error(f'Error deleting video: {str(e)}')
        return jsonify({'error': 'Failed to delete video'}), 500
