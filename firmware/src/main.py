"""
Baby Monitor - Main Application
Orchestrates camera, sensors, backend communication, and monitoring
"""
import logging
import time
import signal
import sys
import threading
from pathlib import Path
from datetime import datetime

# Import configuration
from config import config

# Import components
from camera import CameraManager
from backend_client import BackendClient
from mqtt_client import MQTTClient
from video_uploader import VideoUploader
from system_monitor import SystemMonitor
from sensors.sensor_manager import SensorManager

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/babymonitor.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class BabyMonitorApp:
    """Main application orchestrator"""

    def __init__(self):
        self.running = False

        # Components
        self.camera: CameraManager = None
        self.backend_client: BackendClient = None
        self.mqtt_client: MQTTClient = None
        self.video_uploader: VideoUploader = None
        self.system_monitor: SystemMonitor = None
        self.sensor_manager: SensorManager = None

        # Threads
        self.status_thread: threading.Thread = None
        self.recording_dir = Path('/var/babymonitor/recordings')
        self.recording_dir.mkdir(parents=True, exist_ok=True)

    def initialize(self):
        """Initialize all components"""
        logger.info("=" * 60)
        logger.info("BABY MONITOR STARTING")
        logger.info("=" * 60)

        # Check if device is registered
        if not config.is_registered():
            logger.error("Device not registered! Run: python device_manager.py --register")
            print("\n❌ Device not registered!")
            print("Please register the device first:")
            print("  python device_manager.py --register --name 'My Baby Monitor' --backend http://server:5000")
            return False

        logger.info(f"Device ID: {config.device_id}")
        logger.info(f"Device Name: {config.device_name}")
        logger.info(f"Backend URL: {config.backend_url}")

        # Initialize backend client
        logger.info("Initializing backend client...")
        self.backend_client = BackendClient(
            config.backend_url,
            config.device_id,
            config.device_secret
        )

        # Health check
        if not self.backend_client.health_check():
            logger.warning("⚠️  Backend health check failed - will retry")
        else:
            logger.info("✓ Backend connection OK")

        # Initialize MQTT client
        logger.info("Initializing MQTT client...")
        self.mqtt_client = MQTTClient(
            config.mqtt_broker_host,
            config.mqtt_broker_port,
            config.device_id,
            config.mqtt_client_id
        )

        try:
            self.mqtt_client.connect()
            self.mqtt_client.set_command_callback(self._handle_command)

            if self.mqtt_client.wait_for_connection(timeout=10):
                logger.info("✓ MQTT connected")
            else:
                logger.warning("⚠️  MQTT connection timeout - will retry")

        except Exception as e:
            logger.error(f"✗ MQTT connection failed: {e}")

        # Initialize system monitor
        logger.info("Initializing system monitor...")
        self.system_monitor = SystemMonitor()
        logger.info("✓ System monitor ready")

        # Initialize camera
        logger.info("Initializing camera...")
        self.camera = CameraManager(
            resolution=config.camera_resolution,
            framerate=config.camera_framerate
        )

        try:
            self.camera.start()
            logger.info("✓ Camera started")
        except Exception as e:
            logger.error(f"✗ Camera initialization failed: {e}")
            return False

        # Initialize video uploader
        logger.info("Initializing video uploader...")
        self.video_uploader = VideoUploader(self.backend_client)
        self.video_uploader.start()
        logger.info("✓ Video uploader started")

        # Initialize sensors (if enabled)
        if config.sensors_enabled:
            logger.info("Initializing sensors...")
            self.sensor_manager = SensorManager()
            if self.sensor_manager.initialize():
                # Start periodic sensor reading
                self.sensor_manager.start_periodic_reading(config.sensor_read_interval)
                # Add callback to send readings to backend
                self.sensor_manager.add_callback(self._on_sensor_reading)
                logger.info("✓ Sensors initialized")
            else:
                logger.warning("⚠️  Sensor initialization failed")
        else:
            logger.info("Sensors disabled in configuration")

        logger.info("=" * 60)
        logger.info("BABY MONITOR READY")
        logger.info("=" * 60)

        return True

    def start(self):
        """Start the application"""
        if not self.initialize():
            logger.error("Initialization failed")
            return False

        self.running = True

        # Start status update thread
        self.status_thread = threading.Thread(target=self._status_update_loop, daemon=True)
        self.status_thread.start()

        logger.info("Baby monitor is running")
        logger.info("Press Ctrl+C to stop")

        return True

    def stop(self):
        """Stop the application"""
        logger.info("Shutting down baby monitor...")

        self.running = False

        # Stop components
        if self.video_uploader:
            self.video_uploader.stop()

        if self.sensor_manager:
            self.sensor_manager.close()

        if self.camera:
            self.camera.stop()

        if self.mqtt_client:
            self.mqtt_client.disconnect()

        logger.info("Baby monitor stopped")

    def _status_update_loop(self):
        """Background thread for periodic status updates"""
        while self.running:
            try:
                # Collect status data
                status = self._collect_status()

                # Send to backend via API
                if self.backend_client:
                    self.backend_client.update_status(status)

                # Publish to MQTT
                if self.mqtt_client and self.mqtt_client.is_connected:
                    self.mqtt_client.publish_status(status)

                # Wait for next interval
                time.sleep(config.status_update_interval)

            except Exception as e:
                logger.error(f"Error in status update loop: {e}")
                time.sleep(5)

    def _collect_status(self) -> dict:
        """Collect current device status"""
        status = {
            'online': True,
            'timestamp': datetime.utcnow().isoformat()
        }

        # System metrics
        if self.system_monitor:
            sys_status = self.system_monitor.get_full_status()
            status.update({
                'cpu_usage_percent': sys_status.get('cpu_usage_percent'),
                'cpu_temperature_celsius': sys_status.get('cpu_temperature_celsius'),
                'memory_usage_percent': sys_status['memory'].get('percent') if sys_status.get('memory') else None,
                'disk_usage_percent': sys_status['disk'].get('percent') if sys_status.get('disk') else None,
                'uptime_seconds': sys_status.get('uptime_seconds')
            })

            # Network info
            network = sys_status.get('network', {})
            status['ip_address'] = network.get('ip_address')

            wifi = network.get('wifi', {})
            status['wifi_ssid'] = wifi.get('ssid')
            status['signal_strength'] = wifi.get('signal_strength')

            # Battery info
            battery = sys_status.get('battery')
            if battery:
                status['battery_level'] = battery.get('percent')
                status['power_source'] = 'battery' if not battery.get('is_plugged') else 'ac_power'

        # Camera status
        if self.camera:
            status['camera'] = {
                'active': True,
                'recording': self.camera.is_recording,
                'resolution': f"{self.camera.resolution[0]}x{self.camera.resolution[1]}",
                'framerate': self.camera.framerate
            }

        # Sensor status
        if self.sensor_manager:
            latest = self.sensor_manager.get_latest_readings()
            status['sensors'] = latest

        # Upload queue status
        if self.video_uploader:
            upload_stats = self.video_uploader.get_stats()
            status['upload_queue'] = upload_stats.get('queued')

        return status

    def _on_sensor_reading(self, readings: dict):
        """Callback for sensor readings"""
        try:
            # Send each reading to backend
            for sensor_type, data in readings.items():
                if isinstance(data, dict) and 'value' in data:
                    self.backend_client.submit_sensor_reading(
                        sensor_type,
                        float(data['value']),
                        data.get('unit')
                    )

            logger.debug(f"Sent {len(readings)} sensor readings to backend")

        except Exception as e:
            logger.error(f"Error sending sensor readings: {e}")

    def _handle_command(self, command: str, params: dict):
        """Handle command from backend"""
        logger.info(f"Received command: {command}")

        try:
            if command == 'start_recording':
                self._start_recording(params)
            elif command == 'stop_recording':
                self._stop_recording()
            elif command == 'capture_snapshot':
                self._capture_snapshot()
            elif command == 'update_settings':
                self._update_settings(params)
            elif command == 'reboot':
                self._reboot()
            else:
                logger.warning(f"Unknown command: {command}")

        except Exception as e:
            logger.error(f"Error handling command: {e}")

    def _start_recording(self, params: dict):
        """Start video recording"""
        duration = params.get('duration', 30)
        filename = f"recording_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.h264"
        filepath = self.recording_dir / filename

        logger.info(f"Starting recording: {filename}")
        self.camera.start_recording(str(filepath))

        # Schedule stop recording
        def stop_after_duration():
            time.sleep(duration)
            if self.camera.is_recording:
                self.camera.stop_recording()
                logger.info(f"Recording completed: {filename}")

                # Queue for upload
                if config.upload_videos:
                    self.video_uploader.queue_upload(str(filepath))

        threading.Thread(target=stop_after_duration, daemon=True).start()

    def _stop_recording(self):
        """Stop video recording"""
        if self.camera.is_recording:
            self.camera.stop_recording()
            logger.info("Recording stopped")

    def _capture_snapshot(self):
        """Capture and upload snapshot"""
        filename = f"snapshot_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.jpg"
        filepath = self.recording_dir / filename

        frame = self.camera.capture_frame()
        if frame:
            with open(filepath, 'wb') as f:
                f.write(frame)
            logger.info(f"Snapshot captured: {filename}")

    def _update_settings(self, params: dict):
        """Update device settings"""
        logger.info(f"Updating settings: {params}")
        for key, value in params.items():
            if hasattr(config, key):
                setattr(config, key, value)
        config.save()

    def _reboot(self):
        """Reboot device"""
        logger.warning("Reboot command received")
        self.stop()
        import subprocess
        subprocess.run(['sudo', 'reboot'])

    def run(self):
        """Main run loop"""
        if not self.start():
            return 1

        # Setup signal handlers
        signal.signal(signal.SIGINT, lambda s, f: self.stop())
        signal.signal(signal.SIGTERM, lambda s, f: self.stop())

        # Keep running
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            pass

        self.stop()
        return 0


def main():
    """Main entry point"""
    app = BabyMonitorApp()
    sys.exit(app.run())


if __name__ == '__main__':
    main()
