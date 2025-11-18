"""
Configuration Management for Baby Monitor Firmware
"""
import os
import json
from pathlib import Path
from typing import Optional, Dict, Any
import logging

logger = logging.getLogger(__name__)


class Config:
    """Configuration manager for firmware"""

    def __init__(self, config_file: str = "/etc/babymonitor/config.json"):
        self.config_file = Path(config_file)
        self.config_dir = self.config_file.parent
        self._config: Dict[str, Any] = {}
        self._load_config()

    def _load_config(self):
        """Load configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    self._config = json.load(f)
                logger.info(f"Configuration loaded from {self.config_file}")
            except Exception as e:
                logger.error(f"Error loading config: {e}")
                self._config = {}
        else:
            logger.warning(f"Config file not found: {self.config_file}")
            self._config = {}

    def save(self):
        """Save configuration to file"""
        try:
            # Create directory if it doesn't exist
            self.config_dir.mkdir(parents=True, exist_ok=True)

            with open(self.config_file, 'w') as f:
                json.dump(self._config, f, indent=2)

            logger.info(f"Configuration saved to {self.config_file}")
        except Exception as e:
            logger.error(f"Error saving config: {e}")
            raise

    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value"""
        return self._config.get(key, default)

    def set(self, key: str, value: Any):
        """Set configuration value"""
        self._config[key] = value

    def update(self, updates: Dict[str, Any]):
        """Update multiple configuration values"""
        self._config.update(updates)

    # Device Configuration
    @property
    def device_id(self) -> Optional[str]:
        return self.get('device_id')

    @device_id.setter
    def device_id(self, value: str):
        self.set('device_id', value)

    @property
    def device_secret(self) -> Optional[str]:
        return self.get('device_secret')

    @device_secret.setter
    def device_secret(self, value: str):
        self.set('device_secret', value)

    @property
    def device_name(self) -> str:
        return self.get('device_name', 'Baby Monitor')

    @device_name.setter
    def device_name(self, value: str):
        self.set('device_name', value)

    @property
    def mqtt_client_id(self) -> Optional[str]:
        return self.get('mqtt_client_id')

    @mqtt_client_id.setter
    def mqtt_client_id(self, value: str):
        self.set('mqtt_client_id', value)

    # Backend Configuration
    @property
    def backend_url(self) -> str:
        return self.get('backend_url', 'http://localhost:5000')

    @backend_url.setter
    def backend_url(self, value: str):
        self.set('backend_url', value)

    @property
    def mqtt_broker_host(self) -> str:
        return self.get('mqtt_broker_host', 'localhost')

    @mqtt_broker_host.setter
    def mqtt_broker_host(self, value: str):
        self.set('mqtt_broker_host', value)

    @property
    def mqtt_broker_port(self) -> int:
        return self.get('mqtt_broker_port', 1883)

    @mqtt_broker_port.setter
    def mqtt_broker_port(self, value: int):
        self.set('mqtt_broker_port', value)

    # Camera Configuration
    @property
    def camera_resolution(self) -> tuple:
        res = self.get('camera_resolution', [1280, 720])
        return tuple(res)

    @camera_resolution.setter
    def camera_resolution(self, value: tuple):
        self.set('camera_resolution', list(value))

    @property
    def camera_framerate(self) -> int:
        return self.get('camera_framerate', 30)

    @camera_framerate.setter
    def camera_framerate(self, value: int):
        self.set('camera_framerate', value)

    @property
    def camera_bitrate(self) -> int:
        return self.get('camera_bitrate', 3000000)  # 3 Mbps

    @camera_bitrate.setter
    def camera_bitrate(self, value: int):
        self.set('camera_bitrate', value)

    # Recording Configuration
    @property
    def recording_enabled(self) -> bool:
        return self.get('recording_enabled', True)

    @property
    def event_recording_duration(self) -> int:
        """Duration in seconds to record after event"""
        return self.get('event_recording_duration', 30)

    @property
    def upload_videos(self) -> bool:
        return self.get('upload_videos', True)

    # Sensor Configuration
    @property
    def sensors_enabled(self) -> bool:
        return self.get('sensors_enabled', False)

    @property
    def sensor_read_interval(self) -> int:
        """Interval in seconds between sensor reads"""
        return self.get('sensor_read_interval', 60)

    # Event Detection Configuration
    @property
    def motion_detection_enabled(self) -> bool:
        return self.get('motion_detection_enabled', False)

    @property
    def motion_threshold(self) -> float:
        return self.get('motion_threshold', 0.05)

    @property
    def sound_detection_enabled(self) -> bool:
        return self.get('sound_detection_enabled', False)

    @property
    def sound_threshold(self) -> int:
        """Sound threshold in dB"""
        return self.get('sound_threshold', 60)

    # System Configuration
    @property
    def log_level(self) -> str:
        return self.get('log_level', 'INFO')

    @property
    def status_update_interval(self) -> int:
        """Interval in seconds to send status updates"""
        return self.get('status_update_interval', 60)

    def is_registered(self) -> bool:
        """Check if device is registered with backend"""
        return bool(self.device_id and self.device_secret and self.mqtt_client_id)

    def __repr__(self):
        safe_config = {k: v for k, v in self._config.items() if 'secret' not in k.lower()}
        return f"<Config {safe_config}>"


# Global config instance
config = Config()
