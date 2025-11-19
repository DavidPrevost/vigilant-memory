import 'package:freezed_annotation/freezed_annotation.dart';

part 'device.freezed.dart';
part 'device.g.dart';

@freezed
class Device with _$Device {
  const factory Device({
    required String id,
    required String ownerId,
    required String deviceName,
    required String mqttClientId,
    required bool onlineStatus,
    DateTime? lastSeenAt,
    int? batteryLevel,
    Map<String, dynamic>? settings,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<SharedUser> sharedWith,
    DeviceMetrics? metrics,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

@freezed
class SharedUser with _$SharedUser {
  const factory SharedUser({
    required String userId,
    required String email,
    required String permission,
    required DateTime sharedAt,
  }) = _SharedUser;

  factory SharedUser.fromJson(Map<String, dynamic> json) => _$SharedUserFromJson(json);
}

@freezed
class DeviceMetrics with _$DeviceMetrics {
  const factory DeviceMetrics({
    double? cpuUsage,
    double? cpuTemperature,
    double? memoryUsage,
    double? diskUsage,
    String? ipAddress,
    String? wifiSsid,
    int? wifiSignalStrength,
    double? batteryPercentage,
    bool? isCharging,
  }) = _DeviceMetrics;

  factory DeviceMetrics.fromJson(Map<String, dynamic> json) => _$DeviceMetricsFromJson(json);
}

// Device settings model
@freezed
class DeviceSettings with _$DeviceSettings {
  const factory DeviceSettings({
    // Camera settings
    @Default(1920) int cameraWidth,
    @Default(1080) int cameraHeight,
    @Default(30) int cameraFps,
    @Default(15) int cameraQuality,

    // Recording settings
    @Default(true) bool enableContinuousRecording,
    @Default(true) bool enableEventRecording,
    @Default(300) int continuousRecordingSegmentDuration,
    @Default(30) int eventRecordingPreBuffer,
    @Default(60) int eventRecordingPostBuffer,

    // Detection settings
    @Default(true) bool enableMotionDetection,
    @Default(true) bool enableSoundDetection,
    @Default(true) bool enableCryDetection,
    @Default(25) int motionSensitivity,
    @Default(50) int soundSensitivity,
    @Default(50) int crySensitivity,

    // Sensor settings
    @Default(true) bool enableSensors,
    @Default(60) int sensorReadingInterval,
    @Default(true) bool enableBme680,
    @Default(true) bool enableBh1750,
    @Default(true) bool enableAdxl345,

    // Alert thresholds
    double? temperatureMinThreshold,
    double? temperatureMaxThreshold,
    double? humidityMinThreshold,
    double? humidityMaxThreshold,
    double? lightMinThreshold,
    double? lightMaxThreshold,

    // System settings
    @Default(60) int statusUpdateInterval,
    @Default(true) bool enableLedIndicator,
    @Default(true) bool enableAudioFeedback,
  }) = _DeviceSettings;

  factory DeviceSettings.fromJson(Map<String, dynamic> json) => _$DeviceSettingsFromJson(json);
}

// Device command model
@freezed
class DeviceCommand with _$DeviceCommand {
  const factory DeviceCommand({
    required String command,
    Map<String, dynamic>? params,
  }) = _DeviceCommand;

  factory DeviceCommand.fromJson(Map<String, dynamic> json) => _$DeviceCommandFromJson(json);
}

// Available commands
class DeviceCommands {
  static const String startRecording = 'start_recording';
  static const String stopRecording = 'stop_recording';
  static const String captureSnapshot = 'capture_snapshot';
  static const String updateSettings = 'update_settings';
  static const String reboot = 'reboot';
  static const String enableMotionDetection = 'enable_motion_detection';
  static const String disableMotionDetection = 'disable_motion_detection';
  static const String enableSensors = 'enable_sensors';
  static const String disableSensors = 'disable_sensors';
}
