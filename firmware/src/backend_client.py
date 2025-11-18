"""
Backend API Client
Handles all HTTP communication with the backend server
"""
import requests
import logging
from typing import Optional, Dict, Any, BinaryIO
from datetime import datetime
import time

logger = logging.getLogger(__name__)


class BackendClient:
    """Client for backend API communication"""

    def __init__(self, base_url: str, device_id: Optional[str] = None, device_secret: Optional[str] = None):
        self.base_url = base_url.rstrip('/')
        self.device_id = device_id
        self.device_secret = device_secret
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'BabyMonitor-Firmware/1.0'
        })

    def _get_device_headers(self) -> Dict[str, str]:
        """Get authentication headers for device"""
        if not self.device_id or not self.device_secret:
            raise ValueError("Device credentials not set")

        return {
            'X-Device-ID': self.device_id,
            'X-Device-Secret': self.device_secret
        }

    def _request(self, method: str, endpoint: str, **kwargs) -> Optional[Dict[str, Any]]:
        """Make HTTP request with error handling"""
        url = f"{self.base_url}{endpoint}"

        try:
            response = self.session.request(method, url, timeout=30, **kwargs)
            response.raise_for_status()

            if response.content:
                return response.json()
            return {}

        except requests.exceptions.ConnectionError as e:
            logger.error(f"Connection error to backend: {e}")
            return None
        except requests.exceptions.Timeout:
            logger.error(f"Request timeout for {endpoint}")
            return None
        except requests.exceptions.HTTPError as e:
            logger.error(f"HTTP error {e.response.status_code} for {endpoint}: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in request: {e}")
            return None

    def register_device(self, device_name: str, model: str = "prototype") -> Optional[Dict[str, Any]]:
        """
        Register device with backend

        Returns:
            Device registration data including device_id, device_secret, mqtt_client_id
        """
        logger.info(f"Registering device: {device_name}")

        # For device registration, we need a user token
        # In production, this would be done through an app
        # For now, we'll create a development user
        data = {
            'device_name': device_name,
            'device_type': 'monitor',
            'model': model,
            'capabilities': {
                'video': True,
                'audio': False,  # Phase 2
                'sensors': False  # Phase 3
            }
        }

        # Note: This requires user authentication
        # In real deployment, registration happens through mobile app
        # For development, you'd need to set up a dev user first
        response = self._request('POST', '/api/devices', json=data)

        if response:
            logger.info(f"Device registered successfully: {response.get('id')}")
            # Store credentials
            self.device_id = response.get('id')
            self.device_secret = response.get('device_secret')

        return response

    def update_status(self, status_data: Dict[str, Any]) -> bool:
        """
        Update device status

        Args:
            status_data: Status information (battery, signal, etc.)
        """
        if not self.device_id:
            logger.error("Device not registered")
            return False

        endpoint = f"/api/devices/{self.device_id}/status"
        headers = self._get_device_headers()

        response = self._request('POST', endpoint, json=status_data, headers=headers)
        return response is not None

    def create_event(self, event_type: str, severity: str = 'info',
                     confidence: Optional[float] = None,
                     metadata: Optional[Dict] = None) -> Optional[str]:
        """
        Create an event

        Args:
            event_type: Type of event (motion_detected, sound_detected, etc.)
            severity: Event severity (info, warning, alert, critical)
            confidence: AI confidence score (0.0-1.0)
            metadata: Additional event data

        Returns:
            Event ID if successful
        """
        if not self.device_id:
            logger.error("Device not registered")
            return None

        data = {
            'device_id': self.device_id,
            'event_type': event_type,
            'severity': severity,
            'confidence_score': confidence,
            'metadata': metadata or {}
        }

        headers = self._get_device_headers()
        response = self._request('POST', '/api/events', json=data, headers=headers)

        if response:
            event_id = response.get('id')
            logger.info(f"Event created: {event_type} ({event_id})")
            return event_id

        return None

    def upload_video(self, video_file: BinaryIO, filename: str,
                     recording_type: str = 'event_triggered',
                     recorded_at: Optional[datetime] = None) -> Optional[str]:
        """
        Upload video file to backend

        Args:
            video_file: File object or path to video file
            filename: Name of the video file
            recording_type: Type of recording (event_triggered, continuous, manual)
            recorded_at: When video was recorded

        Returns:
            Video ID if successful
        """
        if not self.device_id:
            logger.error("Device not registered")
            return None

        headers = self._get_device_headers()

        # Prepare form data
        files = {
            'video': (filename, video_file, 'video/mp4')
        }

        data = {
            'device_id': self.device_id,
            'recording_type': recording_type,
            'recorded_at': (recorded_at or datetime.utcnow()).isoformat()
        }

        logger.info(f"Uploading video: {filename}")

        try:
            url = f"{self.base_url}/api/videos/upload"
            response = self.session.post(
                url,
                files=files,
                data=data,
                headers=headers,
                timeout=300  # 5 minutes for video upload
            )
            response.raise_for_status()
            result = response.json()

            video_id = result.get('id')
            logger.info(f"Video uploaded successfully: {video_id}")
            return video_id

        except Exception as e:
            logger.error(f"Error uploading video: {e}")
            return None

    def submit_sensor_reading(self, sensor_type: str, value: float, unit: Optional[str] = None) -> bool:
        """
        Submit sensor reading to backend

        Args:
            sensor_type: Type of sensor (temperature, humidity, etc.)
            value: Sensor value
            unit: Unit of measurement

        Returns:
            True if successful
        """
        if not self.device_id:
            logger.error("Device not registered")
            return False

        data = {
            'device_id': self.device_id,
            'sensor_type': sensor_type,
            'value': value,
            'unit': unit
        }

        headers = self._get_device_headers()
        response = self._request('POST', '/api/sensors/readings', json=data, headers=headers)

        return response is not None

    def health_check(self) -> bool:
        """Check if backend is reachable"""
        response = self._request('GET', '/health')
        return response is not None and response.get('status') == 'healthy'

    def retry_request(self, func, max_retries: int = 3, backoff: float = 2.0):
        """
        Retry a request with exponential backoff

        Args:
            func: Function to retry
            max_retries: Maximum number of retries
            backoff: Backoff multiplier

        Returns:
            Function result or None if all retries fail
        """
        for attempt in range(max_retries):
            result = func()
            if result is not None:
                return result

            if attempt < max_retries - 1:
                wait_time = backoff ** attempt
                logger.warning(f"Retry {attempt + 1}/{max_retries} in {wait_time}s...")
                time.sleep(wait_time)

        logger.error(f"All {max_retries} retries failed")
        return None
