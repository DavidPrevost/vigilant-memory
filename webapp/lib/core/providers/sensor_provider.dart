import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/sensor_reading.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'websocket_provider.dart';

// Sensor Readings State Notifier
class SensorReadingsNotifier extends StateNotifier<AsyncValue<List<SensorReading>>> {
  final ApiClient _apiClient;
  final Ref _ref;
  SensorReadingFilter? _currentFilter;

  SensorReadingsNotifier(this._apiClient, this._ref) : super(const AsyncValue.loading()) {
    fetchReadings();
    _listenToWebSocketUpdates();
  }

  // Listen to WebSocket sensor reading updates
  void _listenToWebSocketUpdates() {
    _ref.listen(sensorReadingStreamProvider, (previous, next) {
      next.whenData((readingData) {
        addNewReading(SensorReading.fromJson(readingData));
      });
    });
  }

  // Fetch sensor readings with optional filter
  Future<void> fetchReadings([SensorReadingFilter? filter]) async {
    _currentFilter = filter;
    state = const AsyncValue.loading();

    try {
      final queryParams = filter?.toQueryParameters() ?? {};
      final response = await _apiClient.get(
        ApiEndpoints.sensorReadings,
        queryParameters: queryParams,
      );

      final readings = (response.data as List)
          .map((json) => SensorReading.fromJson(json))
          .toList();

      state = AsyncValue.data(readings);
    } catch (e, stack) {
      state = AsyncValue.error(
        ApiException.fromDioException(e as DioException),
        stack,
      );
    }
  }

  // Refresh readings (using current filter)
  Future<void> refresh() async {
    await fetchReadings(_currentFilter);
  }

  // Add new reading from WebSocket
  void addNewReading(SensorReading newReading) {
    state.whenData((readings) {
      // Add to beginning of list and limit to last 1000 readings to prevent memory issues
      final newReadings = [newReading, ...readings];
      if (newReadings.length > 1000) {
        newReadings.removeRange(1000, newReadings.length);
      }
      state = AsyncValue.data(newReadings);
    });
  }

  // Load more readings (pagination)
  Future<void> loadMore() async {
    state.whenData((currentReadings) async {
      try {
        final filter = _currentFilter?.copyWith(
          offset: currentReadings.length,
        ) ?? SensorReadingFilter(offset: currentReadings.length);

        final queryParams = filter.toQueryParameters();
        final response = await _apiClient.get(
          ApiEndpoints.sensorReadings,
          queryParameters: queryParams,
        );

        final newReadings = (response.data as List)
            .map((json) => SensorReading.fromJson(json))
            .toList();

        // Append new readings to existing list
        final allReadings = [...currentReadings, ...newReadings];
        state = AsyncValue.data(allReadings);
      } catch (e) {
        print('Error loading more readings: $e');
      }
    });
  }

  // Export sensor data to CSV
  Future<String?> exportToCsv(String deviceId, DateTime startDate, DateTime endDate) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.sensorReadingsExport(
          deviceId,
          startDate.toIso8601String(),
          endDate.toIso8601String(),
        ),
      );

      return response.data as String;
    } catch (e) {
      print('Error exporting sensor data: $e');
      return null;
    }
  }
}

// Sensor Readings Provider
final sensorReadingsProvider =
    StateNotifierProvider<SensorReadingsNotifier, AsyncValue<List<SensorReading>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SensorReadingsNotifier(apiClient, ref);
});

// Device sensor readings provider
final deviceSensorReadingsProvider =
    FutureProvider.family<List<SensorReading>, String>((ref, deviceId) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.get(
      ApiEndpoints.sensorReadingsByDevice(deviceId),
    );
    return (response.data as List)
        .map((json) => SensorReading.fromJson(json))
        .toList();
  } catch (e) {
    print('Error fetching device sensor readings: $e');
    return [];
  }
});

// Current sensor stats provider (latest values by type)
final currentSensorStatsProvider = Provider<Map<String, SensorStats>>((ref) {
  final readingsState = ref.watch(sensorReadingsProvider);

  return readingsState.when(
    data: (readings) {
      final stats = <String, SensorStats>{};

      // Group readings by sensor type
      final groupedReadings = <String, List<SensorReading>>{};
      for (final reading in readings) {
        groupedReadings.putIfAbsent(reading.sensorType, () => []);
        groupedReadings[reading.sensorType]!.add(reading);
      }

      // Calculate stats for each sensor type
      for (final entry in groupedReadings.entries) {
        final sensorType = entry.key;
        final sensorReadings = entry.value;

        if (sensorReadings.isEmpty) continue;

        final values = sensorReadings.map((r) => r.value).toList();
        final currentValue = sensorReadings.first.value;
        final minValue = values.reduce((a, b) => a < b ? a : b);
        final maxValue = values.reduce((a, b) => a > b ? a : b);
        final avgValue = values.reduce((a, b) => a + b) / values.length;
        final lastUpdated = sensorReadings.first.timestamp;

        stats[sensorType] = SensorStats(
          sensorType: sensorType,
          currentValue: currentValue,
          minValue: minValue,
          maxValue: maxValue,
          avgValue: avgValue,
          lastUpdated: lastUpdated,
        );
      }

      return stats;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Chart data provider for a specific sensor type
final sensorChartDataProvider =
    Provider.family<List<SensorChartData>, String>((ref, sensorType) {
  final readingsState = ref.watch(sensorReadingsProvider);

  return readingsState.when(
    data: (readings) {
      final filteredReadings = readings
          .where((r) => r.sensorType == sensorType)
          .take(100) // Limit to last 100 readings for chart
          .toList();

      return filteredReadings
          .map((r) => SensorChartData(
                timestamp: r.timestamp,
                value: r.value,
              ))
          .toList()
          .reversed
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Temperature alert provider (example threshold check)
final temperatureAlertProvider = Provider<bool>((ref) {
  final stats = ref.watch(currentSensorStatsProvider);
  final tempStat = stats[SensorTypes.temperature];

  if (tempStat == null) return false;

  // Alert if temperature is outside 18-26°C range
  return tempStat.currentValue < 18 || tempStat.currentValue > 26;
});

// Humidity alert provider
final humidityAlertProvider = Provider<bool>((ref) {
  final stats = ref.watch(currentSensorStatsProvider);
  final humidityStat = stats[SensorTypes.humidity];

  if (humidityStat == null) return false;

  // Alert if humidity is outside 30-70% range
  return humidityStat.currentValue < 30 || humidityStat.currentValue > 70;
});
