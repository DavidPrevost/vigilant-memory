"""
Web server for baby monitor.

Serves web interface and provides API endpoints for camera control.
"""

import logging
from flask import Flask, render_template, Response, jsonify
from flask_cors import CORS
from camera import CameraManager
import time

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create Flask app
app = Flask(__name__,
            static_folder='web/static',
            template_folder='web/templates')
CORS(app)

# Global camera instance
camera: CameraManager = None


def get_camera() -> CameraManager:
    """Get or create camera instance."""
    global camera
    if camera is None:
        camera = CameraManager(resolution=(1280, 720), framerate=30)
        camera.start()
    return camera


def generate_frames():
    """
    Generator function for MJPEG streaming.
    Yields JPEG frames continuously.
    """
    cam = get_camera()

    while True:
        try:
            # Capture frame
            frame = cam.capture_frame()

            if frame is None:
                logger.warning("Failed to capture frame")
                time.sleep(0.1)
                continue

            # Yield frame in multipart format
            yield (b'--frame\r\n'
                   b'Content-Type: image/jpeg\r\n\r\n' + frame + b'\r\n')

            # Control frame rate (30fps = ~33ms per frame)
            time.sleep(0.033)

        except Exception as e:
            logger.error(f"Error in frame generation: {e}")
            time.sleep(0.1)


@app.route('/')
def index():
    """Serve main web interface."""
    return render_template('index.html')


@app.route('/video_feed')
def video_feed():
    """
    Video streaming route.
    Returns MJPEG stream.
    """
    return Response(
        generate_frames(),
        mimetype='multipart/x-mixed-replace; boundary=frame'
    )


@app.route('/api/status')
def status():
    """Get camera status."""
    cam = get_camera()
    return jsonify({
        'status': 'online',
        'resolution': {
            'width': cam.resolution[0],
            'height': cam.resolution[1]
        },
        'framerate': cam.framerate,
        'recording': cam.is_recording
    })


@app.route('/api/snapshot')
def snapshot():
    """Capture and return a single snapshot."""
    cam = get_camera()
    frame = cam.capture_frame()

    if frame is None:
        return jsonify({'error': 'Failed to capture snapshot'}), 500

    return Response(frame, mimetype='image/jpeg')


@app.route('/api/camera/resolution/<int:width>/<int:height>', methods=['POST'])
def set_resolution(width: int, height: int):
    """
    Set camera resolution.

    Note: Requires camera restart.
    """
    cam = get_camera()
    cam.set_resolution(width, height)

    return jsonify({
        'message': 'Resolution updated (restart camera to apply)',
        'resolution': {'width': width, 'height': height}
    })


def main():
    """Run web server."""
    print("Baby Monitor - Web Server")
    print("=" * 50)
    print("\nStarting server...")
    print("Access the monitor at: http://raspberrypi.local:5000")
    print("Or: http://<your-pi-ip>:5000")
    print("\nPress Ctrl+C to stop")
    print("=" * 50)

    try:
        # Run Flask app
        app.run(
            host='0.0.0.0',  # Listen on all interfaces
            port=5000,
            debug=True,
            threaded=True
        )
    except KeyboardInterrupt:
        print("\n\nShutting down...")
        if camera:
            camera.stop()
        print("Server stopped")


if __name__ == '__main__':
    main()
