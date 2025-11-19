"""
Video Uploader Service
Handles uploading video recordings to backend
"""
import logging
import os
import threading
import queue
from pathlib import Path
from typing import Optional
from datetime import datetime
import time

from backend_client import BackendClient
from config import config

logger = logging.getLogger(__name__)


class VideoUploadTask:
    """Represents a video upload task"""

    def __init__(self, video_path: str, recording_type: str = 'event_triggered',
                 recorded_at: Optional[datetime] = None, event_id: Optional[str] = None):
        self.video_path = Path(video_path)
        self.recording_type = recording_type
        self.recorded_at = recorded_at or datetime.utcnow()
        self.event_id = event_id
        self.attempts = 0
        self.max_attempts = 3


class VideoUploader:
    """Manages video upload queue and uploads to backend"""

    def __init__(self, backend_client: BackendClient):
        self.backend_client = backend_client
        self.upload_queue = queue.Queue()
        self.is_running = False
        self.upload_thread: Optional[threading.Thread] = None
        self.upload_stats = {
            'total': 0,
            'success': 0,
            'failed': 0
        }

    def start(self):
        """Start upload worker thread"""
        if self.is_running:
            logger.warning("Video uploader already running")
            return

        self.is_running = True
        self.upload_thread = threading.Thread(target=self._upload_worker, daemon=True)
        self.upload_thread.start()
        logger.info("Video uploader started")

    def stop(self):
        """Stop upload worker thread"""
        self.is_running = False
        if self.upload_thread:
            self.upload_thread.join(timeout=30)
        logger.info("Video uploader stopped")

    def queue_upload(self, video_path: str, recording_type: str = 'event_triggered',
                     recorded_at: Optional[datetime] = None, event_id: Optional[str] = None):
        """
        Add video to upload queue

        Args:
            video_path: Path to video file
            recording_type: Type of recording
            recorded_at: When video was recorded
            event_id: Associated event ID
        """
        task = VideoUploadTask(video_path, recording_type, recorded_at, event_id)
        self.upload_queue.put(task)
        logger.info(f"Queued video for upload: {video_path}")

    def _upload_worker(self):
        """Worker thread that processes upload queue"""
        logger.info("Upload worker thread started")

        while self.is_running:
            try:
                # Get task from queue (with timeout to allow checking is_running)
                try:
                    task = self.upload_queue.get(timeout=1.0)
                except queue.Empty:
                    continue

                # Process upload
                success = self._upload_video(task)

                if success:
                    self.upload_stats['success'] += 1
                    # Delete local file after successful upload
                    self._cleanup_video(task.video_path)
                else:
                    task.attempts += 1
                    if task.attempts < task.max_attempts:
                        # Re-queue with exponential backoff
                        logger.info(f"Re-queuing upload (attempt {task.attempts}/{task.max_attempts})")
                        time.sleep(2 ** task.attempts)  # 2, 4, 8 seconds
                        self.upload_queue.put(task)
                    else:
                        logger.error(f"Upload failed after {task.max_attempts} attempts: {task.video_path}")
                        self.upload_stats['failed'] += 1
                        # Move to failed directory
                        self._move_to_failed(task.video_path)

                self.upload_queue.task_done()
                self.upload_stats['total'] += 1

            except Exception as e:
                logger.error(f"Error in upload worker: {e}")
                time.sleep(1)

        logger.info("Upload worker thread stopped")

    def _upload_video(self, task: VideoUploadTask) -> bool:
        """
        Upload video file to backend

        Args:
            task: Upload task

        Returns:
            True if successful
        """
        if not task.video_path.exists():
            logger.error(f"Video file not found: {task.video_path}")
            return False

        logger.info(f"Uploading video: {task.video_path.name}")

        try:
            with open(task.video_path, 'rb') as video_file:
                video_id = self.backend_client.upload_video(
                    video_file,
                    task.video_path.name,
                    recording_type=task.recording_type,
                    recorded_at=task.recorded_at
                )

            if video_id:
                logger.info(f"Video uploaded successfully: {video_id}")
                return True
            else:
                logger.error(f"Video upload failed: {task.video_path.name}")
                return False

        except Exception as e:
            logger.error(f"Error uploading video: {e}")
            return False

    def _cleanup_video(self, video_path: Path):
        """Delete video file after successful upload"""
        try:
            if video_path.exists():
                video_path.unlink()
                logger.info(f"Deleted video after upload: {video_path}")
        except Exception as e:
            logger.error(f"Error deleting video: {e}")

    def _move_to_failed(self, video_path: Path):
        """Move failed upload to failed directory"""
        try:
            failed_dir = video_path.parent / 'failed'
            failed_dir.mkdir(exist_ok=True)

            new_path = failed_dir / video_path.name
            video_path.rename(new_path)
            logger.info(f"Moved failed upload to: {new_path}")

        except Exception as e:
            logger.error(f"Error moving failed video: {e}")

    def get_stats(self):
        """Get upload statistics"""
        return {
            **self.upload_stats,
            'queued': self.upload_queue.qsize(),
            'is_running': self.is_running
        }

    def wait_for_uploads(self, timeout: Optional[int] = None):
        """
        Wait for all uploads to complete

        Args:
            timeout: Maximum time to wait in seconds
        """
        self.upload_queue.join()
        logger.info("All uploads complete")
