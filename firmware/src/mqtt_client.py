"""
MQTT Client for Device Communication
Handles real-time messaging with backend via MQTT
"""
import paho.mqtt.client as mqtt
import json
import logging
import time
from typing import Optional, Callable, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)


class MQTTClient:
    """MQTT client for device communication"""

    def __init__(self, broker_host: str, broker_port: int = 1883,
                 device_id: Optional[str] = None,
                 mqtt_client_id: Optional[str] = None):
        self.broker_host = broker_host
        self.broker_port = broker_port
        self.device_id = device_id
        self.mqtt_client_id = mqtt_client_id or f"device_{device_id}"

        self.client: Optional[mqtt.Client] = None
        self.is_connected = False
        self.command_callback: Optional[Callable] = None

    def connect(self, username: Optional[str] = None, password: Optional[str] = None):
        """Connect to MQTT broker"""
        if not self.device_id:
            raise ValueError("Device ID not set")

        logger.info(f"Connecting to MQTT broker at {self.broker_host}:{self.broker_port}")

        try:
            # Create MQTT client
            self.client = mqtt.Client(client_id=self.mqtt_client_id)

            # Set callbacks
            self.client.on_connect = self._on_connect
            self.client.on_disconnect = self._on_disconnect
            self.client.on_message = self._on_message

            # Set credentials if provided
            if username and password:
                self.client.username_pw_set(username, password)

            # Connect to broker
            self.client.connect(self.broker_host, self.broker_port, keepalive=60)

            # Start network loop in background thread
            self.client.loop_start()

            logger.info("MQTT client started")

        except Exception as e:
            logger.error(f"Error connecting to MQTT broker: {e}")
            raise

    def disconnect(self):
        """Disconnect from MQTT broker"""
        if self.client:
            self.client.loop_stop()
            self.client.disconnect()
            self.is_connected = False
            logger.info("MQTT client disconnected")

    def _on_connect(self, client, userdata, flags, rc):
        """Callback when connected to broker"""
        if rc == 0:
            self.is_connected = True
            logger.info("Connected to MQTT broker")

            # Subscribe to command topic
            command_topic = f"devices/{self.device_id}/commands"
            self.client.subscribe(command_topic)
            logger.info(f"Subscribed to {command_topic}")

        else:
            logger.error(f"Failed to connect to MQTT broker: {rc}")

    def _on_disconnect(self, client, userdata, rc):
        """Callback when disconnected from broker"""
        self.is_connected = False
        if rc != 0:
            logger.warning(f"Unexpected MQTT disconnect: {rc}")
            # Auto-reconnect is handled by paho-mqtt library
        else:
            logger.info("MQTT disconnected")

    def _on_message(self, client, userdata, msg):
        """Callback when message received"""
        try:
            topic = msg.topic
            payload = json.loads(msg.payload.decode())

            logger.info(f"MQTT message received on {topic}")

            # Handle commands
            if '/commands' in topic:
                self._handle_command(payload)

        except Exception as e:
            logger.error(f"Error processing MQTT message: {e}")

    def _handle_command(self, payload: Dict[str, Any]):
        """Handle command from backend"""
        command = payload.get('command')
        params = payload.get('params', {})

        logger.info(f"Received command: {command}")

        if self.command_callback:
            self.command_callback(command, params)
        else:
            logger.warning("No command callback registered")

    def set_command_callback(self, callback: Callable[[str, Dict], None]):
        """
        Set callback for handling commands

        Args:
            callback: Function that takes (command, params)
        """
        self.command_callback = callback

    def publish_status(self, status_data: Dict[str, Any]):
        """
        Publish device status

        Args:
            status_data: Status information
        """
        if not self.is_connected:
            logger.warning("MQTT not connected, cannot publish status")
            return False

        topic = f"devices/{self.device_id}/status"
        payload = {
            **status_data,
            'timestamp': datetime.utcnow().isoformat()
        }

        return self._publish(topic, payload)

    def publish_telemetry(self, sensor_data: Dict[str, Any]):
        """
        Publish sensor telemetry

        Args:
            sensor_data: Sensor readings
        """
        if not self.is_connected:
            logger.warning("MQTT not connected, cannot publish telemetry")
            return False

        topic = f"devices/{self.device_id}/telemetry"
        payload = {
            'sensors': sensor_data,
            'timestamp': datetime.utcnow().isoformat()
        }

        return self._publish(topic, payload)

    def publish_event(self, event_type: str, severity: str = 'info',
                      confidence: Optional[float] = None,
                      metadata: Optional[Dict] = None):
        """
        Publish event

        Args:
            event_type: Type of event
            severity: Event severity
            confidence: AI confidence score
            metadata: Additional event data
        """
        if not self.is_connected:
            logger.warning("MQTT not connected, cannot publish event")
            return False

        topic = f"devices/{self.device_id}/events"
        payload = {
            'event_type': event_type,
            'severity': severity,
            'confidence': confidence,
            'metadata': metadata or {},
            'timestamp': datetime.utcnow().isoformat()
        }

        return self._publish(topic, payload)

    def _publish(self, topic: str, payload: Dict[str, Any], qos: int = 1) -> bool:
        """
        Publish message to MQTT topic

        Args:
            topic: MQTT topic
            payload: Message payload
            qos: Quality of service (0, 1, or 2)

        Returns:
            True if published successfully
        """
        try:
            message = json.dumps(payload)
            result = self.client.publish(topic, message, qos=qos)

            if result.rc == mqtt.MQTT_ERR_SUCCESS:
                logger.debug(f"Published to {topic}")
                return True
            else:
                logger.error(f"Failed to publish to {topic}: {result.rc}")
                return False

        except Exception as e:
            logger.error(f"Error publishing to MQTT: {e}")
            return False

    def wait_for_connection(self, timeout: int = 30) -> bool:
        """
        Wait for MQTT connection to be established

        Args:
            timeout: Maximum time to wait in seconds

        Returns:
            True if connected, False if timeout
        """
        start = time.time()
        while not self.is_connected and (time.time() - start) < timeout:
            time.sleep(0.1)

        return self.is_connected
