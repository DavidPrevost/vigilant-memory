import 'package:freezed_annotation/freezed_annotation.dart';

part 'sensor_reading.freezed.dart';
part 'sensor_reading.g.dart';

@freezed
class SensorReading with _$SensorReading {
  const factory SensorReading({
    required String deviceId,
    required String sensorType,
    required double value,
    String? unit,
    Map<String, dynamic>? metadata,
    required DateTime timestamp,
    // Denormalized device info
    String? deviceName,
  }) = _SensorReading;

  factory SensorReading.fromJson(Map<String, dynamic> json) => _$SensorReadingFromJson(json);
}

// Sensor types
class SensorTypes {
  static const String temperature = 'temperature';
  static const String humidity = 'humidity';
  static const String pressure = 'pressure';
  static const String airQuality = 'air_quality';
  static const String light = 'light';
  static const String motion = 'motion';
  static const String sound = 'sound';

  static List<String> get all => [
    temperature,
    humidity,
    pressure,
    airQuality,
    light,
    motion,
    sound,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case temperature:
        return 'Temperature';
      case humidity:
        return 'Humidity';
      case pressure:
        return 'Pressure';
      case airQuality:
        return 'Air Quality';
      case light:
        return 'Light Level';
      case motion:
        return 'Motion';
      case sound:
        return 'Sound Level';
      default:
        return type;
    }
  }

  static String getUnit(String type) {
    switch (type) {
      case temperature:
        return '°C';
      case humidity:
        return '%';
      case pressure:
        return 'hPa';
      case airQuality:
        return 'IAQ';
      case light:
        return 'lux';
      case motion:
        return 'g';
      case sound:
        return 'dB';
      default:
        return '';
    }
  }

  static String getIcon(String type) {
    switch (type) {
      case temperature:
        return '🌡️';
      case humidity:
        return '💧';
      case pressure:
        return '🔽';
      case airQuality:
        return '🌬️';
      case light:
        return '💡';
      case motion:
        return '📳';
      case sound:
        return '🔊';
      default:
        return '📊';
    }
  }
}

// Sensor reading filter
@freezed
class SensorReadingFilter with _$SensorReadingFilter {
  const factory SensorReadingFilter({
    String? deviceId,
    List<String>? sensorTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) = _SensorReadingFilter;

  factory SensorReadingFilter.fromJson(Map<String, dynamic> json) =>
      _$SensorReadingFilterFromJson(json);

  // Convert to query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (deviceId != null) params['device_id'] = deviceId;
    if (sensorTypes != null && sensorTypes!.isNotEmpty) {
      params['sensor_types'] = sensorTypes!.join(',');
    }
    if (startDate != null) {
      params['start_date'] = startDate!.toIso8601String();
    }
    if (endDate != null) {
      params['end_date'] = endDate!.toIso8601String();
    }
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    return params;
  }
}

// Aggregated sensor stats
@freezed
class SensorStats with _$SensorStats {
  const factory SensorStats({
    required String sensorType,
    required double currentValue,
    required double minValue,
    required double maxValue,
    required double avgValue,
    required DateTime lastUpdated,
  }) = _SensorStats;

  factory SensorStats.fromJson(Map<String, dynamic> json) => _$SensorStatsFromJson(json);
}

// Chart data point
@freezed
class SensorChartData with _$SensorChartData {
  const factory SensorChartData({
    required DateTime timestamp,
    required double value,
  }) = _SensorChartData;

  factory SensorChartData.fromJson(Map<String, dynamic> json) =>
      _$SensorChartDataFromJson(json);
}
