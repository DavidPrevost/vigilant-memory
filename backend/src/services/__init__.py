"""
Services Initialization
"""
from .storage import storage_service
from .mqtt import mqtt_service


def init_services(app):
    """Initialize all services"""
    # Initialize storage service
    storage_service.init_app(app)

    # Initialize MQTT service
    mqtt_service.init_app(app)

    app.logger.info('Services initialized')
