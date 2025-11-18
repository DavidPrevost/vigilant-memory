"""
Baby Monitor Backend API
Main Flask Application
"""
from flask import Flask, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO
import logging
from datetime import datetime

from .config import get_config
from .models.database import init_databases
from .api import register_blueprints
from .services import init_services


def create_app(config_name=None):
    """Application factory"""
    app = Flask(__name__)

    # Load configuration
    config = get_config()
    app.config.from_object(config)

    # Setup logging
    setup_logging(app)

    # Initialize CORS
    CORS(app, origins=app.config.get('CORS_ORIGINS', '*'))

    # Initialize databases
    init_databases(app)

    # Initialize services (MQTT, MinIO, Redis, etc.)
    init_services(app)

    # Register API blueprints
    register_blueprints(app)

    # Initialize SocketIO for WebSocket support
    socketio = SocketIO(
        app,
        cors_allowed_origins=app.config.get('CORS_ORIGINS', '*'),
        async_mode='gevent'
    )

    # Health check endpoint
    @app.route('/health', methods=['GET'])
    def health_check():
        """Health check endpoint"""
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.utcnow().isoformat(),
            'version': '1.0.0'
        })

    # Root endpoint
    @app.route('/', methods=['GET'])
    def root():
        """Root endpoint"""
        return jsonify({
            'name': 'Baby Monitor API',
            'version': '1.0.0',
            'documentation': '/api/docs',
            'health': '/health'
        })

    # Error handlers
    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Not found'}), 404

    @app.errorhandler(500)
    def internal_error(error):
        app.logger.error(f'Internal error: {str(error)}')
        return jsonify({'error': 'Internal server error'}), 500

    app.socketio = socketio
    return app


def setup_logging(app):
    """Setup application logging"""
    log_level = getattr(logging, app.config.get('LOG_LEVEL', 'INFO'))
    log_file = app.config.get('LOG_FILE')

    # Configure logging
    logging.basicConfig(
        level=log_level,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file) if log_file else logging.StreamHandler()
        ]
    )

    app.logger.setLevel(log_level)


if __name__ == '__main__':
    app = create_app()
    socketio = app.socketio

    # Run with SocketIO
    socketio.run(
        app,
        host=app.config['HOST'],
        port=app.config['PORT'],
        debug=app.config['DEBUG']
    )
