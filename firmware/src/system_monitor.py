"""
System Monitor
Tracks system health metrics (CPU, temp, battery, network)
"""
import logging
import psutil
import subprocess
from typing import Dict, Any, Optional
import socket

logger = logging.getLogger(__name__)


class SystemMonitor:
    """Monitors system health and resources"""

    def __init__(self):
        pass

    def get_cpu_usage(self) -> float:
        """Get CPU usage percentage"""
        try:
            return psutil.cpu_percent(interval=1)
        except Exception as e:
            logger.error(f"Error getting CPU usage: {e}")
            return 0.0

    def get_memory_usage(self) -> Dict[str, Any]:
        """Get memory usage information"""
        try:
            mem = psutil.virtual_memory()
            return {
                'total_mb': mem.total / (1024 * 1024),
                'available_mb': mem.available / (1024 * 1024),
                'used_mb': mem.used / (1024 * 1024),
                'percent': mem.percent
            }
        except Exception as e:
            logger.error(f"Error getting memory usage: {e}")
            return {}

    def get_cpu_temperature(self) -> Optional[float]:
        """Get CPU temperature in Celsius"""
        try:
            # Try vcgencmd (Raspberry Pi specific)
            result = subprocess.run(
                ['vcgencmd', 'measure_temp'],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                # Output format: "temp=42.8'C"
                temp_str = result.stdout.strip().split('=')[1].split("'")[0]
                return float(temp_str)

        except FileNotFoundError:
            # vcgencmd not available (not on Raspberry Pi)
            pass
        except Exception as e:
            logger.error(f"Error getting CPU temperature: {e}")

        try:
            # Try psutil sensors (Linux)
            temps = psutil.sensors_temperatures()
            if temps:
                # Get first available temperature sensor
                for name, entries in temps.items():
                    if entries:
                        return entries[0].current
        except Exception as e:
            logger.debug(f"psutil temperature not available: {e}")

        return None

    def get_disk_usage(self) -> Dict[str, Any]:
        """Get disk usage information"""
        try:
            disk = psutil.disk_usage('/')
            return {
                'total_gb': disk.total / (1024 ** 3),
                'used_gb': disk.used / (1024 ** 3),
                'free_gb': disk.free / (1024 ** 3),
                'percent': disk.percent
            }
        except Exception as e:
            logger.error(f"Error getting disk usage: {e}")
            return {}

    def get_network_info(self) -> Dict[str, Any]:
        """Get network information"""
        try:
            # Get IP address
            hostname = socket.gethostname()
            ip_address = socket.gethostbyname(hostname)

            # Get network interfaces
            interfaces = psutil.net_if_addrs()

            # Try to get WiFi info (Raspberry Pi specific)
            wifi_info = self._get_wifi_info()

            return {
                'hostname': hostname,
                'ip_address': ip_address,
                'wifi': wifi_info,
                'interfaces': list(interfaces.keys())
            }

        except Exception as e:
            logger.error(f"Error getting network info: {e}")
            return {}

    def _get_wifi_info(self) -> Dict[str, Any]:
        """Get WiFi connection information (Linux/Raspberry Pi)"""
        try:
            # Try iwconfig (Linux WiFi tool)
            result = subprocess.run(
                ['iwconfig', 'wlan0'],
                capture_output=True,
                text=True,
                timeout=5
            )

            if result.returncode == 0:
                output = result.stdout

                # Parse SSID
                ssid = None
                if 'ESSID:' in output:
                    ssid = output.split('ESSID:"')[1].split('"')[0]

                # Parse signal strength
                signal = None
                if 'Signal level=' in output:
                    signal_str = output.split('Signal level=')[1].split()[0]
                    # Convert to integer (dBm)
                    signal = int(signal_str)

                return {
                    'ssid': ssid,
                    'signal_strength': signal
                }

        except FileNotFoundError:
            # iwconfig not available
            pass
        except Exception as e:
            logger.debug(f"Error getting WiFi info: {e}")

        return {}

    def get_battery_info(self) -> Optional[Dict[str, Any]]:
        """Get battery information (if available)"""
        try:
            battery = psutil.sensors_battery()
            if battery:
                return {
                    'percent': battery.percent,
                    'is_plugged': battery.power_plugged,
                    'time_left': battery.secsleft if battery.secsleft > 0 else None
                }
        except Exception as e:
            logger.debug(f"Battery info not available: {e}")

        return None

    def get_uptime(self) -> float:
        """Get system uptime in seconds"""
        try:
            import time
            boot_time = psutil.boot_time()
            return time.time() - boot_time
        except Exception as e:
            logger.error(f"Error getting uptime: {e}")
            return 0.0

    def get_full_status(self) -> Dict[str, Any]:
        """Get comprehensive system status"""
        status = {
            'cpu_usage_percent': self.get_cpu_usage(),
            'cpu_temperature_celsius': self.get_cpu_temperature(),
            'memory': self.get_memory_usage(),
            'disk': self.get_disk_usage(),
            'network': self.get_network_info(),
            'battery': self.get_battery_info(),
            'uptime_seconds': self.get_uptime()
        }

        return status

    def is_healthy(self) -> bool:
        """Check if system is healthy"""
        try:
            # Check CPU temperature
            temp = self.get_cpu_temperature()
            if temp and temp > 80:  # Over 80°C
                logger.warning(f"High CPU temperature: {temp}°C")
                return False

            # Check disk space
            disk = self.get_disk_usage()
            if disk and disk.get('percent', 0) > 90:  # Over 90% full
                logger.warning(f"Low disk space: {disk.get('percent')}%")
                return False

            # Check memory
            mem = self.get_memory_usage()
            if mem and mem.get('percent', 0) > 90:  # Over 90% used
                logger.warning(f"High memory usage: {mem.get('percent')}%")
                return False

            return True

        except Exception as e:
            logger.error(f"Error checking system health: {e}")
            return False
