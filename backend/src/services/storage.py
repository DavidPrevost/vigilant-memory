"""
Object Storage Service (MinIO/S3)
"""
from minio import Minio
from minio.error import S3Error
from datetime import timedelta
import io


class StorageService:
    """MinIO/S3 storage service"""

    def __init__(self):
        self.client = None
        self.video_bucket = None
        self.thumbnail_bucket = None

    def init_app(self, app):
        """Initialize with Flask app"""
        try:
            self.client = Minio(
                app.config['MINIO_ENDPOINT'],
                access_key=app.config['MINIO_ACCESS_KEY'],
                secret_key=app.config['MINIO_SECRET_KEY'],
                secure=app.config['MINIO_SECURE']
            )

            self.video_bucket = app.config['MINIO_BUCKET_VIDEOS']
            self.thumbnail_bucket = app.config['MINIO_BUCKET_THUMBNAILS']

            # Create buckets if they don't exist
            self._create_bucket_if_not_exists(self.video_bucket)
            self._create_bucket_if_not_exists(self.thumbnail_bucket)

            app.logger.info('Storage service initialized')

        except S3Error as e:
            app.logger.error(f'Error initializing storage service: {str(e)}')
            raise

    def _create_bucket_if_not_exists(self, bucket_name):
        """Create bucket if it doesn't exist"""
        try:
            if not self.client.bucket_exists(bucket_name):
                self.client.make_bucket(bucket_name)
        except S3Error as e:
            raise Exception(f'Error creating bucket {bucket_name}: {str(e)}')

    def upload_video(self, file_obj, filename):
        """Upload video file"""
        try:
            # Read file data
            file_data = file_obj.read()
            file_size = len(file_data)

            # Upload to MinIO
            self.client.put_object(
                self.video_bucket,
                filename,
                io.BytesIO(file_data),
                file_size,
                content_type='video/mp4'
            )

            return f"{self.video_bucket}/{filename}"

        except S3Error as e:
            raise Exception(f'Error uploading video: {str(e)}')

    def upload_thumbnail(self, file_obj, filename):
        """Upload thumbnail image"""
        try:
            file_data = file_obj.read()
            file_size = len(file_data)

            self.client.put_object(
                self.thumbnail_bucket,
                filename,
                io.BytesIO(file_data),
                file_size,
                content_type='image/jpeg'
            )

            return f"{self.thumbnail_bucket}/{filename}"

        except S3Error as e:
            raise Exception(f'Error uploading thumbnail: {str(e)}')

    def get_download_url(self, storage_path, expires=3600):
        """Generate presigned download URL"""
        try:
            # Parse bucket and object name from path
            parts = storage_path.split('/', 1)
            bucket_name = parts[0]
            object_name = parts[1] if len(parts) > 1 else parts[0]

            url = self.client.presigned_get_object(
                bucket_name,
                object_name,
                expires=timedelta(seconds=expires)
            )

            return url

        except S3Error as e:
            raise Exception(f'Error generating download URL: {str(e)}')

    def delete_video(self, storage_path):
        """Delete video from storage"""
        try:
            parts = storage_path.split('/', 1)
            bucket_name = parts[0]
            object_name = parts[1] if len(parts) > 1 else parts[0]

            self.client.remove_object(bucket_name, object_name)

        except S3Error as e:
            raise Exception(f'Error deleting video: {str(e)}')

    def get_video_stream(self, storage_path):
        """Get video stream"""
        try:
            parts = storage_path.split('/', 1)
            bucket_name = parts[0]
            object_name = parts[1] if len(parts) > 1 else parts[0]

            response = self.client.get_object(bucket_name, object_name)
            return response

        except S3Error as e:
            raise Exception(f'Error streaming video: {str(e)}')


# Global storage service instance
storage_service = StorageService()
