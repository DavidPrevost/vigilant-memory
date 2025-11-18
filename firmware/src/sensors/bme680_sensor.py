"""
BME680 Sensor Driver
Temperature, Humidity, Pressure, Air Quality
"""
import logging
from typing import Optional, Dict, Any

logger = logging.getLogger(__name__)


class BME680Sensor:
    """BME680 environmental sensor (Temp, Humidity, Pressure, Air Quality)"""

    def __init__(self, i2c_address: int = 0x77):
        self.i2c_address = i2c_address
        self.sensor = None
        self._initialized = False

    def initialize(self) -> bool:
        """Initialize sensor"""
        try:
            # Import sensor library
            try:
                import bme680
            except ImportError:
                logger.error("bme680 library not installed. Run: pip install bme680")
                return False

            # Initialize sensor
            self.sensor = bme680.BME680(self.i2c_address)

            # Configure oversampling
            self.sensor.set_humidity_oversample(bme680.OS_2X)
            self.sensor.set_pressure_oversample(bme680.OS_4X)
            self.sensor.set_temperature_oversample(bme680.OS_8X)
            self.sensor.set_filter(bme680.FILTER_SIZE_3)

            # Configure gas sensor (for air quality)
            self.sensor.set_gas_status(bme680.ENABLE_GAS_MEAS)
            self.sensor.set_gas_heater_temperature(320)
            self.sensor.set_gas_heater_duration(150)
            self.sensor.select_gas_heater_profile(0)

            self._initialized = True
            logger.info(f"BME680 sensor initialized at 0x{self.i2c_address:02x}")
            return True

        except Exception as e:
            logger.error(f"Error initializing BME680: {e}")
            return False

    def read(self) -> Optional[Dict[str, Any]]:
        """
        Read all sensor values

        Returns:
            Dict with temperature, humidity, pressure, gas_resistance
        """
        if not self._initialized:
            logger.warning("BME680 not initialized")
            return None

        try:
            # Get sensor data
            if not self.sensor.get_sensor_data():
                logger.warning("BME680: Failed to get sensor data")
                return None

            data = {
                'temperature': {
                    'value': round(self.sensor.data.temperature, 2),
                    'unit': 'celsius'
                },
                'humidity': {
                    'value': round(self.sensor.data.humidity, 2),
                    'unit': 'percent'
                },
                'pressure': {
                    'value': round(self.sensor.data.pressure, 2),
                    'unit': 'hPa'
                },
                'gas_resistance': {
                    'value': self.sensor.data.gas_resistance,
                    'unit': 'ohms'
                }
            }

            # Calculate air quality index (simple method)
            # Higher gas resistance = better air quality
            if self.sensor.data.heat_stable:
                gas = self.sensor.data.gas_resistance
                if gas > 50000:
                    air_quality = 'excellent'
                elif gas > 20000:
                    air_quality = 'good'
                elif gas > 10000:
                    air_quality = 'fair'
                else:
                    air_quality = 'poor'

                data['air_quality'] = {
                    'value': air_quality,
                    'unit': 'category'
                }

            return data

        except Exception as e:
            logger.error(f"Error reading BME680: {e}")
            return None

    def get_temperature(self) -> Optional[float]:
        """Get temperature in Celsius"""
        data = self.read()
        return data['temperature']['value'] if data else None

    def get_humidity(self) -> Optional[float]:
        """Get humidity in percent"""
        data = self.read()
        return data['humidity']['value'] if data else None

    def get_pressure(self) -> Optional[float]:
        """Get pressure in hPa"""
        data = self.read()
        return data['pressure']['value'] if data else None

    def close(self):
        """Close sensor"""
        self._initialized = False
        logger.info("BME680 sensor closed")
