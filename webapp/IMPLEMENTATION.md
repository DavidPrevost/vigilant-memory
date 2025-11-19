# Implementation Guide

## What's Been Created

### Project Structure ✅
- Complete directory structure
- pubspec.yaml with all dependencies
- Web configuration (index.html, manifest.json)
- Environment configuration (.env)
- Main entry points (main.dart, app.dart)
- Comprehensive README

## What Needs to Be Built

### 1. Configuration (lib/config/)
- **theme.dart** - Light/dark themes with color schemes
- **routes.dart** - Go Router configuration with auth guards
- **constants.dart** - API URLs, app constants

### 2. Core Infrastructure (lib/core/)

**API Layer (core/api/):**
- **api_client.dart** - Dio HTTP client with interceptors
- **websocket_client.dart** - Socket.IO real-time connection
- **api_endpoints.dart** - Endpoint constants

**Models (core/models/):**
- **device.dart** - Device data model
- **event.dart** - Event data model
- **sensor_reading.dart** - Sensor data model
- **video.dart** - Video data model
- **user.dart** - User data model

**Providers (core/providers/):**
- **auth_provider.dart** - Firebase auth state
- **theme_provider.dart** - Theme mode management
- **device_provider.dart** - Device state management
- **event_provider.dart** - Events state
- **sensor_provider.dart** - Sensor data state
- **video_provider.dart** - Video library state
- **websocket_provider.dart** - WebSocket connection

### 3. Feature Screens (lib/features/)

**Auth (features/auth/):**
- login_screen.dart - Email/password login
- register_screen.dart - User registration

**Dashboard (features/dashboard/):**
- dashboard_screen.dart - Home overview
- widgets/device_card.dart - Device summary card
- widgets/recent_events.dart - Event list widget
- widgets/stats_card.dart - Statistics display

**Live View (features/live_view/):**
- live_view_screen.dart - Video streaming
- widgets/video_player.dart - MJPEG player
- widgets/controls_panel.dart - Playback controls
- widgets/sensor_panel.dart - Real-time sensors

**Events (features/events/):**
- events_screen.dart - Event timeline
- event_details_dialog.dart - Event details modal
- widgets/event_card.dart - Event list item
- widgets/event_filters.dart - Filter controls

**Devices (features/devices/):**
- devices_screen.dart - Device list
- device_details_screen.dart - Device details/settings
- widgets/device_list_item.dart
- widgets/device_settings_form.dart
- widgets/sharing_panel.dart

**Sensors (features/sensors/):**
- sensors_screen.dart - Sensor monitoring
- widgets/sensor_gauge.dart - Real-time gauge
- widgets/sensor_chart.dart - Historical chart
- widgets/export_dialog.dart - CSV export

**Videos (features/videos/):**
- videos_screen.dart - Video library
- video_player_screen.dart - Full video player
- widgets/video_grid.dart
- widgets/video_filters.dart

**Profile (features/profile/):**
- profile_screen.dart - User profile/settings
- widgets/profile_form.dart
- widgets/preferences_panel.dart
- widgets/subscription_panel.dart

### 4. Shared Components (lib/shared/)

**Widgets (shared/widgets/):**
- app_bar.dart - Custom app bar
- sidebar.dart - Navigation sidebar
- loading_indicator.dart
- error_widget.dart
- empty_state.dart
- confirmation_dialog.dart
- notification_badge.dart

**Utils (shared/utils/):**
- formatters.dart - Date/time/number formatting
- validators.dart - Form validation
- constants.dart - Shared constants
- extensions.dart - Dart extensions

## Build Order Recommendation

1. **Phase 1: Foundation**
   - Config files (theme, routes, constants)
   - API client + WebSocket
   - Core models
   - Auth provider

2. **Phase 2: Authentication**
   - Login screen
   - Register screen
   - Auth guards

3. **Phase 3: Core Screens**
   - Dashboard (most important for testing)
   - Live View (hardware testing)
   - Devices (device management)

4. **Phase 4: Data Screens**
   - Events timeline
   - Sensors monitoring
   - Videos library

5. **Phase 5: User Features**
   - Profile/settings
   - Dark mode
   - CSV export

6. **Phase 6: Polish**
   - Shared widgets
   - Error handling
   - Loading states
   - Responsive design

## Estimated Lines of Code

- Configuration: ~500 lines
- Core Infrastructure: ~1,500 lines
- Auth Screens: ~400 lines
- Dashboard: ~600 lines
- Live View: ~700 lines
- Events: ~600 lines
- Devices: ~800 lines
- Sensors: ~800 lines
- Videos: ~600 lines
- Profile: ~400 lines
- Shared: ~800 lines

**Total: ~7,700 lines of Dart code**

## Key Implementation Patterns

### State Management (Riverpod)
```dart
// Define provider
final devicesProvider = StateNotifierProvider<DevicesNotifier, AsyncValue<List<Device>>>((ref) {
  return DevicesNotifier(ref.read(apiClientProvider));
});

// Use in widget
final devices = ref.watch(devicesProvider);

devices.when(
  data: (data) => ListView(...),
  loading: () => LoadingIndicator(),
  error: (err, stack) => ErrorWidget(err),
);
```

### API Calls (Dio)
```dart
// In API client
Future<List<Device>> getDevices() async {
  final response = await _dio.get('/api/devices');
  return (response.data as List)
      .map((json) => Device.fromJson(json))
      .toList();
}
```

### WebSocket (Socket.IO)
```dart
// Connect and listen
socket.on('device_status', (data) {
  final device = Device.fromJson(data);
  ref.read(devicesProvider.notifier).updateDevice(device);
});
```

### Routing (Go Router)
```dart
GoRoute(
  path: '/dashboard',
  builder: (context, state) => const DashboardScreen(),
  redirect: (context, state) {
    final isAuthenticated = ref.read(authStateProvider) != null;
    return isAuthenticated ? null : '/login';
  },
),
```

## Next Steps

Would you like me to:

1. **Build everything in sequence** - Create all files systematically (will take multiple responses)
2. **Build foundation first** - Config, API, models, providers (then screens later)
3. **Build key screens** - Dashboard, Live View, Devices (most critical for testing)
4. **Provide templates** - Give you detailed templates to expand yourself

Recommendation: Build foundation + key screens first, since those are needed for hardware testing.
