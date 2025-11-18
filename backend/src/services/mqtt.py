"""
MQTT Service for Device Communication
"""
import paho.mqtt.client as mqtt
import json
import threading
from datetime import datetime


class MQTTService:
    """MQTT broker communication service"""

    def __init__(self):
        self.client = None
        self.app = None
        self.is_connected = False

    def init_app(self, app):
        """Initialize with Flask app"""
        self.app = app

        try:
            # Create MQTT client
            self.client = mqtt.Client(client_id="babymonitor_server")

            # Set callbacks
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            self.client.on_message = self._on_message

            # Set credentials if configured
            if app.config.get('MQTT_USERNAME'):
                self.client.username_pw_set(
                    app.config['MQTT_USERNAME'],
                    app.config.get('MQTT_PASSWORD')
                )

            # Connect to broker
            self.client.connect_async(
                app.config['MQTT_BROKER_HOST'],
                app.config['MQTT_BROKER_PORT'],
                keepalive=60
            )

            # Start network loop in separate thread
            self.client.loop_start()

            app.logger.info('MQTT service initialized')

        except Exception as e:
            app.logger.error(f'Error initializing MQTT service: {str(e)}')

    def _on_connect(self, client, userdata, flags, rc):
        """Callback when connected to MQTT broker"""
        if rc == 0:
            self.is_connected = True
            self.app.logger.info('Connected to MQTT broker')

            # Subscribe to device topics
            self.client.subscribe('devices/+/status')
            self.client.subscribe('devices/+/telemetry')
            self.client.subscribe('devices/+/events')

        else:
            self.app.logger.error(f'Failed to connect to MQTT broker: {rc}')

    def _on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from MQTT broker"""
        self.is_connected = False
        self.app.logger.warning(f'Disconnected from MQTT broker: {rc}')

    def _on_message(self, client, userdata, msg):
        """Callback when message received"""
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode())

            self.app.logger.debug(f'MQTT message received: {topic}')

            # Handle different message types
            if '/status' in topic:
                self._handle_device_status(topic, payload)
            elif '/telemetry' in topic:
                self._handle_telemetry(topic, payload)
            elif '/events' in topic:
                self._handle_event(topic, payload)

        except Exception as e:
            self.app.logger.error(f'Error processing MQTT message: {str(e)}')

    def _handle_device_status(self, topic, payload):
        """Handle device status updates"""
        # Extract device ID from topic: devices/{device_id}/status
        device_id = topic.split('/')[1]

        # Update device status in database (would need app context)
        with self.app.app_context():
            from ..models import db, Device
            device = Device.query.get(device_id)
            if device:
                device.online_status = payload.get('online', False)
                device.last_seen_at = payload.get('timestamp')
                device.battery_level = payload.get('battery_level')
                db.session.commit()

    def _handle_telemetry(self, topic, payload):
        """Handle telemetry data (sensors)"""
        device_id = topic.split('/')[1]

        # Store in TimescaleDB
        with self.app.app_context():
            from ..models import timescale_db
            for sensor_type, value in payload.get('sensors', {}).items():
                query = """
                    INSERT INTO sensor_readings (time, device_id, sensor_type, value, unit)
                    VALUES (NOW(), %s, %s, %s, %s)
                """
                timescale_db.execute(query, (device_id, sensor_type, value, payload.get('unit')))

    def _handle_event(self, topic, payload):
        """Handle device events"""
        device_id = topic.split('/')[1]

        # Create event in database
        with self.app.app_context():
            from ..models import db, Event
            event = Event(
                device_id=device_id,
                event_type=payload.get('event_type'),
                severity=payload.get('severity', 'info'),
                confidence_score=payload.get('confidence'),
                metadata=payload.get('metadata', {})
            )
            db.session.add(event)
            db.session.commit()

    def publish(self, topic, payload, qos=1):
        """Publish message to MQTT topic"""
        if not self.is_connected:
            self.app.logger.warning('MQTT not connected, cannot publish')
            return False

        try:
            message = json.dumps(payload)
            result = self.client.publish(topic, message, qos=qos)
            return result.rc == mqtt.MQTT_ERR_SUCCESS

        except Exception as e:
            self.app.logger.error(f'Error publishing MQTT message: {str(e)}')
            return False

    def send_command_to_device(self, device_id, command, params=None):
        """Send command to specific device"""
        topic = f"devices/{device_id}/commands"
        payload = {
            'command': command,
            'params': params or {},
            'timestamp': str(datetime.utcnow())
        }
        return self.publish(topic, payload)


# Global MQTT service instance
mqtt_service = MQTTService()
