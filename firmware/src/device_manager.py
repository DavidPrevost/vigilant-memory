"""
Device Manager
Handles device registration, initialization, and lifecycle
"""
import logging
import argparse
import sys
from pathlib import Path
from typing import Optional

from config import config
from backend_client import BackendClient

logger = logging.getLogger(__name__)


class DeviceManager:
    """Manages device registration and configuration"""

    def __init__(self):
        self.backend_client: Optional[BackendClient] = None

    def is_registered(self) -> bool:
        """Check if device is registered"""
        return config.is_registered()

    def register(self, device_name: str, backend_url: str, user_email: Optional[str] = None) -> bool:
        """
        Register device with backend

        Args:
            device_name: Name for this device
            backend_url: Backend API URL
            user_email: User email (for production registration)

        Returns:
            True if registration successful
        """
        if self.is_registered():
            logger.warning("Device already registered")
            print(f"Device already registered: {config.device_id}")
            print("Use --force to re-register")
            return False

        logger.info(f"Registering device: {device_name}")
        print(f"\n🔄 Registering device '{device_name}'...")
        print(f"Backend URL: {backend_url}")

        # Create backend client
        client = BackendClient(backend_url)

        # Attempt registration
        # Note: In production, this requires user authentication via mobile app
        # For development, we'd use a dev user or registration token
        try:
            response = client.register_device(device_name, model="prototype")

            if not response:
                logger.error("Registration failed - no response from backend")
                print("\n❌ Registration failed!")
                print("Make sure:")
                print("  1. Backend is running")
                print("  2. You have internet/network connectivity")
                print("  3. Backend URL is correct")
                return False

            # Save device credentials
            config.device_id = response['id']
            config.device_secret = response['device_secret']
            config.mqtt_client_id = response['mqtt_client_id']
            config.device_name = device_name
            config.backend_url = backend_url

            # Save configuration
            config.save()

            logger.info("Device registered successfully")
            print("\n✅ Device registered successfully!")
            print(f"Device ID: {config.device_id}")
            print(f"MQTT Client ID: {config.mqtt_client_id}")
            print("\n⚠️  IMPORTANT: Device secret has been saved securely.")
            print("Configuration saved to:", config.config_file)

            return True

        except Exception as e:
            logger.error(f"Registration error: {e}")
            print(f"\n❌ Registration failed: {e}")
            return False

    def unregister(self) -> bool:
        """Unregister device and clear configuration"""
        if not self.is_registered():
            print("Device is not registered")
            return False

        print(f"\n⚠️  Unregistering device: {config.device_id}")
        print("This will delete all local configuration.")

        # Clear configuration
        config._config = {}
        config.save()

        print("✅ Device unregistered")
        return True

    def get_status(self):
        """Get device registration status"""
        print("\n" + "=" * 50)
        print("DEVICE STATUS")
        print("=" * 50)

        if self.is_registered():
            print(f"✅ Registered")
            print(f"\nDevice Information:")
            print(f"  Device ID:       {config.device_id}")
            print(f"  Device Name:     {config.device_name}")
            print(f"  MQTT Client ID:  {config.mqtt_client_id}")
            print(f"\nBackend Configuration:")
            print(f"  Backend URL:     {config.backend_url}")
            print(f"  MQTT Broker:     {config.mqtt_broker_host}:{config.mqtt_broker_port}")
            print(f"\nCamera Configuration:")
            print(f"  Resolution:      {config.camera_resolution[0]}x{config.camera_resolution[1]}")
            print(f"  Frame Rate:      {config.camera_framerate} fps")
            print(f"  Bitrate:         {config.camera_bitrate / 1000000:.1f} Mbps")
            print(f"\nFeatures:")
            print(f"  Recording:       {'Enabled' if config.recording_enabled else 'Disabled'}")
            print(f"  Video Upload:    {'Enabled' if config.upload_videos else 'Disabled'}")
            print(f"  Sensors:         {'Enabled' if config.sensors_enabled else 'Disabled'}")
            print(f"  Motion Detection:{'Enabled' if config.motion_detection_enabled else 'Disabled'}")

        else:
            print("❌ Not Registered")
            print("\nTo register this device:")
            print("  python device_manager.py --register --name 'My Baby Monitor' --backend http://your-server:5000")

        print("=" * 50)

    def configure(self, **kwargs):
        """Update device configuration"""
        if not self.is_registered():
            print("❌ Device must be registered first")
            return False

        print("\n🔧 Updating configuration...")

        for key, value in kwargs.items():
            if value is not None:
                setattr(config, key, value)
                print(f"  {key}: {value}")

        config.save()
        print("✅ Configuration updated")
        return True


def main():
    """CLI for device management"""
    parser = argparse.ArgumentParser(description='Baby Monitor Device Manager')

    parser.add_argument('--register', action='store_true',
                        help='Register device with backend')
    parser.add_argument('--unregister', action='store_true',
                        help='Unregister device')
    parser.add_argument('--status', action='store_true',
                        help='Show device status')
    parser.add_argument('--name', type=str,
                        help='Device name')
    parser.add_argument('--backend', type=str,
                        help='Backend URL (e.g., http://server:5000)')
    parser.add_argument('--mqtt-host', type=str,
                        help='MQTT broker host')
    parser.add_argument('--mqtt-port', type=int,
                        help='MQTT broker port')
    parser.add_argument('--force', action='store_true',
                        help='Force operation (e.g., re-register)')

    args = parser.parse_args()

    # Setup logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    manager = DeviceManager()

    # Handle commands
    if args.register:
        if not args.name or not args.backend:
            print("❌ Error: --name and --backend are required for registration")
            sys.exit(1)

        if args.force and manager.is_registered():
            manager.unregister()

        success = manager.register(args.name, args.backend)
        sys.exit(0 if success else 1)

    elif args.unregister:
        success = manager.unregister()
        sys.exit(0 if success else 1)

    elif args.status:
        manager.get_status()
        sys.exit(0)

    elif args.mqtt_host or args.mqtt_port:
        # Update MQTT configuration
        kwargs = {}
        if args.mqtt_host:
            kwargs['mqtt_broker_host'] = args.mqtt_host
        if args.mqtt_port:
            kwargs['mqtt_broker_port'] = args.mqtt_port

        success = manager.configure(**kwargs)
        sys.exit(0 if success else 1)

    else:
        # Default: show status
        manager.get_status()


if __name__ == '__main__':
    main()
