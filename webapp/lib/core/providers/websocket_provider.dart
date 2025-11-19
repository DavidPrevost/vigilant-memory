import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/websocket_client.dart';
import 'auth_provider.dart';
export '../api/websocket_client.dart'
    show
        WebSocketStatus,
        webSocketClientProvider,
        webSocketStatusProvider,
        deviceStatusStreamProvider,
        eventStreamProvider,
        sensorReadingStreamProvider,
        videoUploadStreamProvider;

// WebSocket Manager Notifier
class WebSocketManager extends StateNotifier<bool> {
  final WebSocketClient _client;
  final Ref _ref;

  WebSocketManager(this._client, this._ref) : super(false) {
    _initialize();
  }

  void _initialize() {
    // Auto-connect when authenticated
    _ref.listen(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null && !state) {
          connect();
        } else if (user == null && state) {
          disconnect();
        }
      });
    });

    // Listen to connection status
    _client.statusStream.listen((status) {
      state = status == WebSocketStatus.connected;
    });
  }

  Future<void> connect() async {
    if (!state) {
      await _client.connect();
    }
  }

  void disconnect() {
    if (state) {
      _client.disconnect();
    }
  }

  void subscribeToDevice(String deviceId) {
    if (state) {
      _client.subscribeToDevice(deviceId);
    }
  }

  void unsubscribeFromDevice(String deviceId) {
    if (state) {
      _client.unsubscribeFromDevice(deviceId);
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

// WebSocket Manager Provider
final webSocketManagerProvider = StateNotifierProvider<WebSocketManager, bool>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return WebSocketManager(client, ref);
});

// Connection state helper provider
final isWebSocketConnectedProvider = Provider<bool>((ref) {
  return ref.watch(webSocketManagerProvider);
});

// WebSocket connection status message provider
final webSocketStatusMessageProvider = Provider<String>((ref) {
  final statusAsync = ref.watch(webSocketStatusProvider);

  return statusAsync.when(
    data: (status) {
      switch (status) {
        case WebSocketStatus.connected:
          return 'Connected';
        case WebSocketStatus.connecting:
          return 'Connecting...';
        case WebSocketStatus.disconnected:
          return 'Disconnected';
        case WebSocketStatus.error:
          return 'Connection Error';
      }
    },
    loading: () => 'Initializing...',
    error: (_, __) => 'Error',
  );
});

// Helper to subscribe to a device when viewing it
class DeviceSubscriptionNotifier extends StateNotifier<String?> {
  final WebSocketClient _client;

  DeviceSubscriptionNotifier(this._client) : super(null);

  void subscribeToDevice(String deviceId) {
    // Unsubscribe from previous device if any
    if (state != null && state != deviceId) {
      _client.unsubscribeFromDevice(state!);
    }

    // Subscribe to new device
    _client.subscribeToDevice(deviceId);
    state = deviceId;
  }

  void unsubscribe() {
    if (state != null) {
      _client.unsubscribeFromDevice(state!);
      state = null;
    }
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}

// Device subscription provider
final deviceSubscriptionProvider =
    StateNotifierProvider<DeviceSubscriptionNotifier, String?>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return DeviceSubscriptionNotifier(client);
});
