"""
BH1750 Light Sensor Driver
Ambient Light Measurement
"""
import logging
from typing import Optional, Dict, Any
import time

logger = logging.getLogger(__name__)


class BH1750Sensor:
    """BH1750 ambient light sensor"""

    # I2C addresses
    ADDR_LOW = 0x23
    ADDR_HIGH = 0x5C

    # Measurement modes
    CONTINUOUS_HIGH_RES_MODE = 0x10
    CONTINUOUS_HIGH_RES_MODE_2 = 0x11
    CONTINUOUS_LOW_RES_MODE = 0x13
    ONE_TIME_HIGH_RES_MODE = 0x20
    ONE_TIME_HIGH_RES_MODE_2 = 0x21
    ONE_TIME_LOW_RES_MODE = 0x23

    def __init__(self, i2c_address: int = ADDR_LOW, mode: int = CONTINUOUS_HIGH_RES_MODE):
        self.i2c_address = i2c_address
        self.mode = mode
        self.bus = None
        self._initialized = False

    def initialize(self) -> bool:
        """Initialize sensor"""
        try:
            # Import I2C library
            try:
                import smbus2
            except ImportError:
                logger.error("smbus2 library not installed. Run: pip install smbus2")
                return False

            # Initialize I2C bus
            self.bus = smbus2.SMBus(1)  # Use I2C bus 1

            # Power on and set mode
            self.bus.write_byte(self.i2c_address, 0x01)  # Power on
            time.sleep(0.01)
            self.bus.write_byte(self.i2c_address, self.mode)
            time.sleep(0.18)  # Wait for measurement

            self._initialized = True
            logger.info(f"BH1750 sensor initialized at 0x{self.i2c_address:02x}")
            return True

        except Exception as e:
            logger.error(f"Error initializing BH1750: {e}")
            return False

    def read(self) -> Optional[Dict[str, Any]]:
        """
        Read light level

        Returns:
            Dict with light level in lux
        """
        if not self._initialized:
            logger.warning("BH1750 not initialized")
            return None

        try:
            # Read 2 bytes of data
            data = self.bus.read_i2c_block_data(self.i2c_address, self.mode, 2)

            # Convert to lux
            lux = (data[0] << 8 | data[1]) / 1.2

            return {
                'light': {
                    'value': round(lux, 2),
                    'unit': 'lux'
                }
            }

        except Exception as e:
            logger.error(f"Error reading BH1750: {e}")
            return None

    def get_light_level(self) -> Optional[float]:
        """Get light level in lux"""
        data = self.read()
        return data['light']['value'] if data else None

    def get_light_condition(self) -> Optional[str]:
        """
        Get human-readable light condition

        Returns:
            String describing light level (dark, dim, bright, very_bright)
        """
        lux = self.get_light_level()
        if lux is None:
            return None

        if lux < 10:
            return 'dark'
        elif lux < 100:
            return 'dim'
        elif lux < 1000:
            return 'bright'
        else:
            return 'very_bright'

    def close(self):
        """Close sensor"""
        if self.bus:
            # Power down sensor
            try:
                self.bus.write_byte(self.i2c_address, 0x00)
            except:
                pass
            self.bus.close()

        self._initialized = False
        logger.info("BH1750 sensor closed")
