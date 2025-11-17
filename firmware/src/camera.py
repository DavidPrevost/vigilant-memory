"""
Camera module for baby monitor.

Handles video capture using picamera2 library.
Supports multiple resolutions and frame rates.
"""

import time
import logging
from typing import Optional, Tuple
from picamera2 import Picamera2
from picamera2.encoders import H264Encoder, Quality
from picamera2.outputs import FileOutput
import io

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CameraManager:
    """Manages camera capture and configuration."""

    def __init__(self, resolution: Tuple[int, int] = (1280, 720), framerate: int = 30):
        """
        Initialize camera manager.

        Args:
            resolution: Video resolution as (width, height). Default 720p.
            framerate: Frames per second. Default 30.
        """
        self.resolution = resolution
        self.framerate = framerate
        self.picam2: Optional[Picamera2] = None
        self.encoder: Optional[H264Encoder] = None
        self.is_recording = False

        logger.info(f"Camera manager initialized: {resolution[0]}x{resolution[1]} @ {framerate}fps")

    def start(self):
        """Start the camera."""
        if self.picam2 is not None:
            logger.warning("Camera already started")
            return

        try:
            self.picam2 = Picamera2()

            # Create video configuration
            video_config = self.picam2.create_video_configuration(
                main={
                    "size": self.resolution,
                    "format": "RGB888"
                },
                controls={
                    "FrameRate": self.framerate
                }
            )

            self.picam2.configure(video_config)
            self.picam2.start()

            logger.info("Camera started successfully")

        except Exception as e:
            logger.error(f"Failed to start camera: {e}")
            raise

    def stop(self):
        """Stop the camera."""
        if self.picam2 is None:
            logger.warning("Camera not started")
            return

        try:
            if self.is_recording:
                self.stop_recording()

            self.picam2.stop()
            self.picam2.close()
            self.picam2 = None

            logger.info("Camera stopped")

        except Exception as e:
            logger.error(f"Error stopping camera: {e}")
            raise

    def capture_frame(self) -> Optional[bytes]:
        """
        Capture a single frame as JPEG.

        Returns:
            JPEG image data as bytes, or None if error.
        """
        if self.picam2 is None:
            logger.error("Camera not started")
            return None

        try:
            # Capture to memory buffer
            buffer = io.BytesIO()
            self.picam2.capture_file(buffer, format='jpeg')
            buffer.seek(0)

            return buffer.read()

        except Exception as e:
            logger.error(f"Error capturing frame: {e}")
            return None

    def start_recording(self, output_file: str):
        """
        Start recording video to file.

        Args:
            output_file: Path to output video file (H.264).
        """
        if self.picam2 is None:
            logger.error("Camera not started")
            return

        if self.is_recording:
            logger.warning("Already recording")
            return

        try:
            # Create H.264 encoder
            self.encoder = H264Encoder(bitrate=3000000)  # 3 Mbps

            # Start recording
            output = FileOutput(output_file)
            self.picam2.start_recording(self.encoder, output)
            self.is_recording = True

            logger.info(f"Started recording to {output_file}")

        except Exception as e:
            logger.error(f"Error starting recording: {e}")
            raise

    def stop_recording(self):
        """Stop recording video."""
        if not self.is_recording:
            logger.warning("Not recording")
            return

        try:
            self.picam2.stop_recording()
            self.is_recording = False
            self.encoder = None

            logger.info("Stopped recording")

        except Exception as e:
            logger.error(f"Error stopping recording: {e}")
            raise

    def get_stream(self):
        """
        Get video stream for live streaming.

        Returns:
            Camera stream object for use with streaming servers.
        """
        if self.picam2 is None:
            logger.error("Camera not started")
            return None

        return self.picam2

    def set_resolution(self, width: int, height: int):
        """
        Change video resolution.

        Args:
            width: Video width in pixels.
            height: Video height in pixels.

        Note: Requires camera restart to take effect.
        """
        self.resolution = (width, height)
        logger.info(f"Resolution set to {width}x{height} (restart camera to apply)")

    def set_framerate(self, fps: int):
        """
        Change frame rate.

        Args:
            fps: Frames per second.

        Note: Requires camera restart to take effect.
        """
        self.framerate = fps
        logger.info(f"Framerate set to {fps} (restart camera to apply)")


def main():
    """Test camera functionality."""
    print("Baby Monitor - Camera Test")
    print("=" * 50)

    # Test 720p camera
    camera = CameraManager(resolution=(1280, 720), framerate=30)

    try:
        # Start camera
        print("\n1. Starting camera...")
        camera.start()
        time.sleep(2)  # Let camera initialize

        # Capture a test frame
        print("\n2. Capturing test frame...")
        frame = camera.capture_frame()
        if frame:
            # Save to file
            with open("/tmp/test_frame.jpg", "wb") as f:
                f.write(frame)
            print(f"   ✓ Captured frame ({len(frame)} bytes)")
            print("   ✓ Saved to /tmp/test_frame.jpg")
        else:
            print("   ✗ Failed to capture frame")

        # Test recording
        print("\n3. Testing video recording (5 seconds)...")
        camera.start_recording("/tmp/test_video.h264")
        time.sleep(5)
        camera.stop_recording()
        print("   ✓ Recording saved to /tmp/test_video.h264")

        # Display camera info
        print("\n4. Camera information:")
        print(f"   Resolution: {camera.resolution[0]}x{camera.resolution[1]}")
        print(f"   Framerate: {camera.framerate} fps")
        print(f"   Status: {'Recording' if camera.is_recording else 'Idle'}")

        print("\n✓ All tests passed!")

    except Exception as e:
        print(f"\n✗ Error: {e}")

    finally:
        # Clean up
        print("\n5. Stopping camera...")
        camera.stop()
        print("   ✓ Camera stopped")

    print("\n" + "=" * 50)
    print("Camera test complete!")


if __name__ == "__main__":
    main()
