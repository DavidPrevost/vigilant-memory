"""
Sensor Manager
Coordinates all sensors and provides unified interface
"""
import logging
import threading
import time
from typing import Dict, Any, Optional, List

from .bme680_sensor import BME680Sensor
from .bh1750_sensor import BH1750Sensor
from .adxl345_sensor import ADXL345Sensor

logger = logging.getLogger(__name__)


class SensorManager:
    """Manages all sensors and periodic readings"""

    def __init__(self):
        self.sensors: Dict[str, Any] = {}
        self.is_running = False
        self.read_thread: Optional[threading.Thread] = None
        self.read_interval = 60  # seconds
        self.last_readings: Dict[str, Any] = {}
        self.callbacks: List = []

    def initialize(self, enable_bme680: bool = True, enable_bh1750: bool = True,
                   enable_adxl345: bool = True) -> bool:
        """
        Initialize all enabled sensors

        Args:
            enable_bme680: Enable temperature/humidity/pressure/air quality sensor
            enable_bh1750: Enable light sensor
            enable_adxl345: Enable accelerometer/motion sensor

        Returns:
            True if at least one sensor initialized successfully
        """
        logger.info("Initializing sensors...")
        success_count = 0

        # Initialize BME680 (temp, humidity, pressure, air quality)
        if enable_bme680:
            try:
                bme = BME680Sensor()
                if bme.initialize():
                    self.sensors['bme680'] = bme
                    logger.info("✓ BME680 initialized")
                    success_count += 1
                else:
                    logger.warning("✗ BME680 initialization failed")
            except Exception as e:
                logger.error(f"✗ BME680 error: {e}")

        # Initialize BH1750 (light)
        if enable_bh1750:
            try:
                bh = BH1750Sensor()
                if bh.initialize():
                    self.sensors['bh1750'] = bh
                    logger.info("✓ BH1750 initialized")
                    success_count += 1
                else:
                    logger.warning("✗ BH1750 initialization failed")
            except Exception as e:
                logger.error(f"✗ BH1750 error: {e}")

        # Initialize ADXL345 (accelerometer)
        if enable_adxl345:
            try:
                adxl = ADXL345Sensor()
                if adxl.initialize():
                    self.sensors['adxl345'] = adxl
                    logger.info("✓ ADXL345 initialized")
                    success_count += 1
                else:
                    logger.warning("✗ ADXL345 initialization failed")
            except Exception as e:
                logger.error(f"✗ ADXL345 error: {e}")

        logger.info(f"Sensors initialized: {success_count}/{3}")
        return success_count > 0

    def read_all(self) -> Dict[str, Any]:
        """
        Read all sensors

        Returns:
            Dict with all sensor readings
        """
        readings = {}

        # BME680
        if 'bme680' in self.sensors:
            data = self.sensors['bme680'].read()
            if data:
                readings.update(data)

        # BH1750
        if 'bh1750' in self.sensors:
            data = self.sensors['bh1750'].read()
            if data:
                readings.update(data)

        # ADXL345
        if 'adxl345' in self.sensors:
            data = self.sensors['adxl345'].read()
            if data:
                readings.update(data)

        # Cache readings
        self.last_readings = readings

        return readings

    def get_latest_readings(self) -> Dict[str, Any]:
        """Get latest cached readings"""
        return self.last_readings

    def start_periodic_reading(self, interval: int = 60):
        """
        Start periodic sensor reading

        Args:
            interval: Reading interval in seconds
        """
        if self.is_running:
            logger.warning("Periodic reading already running")
            return

        self.read_interval = interval
        self.is_running = True
        self.read_thread = threading.Thread(target=self._read_loop, daemon=True)
        self.read_thread.start()
        logger.info(f"Started periodic sensor reading (interval={interval}s)")

    def stop_periodic_reading(self):
        """Stop periodic sensor reading"""
        self.is_running = False
        if self.read_thread:
            self.read_thread.join(timeout=10)
        logger.info("Stopped periodic sensor reading")

    def _read_loop(self):
        """Background thread for periodic reading"""
        while self.is_running:
            try:
                # Read all sensors
                readings = self.read_all()

                # Call callbacks
                for callback in self.callbacks:
                    try:
                        callback(readings)
                    except Exception as e:
                        logger.error(f"Error in sensor callback: {e}")

                # Sleep until next reading
                time.sleep(self.read_interval)

            except Exception as e:
                logger.error(f"Error in sensor read loop: {e}")
                time.sleep(5)  # Wait before retrying

    def add_callback(self, callback):
        """
        Add callback for sensor readings

        Args:
            callback: Function that takes readings dict as parameter
        """
        self.callbacks.append(callback)

    def detect_motion(self) -> bool:
        """Check if motion is detected"""
        if 'adxl345' in self.sensors:
            return self.sensors['adxl345'].detect_motion()
        return False

    def get_temperature(self) -> Optional[float]:
        """Get temperature in Celsius"""
        readings = self.get_latest_readings()
        temp_data = readings.get('temperature')
        return temp_data['value'] if temp_data else None

    def get_humidity(self) -> Optional[float]:
        """Get humidity in percent"""
        readings = self.get_latest_readings()
        humidity_data = readings.get('humidity')
        return humidity_data['value'] if humidity_data else None

    def get_light_level(self) -> Optional[float]:
        """Get light level in lux"""
        readings = self.get_latest_readings()
        light_data = readings.get('light')
        return light_data['value'] if light_data else None

    def get_air_quality(self) -> Optional[str]:
        """Get air quality category"""
        readings = self.get_latest_readings()
        aq_data = readings.get('air_quality')
        return aq_data['value'] if aq_data else None

    def is_healthy(self) -> bool:
        """Check if sensor readings indicate healthy environment"""
        try:
            temp = self.get_temperature()
            humidity = self.get_humidity()

            # Check temperature range (18-24°C is ideal for babies)
            if temp and (temp < 16 or temp > 26):
                return False

            # Check humidity range (40-60% is ideal)
            if humidity and (humidity < 30 or humidity > 70):
                return False

            return True

        except Exception as e:
            logger.error(f"Error checking sensor health: {e}")
            return True  # Assume healthy if can't determine

    def close(self):
        """Close all sensors"""
        # Stop periodic reading
        self.stop_periodic_reading()

        # Close each sensor
        for sensor_name, sensor in self.sensors.items():
            try:
                sensor.close()
                logger.info(f"Closed {sensor_name}")
            except Exception as e:
                logger.error(f"Error closing {sensor_name}: {e}")

        self.sensors.clear()
        logger.info("All sensors closed")
