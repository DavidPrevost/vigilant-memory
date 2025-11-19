import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.freezed.dart';
part 'event.g.dart';

@freezed
class Event with _$Event {
  const factory Event({
    required String id,
    required String deviceId,
    required String eventType,
    required String severity,
    String? description,
    Map<String, dynamic>? metadata,
    String? videoId,
    String? snapshotUrl,
    @Default(false) bool isRead,
    required DateTime occurredAt,
    required DateTime createdAt,
    // Denormalized device info for easier display
    String? deviceName,
  }) = _Event;

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
}

// Event types
class EventTypes {
  static const String motionDetected = 'motion_detected';
  static const String soundDetected = 'sound_detected';
  static const String cryDetected = 'cry_detected';
  static const String temperatureAlert = 'temperature_alert';
  static const String humidityAlert = 'humidity_alert';
  static const String deviceOnline = 'device_online';
  static const String deviceOffline = 'device_offline';
  static const String lowBattery = 'low_battery';
  static const String systemAlert = 'system_alert';
  static const String recordingStarted = 'recording_started';
  static const String recordingStopped = 'recording_stopped';
  static const String snapshotCaptured = 'snapshot_captured';

  static List<String> get all => [
    motionDetected,
    soundDetected,
    cryDetected,
    temperatureAlert,
    humidityAlert,
    deviceOnline,
    deviceOffline,
    lowBattery,
    systemAlert,
    recordingStarted,
    recordingStopped,
    snapshotCaptured,
  ];

  static String getDisplayName(String eventType) {
    switch (eventType) {
      case motionDetected:
        return 'Motion Detected';
      case soundDetected:
        return 'Sound Detected';
      case cryDetected:
        return 'Cry Detected';
      case temperatureAlert:
        return 'Temperature Alert';
      case humidityAlert:
        return 'Humidity Alert';
      case deviceOnline:
        return 'Device Online';
      case deviceOffline:
        return 'Device Offline';
      case lowBattery:
        return 'Low Battery';
      case systemAlert:
        return 'System Alert';
      case recordingStarted:
        return 'Recording Started';
      case recordingStopped:
        return 'Recording Stopped';
      case snapshotCaptured:
        return 'Snapshot Captured';
      default:
        return eventType;
    }
  }
}

// Severity levels
class EventSeverity {
  static const String info = 'info';
  static const String warning = 'warning';
  static const String alert = 'alert';
  static const String critical = 'critical';

  static List<String> get all => [info, warning, alert, critical];

  static String getDisplayName(String severity) {
    switch (severity) {
      case info:
        return 'Info';
      case warning:
        return 'Warning';
      case alert:
        return 'Alert';
      case critical:
        return 'Critical';
      default:
        return severity;
    }
  }
}

// Event filter options
@freezed
class EventFilter with _$EventFilter {
  const factory EventFilter({
    String? deviceId,
    List<String>? eventTypes,
    List<String>? severities,
    DateTime? startDate,
    DateTime? endDate,
    bool? unreadOnly,
    int? limit,
    int? offset,
  }) = _EventFilter;

  const EventFilter._();

  factory EventFilter.fromJson(Map<String, dynamic> json) => _$EventFilterFromJson(json);

  // Convert to query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (deviceId != null) params['device_id'] = deviceId;
    if (eventTypes != null && eventTypes!.isNotEmpty) {
      params['event_types'] = eventTypes!.join(',');
    }
    if (severities != null && severities!.isNotEmpty) {
      params['severities'] = severities!.join(',');
    }
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }
    if (unreadOnly != null) params['unread_only'] = unreadOnly.toString();
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    return params;
  }
}
