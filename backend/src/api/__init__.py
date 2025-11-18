"""
API Blueprints
"""
from flask import Blueprint

def register_blueprints(app):
    """Register all API blueprints"""
    from .users import users_bp
    from .devices import devices_bp
    from .events import events_bp
    from .videos import videos_bp
    from .sensors import sensors_bp

    # Register blueprints with /api prefix
    app.register_blueprint(users_bp, url_prefix='/api/users')
    app.register_blueprint(devices_bp, url_prefix='/api/devices')
    app.register_blueprint(events_bp, url_prefix='/api/events')
    app.register_blueprint(videos_bp, url_prefix='/api/videos')
    app.register_blueprint(sensors_bp, url_prefix='/api/sensors')

    app.logger.info('API blueprints registered')
