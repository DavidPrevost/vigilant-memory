"""
ADXL345 Accelerometer Sensor Driver
Motion and Vibration Detection
"""
import logging
from typing import Optional, Dict, Any, Tuple
import time
import math

logger = logging.getLogger(__name__)


class ADXL345Sensor:
    """ADXL345 3-axis accelerometer for motion/vibration detection"""

    # I2C address
    ADDRESS = 0x53

    # Registers
    REG_POWER_CTL = 0x2D
    REG_DATA_FORMAT = 0x31
    REG_DATAX0 = 0x32

    # Scale factor for +/- 2g range
    SCALE_MULTIPLIER = 0.004

    def __init__(self, i2c_address: int = ADDRESS):
        self.i2c_address = i2c_address
        self.bus = None
        self._initialized = False
        self._baseline = None  # Baseline acceleration for motion detection

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

            # Enable measurements
            self.bus.write_byte_data(self.i2c_address, self.REG_POWER_CTL, 0x08)

            # Set data format (+/- 2g range, full resolution)
            self.bus.write_byte_data(self.i2c_address, self.REG_DATA_FORMAT, 0x08)

            time.sleep(0.1)

            # Set baseline
            self._calibrate()

            self._initialized = True
            logger.info(f"ADXL345 sensor initialized at 0x{self.i2c_address:02x}")
            return True

        except Exception as e:
            logger.error(f"Error initializing ADXL345: {e}")
            return False

    def _calibrate(self):
        """Calibrate sensor by measuring baseline acceleration"""
        try:
            # Take average of several readings
            x_sum = y_sum = z_sum = 0
            samples = 10

            for _ in range(samples):
                x, y, z = self._read_raw()
                x_sum += x
                y_sum += y
                z_sum += z
                time.sleep(0.01)

            self._baseline = (
                x_sum / samples,
                y_sum / samples,
                z_sum / samples
            )

            logger.info(f"ADXL345 calibrated: baseline={self._baseline}")

        except Exception as e:
            logger.error(f"Error calibrating ADXL345: {e}")
            self._baseline = (0, 0, 1)  # Assume gravity on Z axis

    def _read_raw(self) -> Tuple[float, float, float]:
        """Read raw acceleration values"""
        # Read 6 bytes starting from DATAX0
        data = self.bus.read_i2c_block_data(self.i2c_address, self.REG_DATAX0, 6)

        # Convert to signed 16-bit integers
        x = self._bytes_to_int(data[0], data[1])
        y = self._bytes_to_int(data[2], data[3])
        z = self._bytes_to_int(data[4], data[5])

        # Apply scale
        x = x * self.SCALE_MULTIPLIER
        y = y * self.SCALE_MULTIPLIER
        z = z * self.SCALE_MULTIPLIER

        return (x, y, z)

    def _bytes_to_int(self, low_byte: int, high_byte: int) -> int:
        """Convert two bytes to signed 16-bit integer"""
        value = (high_byte << 8) | low_byte
        if value >= 32768:
            value -= 65536
        return value

    def read(self) -> Optional[Dict[str, Any]]:
        """
        Read acceleration values

        Returns:
            Dict with x, y, z acceleration in g's
        """
        if not self._initialized:
            logger.warning("ADXL345 not initialized")
            return None

        try:
            x, y, z = self._read_raw()

            # Calculate magnitude
            magnitude = math.sqrt(x**2 + y**2 + z**2)

            return {
                'acceleration_x': {
                    'value': round(x, 3),
                    'unit': 'g'
                },
                'acceleration_y': {
                    'value': round(y, 3),
                    'unit': 'g'
                },
                'acceleration_z': {
                    'value': round(z, 3),
                    'unit': 'g'
                },
                'magnitude': {
                    'value': round(magnitude, 3),
                    'unit': 'g'
                }
            }

        except Exception as e:
            logger.error(f"Error reading ADXL345: {e}")
            return None

    def detect_motion(self, threshold: float = 0.1) -> bool:
        """
        Detect motion by comparing to baseline

        Args:
            threshold: Acceleration change threshold in g's

        Returns:
            True if motion detected
        """
        if not self._initialized or not self._baseline:
            return False

        try:
            x, y, z = self._read_raw()

            # Calculate difference from baseline
            dx = abs(x - self._baseline[0])
            dy = abs(y - self._baseline[1])
            dz = abs(z - self._baseline[2])

            # Check if any axis exceeds threshold
            motion = max(dx, dy, dz) > threshold

            if motion:
                logger.debug(f"Motion detected: dx={dx:.3f}, dy={dy:.3f}, dz={dz:.3f}")

            return motion

        except Exception as e:
            logger.error(f"Error detecting motion: {e}")
            return False

    def get_vibration_level(self) -> Optional[str]:
        """
        Get vibration level category

        Returns:
            String: 'none', 'low', 'medium', 'high'
        """
        if not self._initialized or not self._baseline:
            return None

        try:
            x, y, z = self._read_raw()

            # Calculate RMS of deviation from baseline
            dx = x - self._baseline[0]
            dy = y - self._baseline[1]
            dz = z - self._baseline[2]

            rms = math.sqrt((dx**2 + dy**2 + dz**2) / 3)

            if rms < 0.05:
                return 'none'
            elif rms < 0.15:
                return 'low'
            elif rms < 0.3:
                return 'medium'
            else:
                return 'high'

        except Exception as e:
            logger.error(f"Error getting vibration level: {e}")
            return None

    def close(self):
        """Close sensor"""
        if self.bus:
            try:
                # Disable measurements
                self.bus.write_byte_data(self.i2c_address, self.REG_POWER_CTL, 0x00)
            except:
                pass
            self.bus.close()

        self._initialized = False
        logger.info("ADXL345 sensor closed")
