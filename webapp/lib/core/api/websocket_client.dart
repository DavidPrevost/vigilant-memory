import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants.dart';

enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class WebSocketClient {
  late io.Socket _socket;
  final FirebaseAuth _firebaseAuth;

  final _statusController = StreamController<WebSocketStatus>.broadcast();
  final _deviceStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();
  final _sensorReadingController = StreamController<Map<String, dynamic>>.broadcast();
  final _videoUploadController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  Stream<Map<String, dynamic>> get deviceStatusStream => _deviceStatusController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventController.stream;
  Stream<Map<String, dynamic>> get sensorReadingStream => _sensorReadingController.stream;
  Stream<Map<String, dynamic>> get videoUploadStream => _videoUploadController.stream;

  WebSocketStatus _status = WebSocketStatus.disconnected;
  WebSocketStatus get status => _status;

  WebSocketClient(this._firebaseAuth) {
    _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    // Get Firebase auth token
    String? token;
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        token = await user.getIdToken();
      }
    } catch (e) {
      print('Error getting auth token for WebSocket: $e');
    }

    // Configure Socket.IO client
    _socket = io.io(
      AppConstants.wsUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(token != null ? {'token': token} : {})
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setReconnectionAttempts(5)
          .build(),
    );

    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    // Connection events
    _socket.onConnect((_) {
      print('🟢 WebSocket connected');
      _updateStatus(WebSocketStatus.connected);
    });

    _socket.onConnecting((_) {
      print('🔵 WebSocket connecting...');
      _updateStatus(WebSocketStatus.connecting);
    });

    _socket.onDisconnect((_) {
      print('🔴 WebSocket disconnected');
      _updateStatus(WebSocketStatus.disconnected);
    });

    _socket.onConnectError((error) {
      print('🔴 WebSocket connection error: $error');
      _updateStatus(WebSocketStatus.error);
    });

    _socket.onError((error) {
      print('🔴 WebSocket error: $error');
      _updateStatus(WebSocketStatus.error);
    });

    _socket.onReconnectAttempt((attempt) {
      print('🔄 WebSocket reconnect attempt #$attempt');
    });

    _socket.onReconnect((attempt) {
      print('🟢 WebSocket reconnected after $attempt attempts');
    });

    // Data events
    _socket.on('device_status', (data) {
      print('📡 Device status update: $data');
      if (data is Map<String, dynamic>) {
        _deviceStatusController.add(data);
      }
    });

    _socket.on('new_event', (data) {
      print('📡 New event: $data');
      if (data is Map<String, dynamic>) {
        _eventController.add(data);
      }
    });

    _socket.on('sensor_reading', (data) {
      print('📡 Sensor reading: $data');
      if (data is Map<String, dynamic>) {
        _sensorReadingController.add(data);
      }
    });

    _socket.on('video_upload_progress', (data) {
      print('📡 Video upload progress: $data');
      if (data is Map<String, dynamic>) {
        _videoUploadController.add(data);
      }
    });
  }

  void _updateStatus(WebSocketStatus status) {
    _status = status;
    _statusController.add(status);
  }

  // Connect to WebSocket server
  Future<void> connect() async {
    if (_status == WebSocketStatus.connected || _status == WebSocketStatus.connecting) {
      print('⚠️ WebSocket already connected or connecting');
      return;
    }

    // Refresh auth token before connecting
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final token = await user.getIdToken(true);
        if (token != null) {
          _socket.auth = {'token': token};
        }
      }
    } catch (e) {
      print('Error refreshing auth token: $e');
    }

    _updateStatus(WebSocketStatus.connecting);
    _socket.connect();
  }

  // Disconnect from WebSocket server
  void disconnect() {
    if (_status == WebSocketStatus.disconnected) {
      print('⚠️ WebSocket already disconnected');
      return;
    }

    _socket.disconnect();
    _updateStatus(WebSocketStatus.disconnected);
  }

  // Subscribe to device updates
  void subscribeToDevice(String deviceId) {
    print('📡 Subscribing to device: $deviceId');
    _socket.emit('subscribe_device', {'device_id': deviceId});
  }

  // Unsubscribe from device updates
  void unsubscribeFromDevice(String deviceId) {
    print('📡 Unsubscribing from device: $deviceId');
    _socket.emit('unsubscribe_device', {'device_id': deviceId});
  }

  // Send a custom event
  void emit(String event, dynamic data) {
    if (_status == WebSocketStatus.connected) {
      _socket.emit(event, data);
    } else {
      print('⚠️ Cannot emit event - WebSocket not connected');
    }
  }

  // Listen to a custom event
  void on(String event, Function(dynamic) handler) {
    _socket.on(event, handler);
  }

  // Remove listener for a custom event
  void off(String event) {
    _socket.off(event);
  }

  // Cleanup resources
  void dispose() {
    _socket.dispose();
    _statusController.close();
    _deviceStatusController.close();
    _eventController.close();
    _sensorReadingController.close();
    _videoUploadController.close();
  }
}

// WebSocket Client Provider
final webSocketClientProvider = Provider<WebSocketClient>((ref) {
  final client = WebSocketClient(FirebaseAuth.instance);

  // Auto-dispose when provider is disposed
  ref.onDispose(() {
    client.dispose();
  });

  return client;
});

// WebSocket Status Provider
final webSocketStatusProvider = StreamProvider<WebSocketStatus>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.statusStream;
});

// Device Status Stream Provider
final deviceStatusStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.deviceStatusStream;
});

// Event Stream Provider
final eventStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.eventStream;
});

// Sensor Reading Stream Provider
final sensorReadingStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.sensorReadingStream;
});

// Video Upload Stream Provider
final videoUploadStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final client = ref.watch(webSocketClientProvider);
  return client.videoUploadStream;
});
