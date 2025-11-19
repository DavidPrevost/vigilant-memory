import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API Configuration
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  static String get wsUrl => dotenv.env['WS_URL'] ?? 'http://localhost:5000';

  // App Info
  static const String appName = 'Baby Monitor';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int eventsPerPage = 50;
  static const int videosPerPage = 20;
  static const int devicesPerPage = 20;

  // Refresh Intervals
  static const Duration statusUpdateInterval = Duration(seconds: 60);
  static const Duration sensorUpdateInterval = Duration(seconds: 10);
  static const Duration wsReconnectDelay = Duration(seconds: 5);

  // Video
  static const List<String> supportedVideoFormats = ['mp4', 'avi', 'mov', 'mkv'];
  static const int maxVideoSizeMB = 500;

  // Sensor Chart Time Ranges
  static const Map<String, Duration> chartTimeRanges = {
    '1h': Duration(hours: 1),
    '6h': Duration(hours: 6),
    '24h': Duration(hours: 24),
    '7d': Duration(days: 7),
    '30d': Duration(days: 30),
  };

  // Theme
  static const String fontFamily = 'Inter';

  // Storage Keys
  static const String themeModeKey = 'theme_mode';
  static const String temperatureUnitKey = 'temperature_unit';
  static const String defaultViewKey = 'default_view';

  // Subscription Tiers
  static const List<String> subscriptionTiers = [
    'free',
    'cloud_storage',
    'ai_insights',
    'complete',
  ];

  // Event Types
  static const List<String> eventTypes = [
    'motion_detected',
    'sound_detected',
    'person_detected',
    'cry_detected',
    'temperature_alert',
    'humidity_alert',
  ];

  // Event Severities
  static const List<String> eventSeverities = [
    'info',
    'warning',
    'alert',
    'critical',
  ];

  // Device Models
  static const List<String> deviceModels = [
    'prototype',
    'core',
    'pro',
  ];

  // Sensor Types
  static const List<String> sensorTypes = [
    'temperature',
    'humidity',
    'pressure',
    'air_quality',
    'light',
    'acceleration_x',
    'acceleration_y',
    'acceleration_z',
  ];

  // Temperature Units
  static const String celsius = '°C';
  static const String fahrenheit = '°F';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxDeviceNameLength = 50;
  static const int maxNotesLength = 500;
}
