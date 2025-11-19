import 'package:freezed_annotation/freezed_annotation.dart';

part 'video.freezed.dart';
part 'video.g.dart';

@freezed
class Video with _$Video {
  const factory Video({
    required String id,
    required String deviceId,
    required String filename,
    String? eventId,
    required String recordingType,
    required int fileSizeBytes,
    int? durationSeconds,
    String? thumbnailUrl,
    String? storageUrl,
    required DateTime recordedAt,
    required DateTime uploadedAt,
    // Denormalized device info
    String? deviceName,
  }) = _Video;

  factory Video.fromJson(Map<String, dynamic> json) => _$VideoFromJson(json);
}

// Recording types
class RecordingTypes {
  static const String continuous = 'continuous';
  static const String eventTriggered = 'event_triggered';
  static const String manual = 'manual';
  static const String snapshot = 'snapshot';

  static List<String> get all => [continuous, eventTriggered, manual, snapshot];

  static String getDisplayName(String type) {
    switch (type) {
      case continuous:
        return 'Continuous Recording';
      case eventTriggered:
        return 'Event Triggered';
      case manual:
        return 'Manual Recording';
      case snapshot:
        return 'Snapshot';
      default:
        return type;
    }
  }
}

// Video filter options
@freezed
class VideoFilter with _$VideoFilter {
  const factory VideoFilter({
    String? deviceId,
    String? eventId,
    List<String>? recordingTypes,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) = _VideoFilter;

  factory VideoFilter.fromJson(Map<String, dynamic> json) => _$VideoFilterFromJson(json);

  // Convert to query parameters
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    if (deviceId != null) params['device_id'] = deviceId;
    if (eventId != null) params['event_id'] = eventId;
    if (recordingTypes != null && recordingTypes!.isNotEmpty) {
      params['recording_types'] = recordingTypes!.join(',');
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

// Video stats model
@freezed
class VideoStats with _$VideoStats {
  const factory VideoStats({
    required int totalVideos,
    required int totalSizeBytes,
    required int continuousCount,
    required int eventTriggeredCount,
    required int manualCount,
    required int snapshotCount,
  }) = _VideoStats;

  factory VideoStats.fromJson(Map<String, dynamic> json) => _$VideoStatsFromJson(json);

  // Helper to get formatted size
  String getFormattedSize() {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = totalSizeBytes.toDouble();
    var unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }
}
