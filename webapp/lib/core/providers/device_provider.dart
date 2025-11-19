import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/device.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'websocket_provider.dart';

// Devices State Notifier
class DevicesNotifier extends StateNotifier<AsyncValue<List<Device>>> {
  final ApiClient _apiClient;
  final Ref _ref;

  DevicesNotifier(this._apiClient, this._ref) : super(const AsyncValue.loading()) {
    fetchDevices();
    _listenToWebSocketUpdates();
  }

  // Listen to WebSocket device status updates
  void _listenToWebSocketUpdates() {
    _ref.listen(deviceStatusStreamProvider, (previous, next) {
      next.whenData((statusData) {
        updateDeviceStatus(statusData);
      });
    });
  }

  // Fetch all devices
  Future<void> fetchDevices() async {
    state = const AsyncValue.loading();

    try {
      final response = await _apiClient.get(ApiEndpoints.devices);
      final devices = (response.data as List)
          .map((json) => Device.fromJson(json))
          .toList();

      state = AsyncValue.data(devices);
    } catch (e, stack) {
      state = AsyncValue.error(
        ApiException.fromDioException(e as DioException),
        stack,
      );
    }
  }

  // Get device by ID
  Future<Device?> getDevice(String deviceId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.device(deviceId));
      return Device.fromJson(response.data);
    } catch (e) {
      print('Error fetching device: $e');
      return null;
    }
  }

  // Update device in state
  void updateDevice(Device updatedDevice) {
    state.whenData((devices) {
      final index = devices.indexWhere((d) => d.id == updatedDevice.id);
      if (index != -1) {
        final newDevices = [...devices];
        newDevices[index] = updatedDevice;
        state = AsyncValue.data(newDevices);
      }
    });
  }

  // Update device status from WebSocket
  void updateDeviceStatus(Map<String, dynamic> statusData) {
    state.whenData((devices) {
      final deviceId = statusData['device_id'] as String?;
      if (deviceId == null) return;

      final index = devices.indexWhere((d) => d.id == deviceId);
      if (index != -1) {
        final device = devices[index];
        final updatedDevice = device.copyWith(
          onlineStatus: statusData['online_status'] as bool? ?? device.onlineStatus,
          lastSeenAt: statusData['last_seen_at'] != null
              ? DateTime.parse(statusData['last_seen_at'])
              : device.lastSeenAt,
          batteryLevel: statusData['battery_level'] as int? ?? device.batteryLevel,
        );

        final newDevices = [...devices];
        newDevices[index] = updatedDevice;
        state = AsyncValue.data(newDevices);
      }
    });
  }

  // Send command to device
  Future<bool> sendCommand(String deviceId, DeviceCommand command) async {
    try {
      await _apiClient.post(
        ApiEndpoints.deviceCommand(deviceId),
        data: command.toJson(),
      );
      return true;
    } catch (e) {
      print('Error sending command: $e');
      return false;
    }
  }

  // Update device settings
  Future<bool> updateSettings(String deviceId, DeviceSettings settings) async {
    try {
      final response = await _apiClient.put(
        ApiEndpoints.deviceSettings(deviceId),
        data: settings.toJson(),
      );

      // Update device in state
      final updatedDevice = Device.fromJson(response.data);
      updateDevice(updatedDevice);

      return true;
    } catch (e) {
      print('Error updating settings: $e');
      return false;
    }
  }

  // Share device with user
  Future<bool> shareDevice(String deviceId, String email, String permission) async {
    try {
      await _apiClient.post(
        ApiEndpoints.deviceShare(deviceId),
        data: {
          'email': email,
          'permission': permission,
        },
      );

      // Refresh devices to get updated shared_with list
      await fetchDevices();

      return true;
    } catch (e) {
      print('Error sharing device: $e');
      return false;
    }
  }

  // Unshare device
  Future<bool> unshareDevice(String deviceId, String userId) async {
    try {
      await _apiClient.delete(ApiEndpoints.deviceUnshare(deviceId, userId));

      // Refresh devices to get updated shared_with list
      await fetchDevices();

      return true;
    } catch (e) {
      print('Error unsharing device: $e');
      return false;
    }
  }

  // Delete device
  Future<bool> deleteDevice(String deviceId) async {
    try {
      await _apiClient.delete(ApiEndpoints.device(deviceId));

      // Remove from state
      state.whenData((devices) {
        final newDevices = devices.where((d) => d.id != deviceId).toList();
        state = AsyncValue.data(newDevices);
      });

      return true;
    } catch (e) {
      print('Error deleting device: $e');
      return false;
    }
  }
}

// Devices Provider
final devicesProvider = StateNotifierProvider<DevicesNotifier, AsyncValue<List<Device>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DevicesNotifier(apiClient, ref);
});

// Single device provider (by ID)
final deviceProvider = FutureProvider.family<Device?, String>((ref, deviceId) async {
  final devicesState = ref.watch(devicesProvider);

  return devicesState.when(
    data: (devices) {
      final device = devices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => throw Exception('Device not found'),
      );
      return device;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Online devices count provider
final onlineDevicesCountProvider = Provider<int>((ref) {
  final devicesState = ref.watch(devicesProvider);

  return devicesState.when(
    data: (devices) => devices.where((d) => d.onlineStatus).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Offline devices count provider
final offlineDevicesCountProvider = Provider<int>((ref) {
  final devicesState = ref.watch(devicesProvider);

  return devicesState.when(
    data: (devices) => devices.where((d) => !d.onlineStatus).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});
