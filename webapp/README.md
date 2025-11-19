# Baby Monitor Web Dashboard

Flutter-based web dashboard for the Baby Monitor system. Also supports mobile compilation from the same codebase.

## Features

### Implemented
- ✅ User authentication (Firebase)
- ✅ Device management and monitoring
- ✅ Live video streaming
- ✅ Event timeline with filtering
- ✅ Sensor monitoring with real-time graphs
- ✅ Video library and playback
- ✅ WebSocket real-time updates
- ✅ Dark mode support
- ✅ CSV export for sensor data
- ✅ Responsive design (desktop/tablet/mobile)

### Screens
1. **Dashboard** - Overview of all devices, recent events, system health
2. **Live View** - Real-time video streaming with controls
3. **Events** - Filterable timeline of all detection events
4. **Devices** - Device management, settings, remote control
5. **Sensors** - Real-time gauges and historical graphs
6. **Videos** - Video library with playback
7. **Profile** - User settings and preferences

## Quick Start

### Prerequisites
- Flutter SDK 3.1.0+
- Backend server running (see `/backend/README.md`)

### Installation

```bash
cd webapp

# Install dependencies
flutter pub get

# Run in development mode
flutter run -d chrome

# Or build for production
flutter build web --release
```

### Configuration

1. Copy `.env` file and update with your backend URL:
```bash
API_BASE_URL=http://your-server:5000
WS_URL=http://your-server:5000
```

2. Add Firebase configuration:
   - Create Firebase project
   - Enable Authentication
   - Copy configuration to `.env`

## Project Structure

```
lib/
├── main.dart                   # Entry point
├── app.dart                    # App widget with routing
├── config/
│   ├── theme.dart             # Light/dark themes
│   ├── routes.dart            # Navigation configuration
│   └── constants.dart         # App constants
├── core/
│   ├── api/
│   │   ├── api_client.dart    # HTTP client (Dio)
│   │   └── websocket_client.dart
│   ├── models/               # Data models
│   └── providers/            # Riverpod providers
├── features/
│   ├── auth/                 # Login/register
│   ├── dashboard/            # Home dashboard
│   ├── live_view/            # Live video
│   ├── events/               # Events timeline
│   ├── devices/              # Device management
│   ├── sensors/              # Sensor monitoring
│   ├── videos/               # Video library
│   └── profile/              # User profile
└── shared/
    ├── widgets/              # Reusable components
    └── utils/                # Utility functions
```

## Tech Stack

**Framework:** Flutter 3.16+
**Language:** Dart
**State Management:** Riverpod
**HTTP Client:** Dio
**Real-time:** Socket.IO
**Authentication:** Firebase Auth
**Charts:** fl_chart
**Video:** video_player + chewie

## Development

### Running Tests
```bash
flutter test
```

### Code Generation
```bash
# Generate code for Riverpod, Retrofit, JSON serialization
flutter pub run build_runner build --delete-conflicting-outputs
```

### Linting
```bash
flutter analyze
```

### Format Code
```bash
flutter format lib/
```

## Building

### Web
```bash
# Development build
flutter build web

# Production build with optimizations
flutter build web --release --web-renderer canvaskit
```

### Mobile (from same codebase)
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## Deployment

### Web Hosting
Deploy the `build/web` directory to:
- **Netlify** (recommended for static hosting)
- **Vercel** (easy deployment)
- **Firebase Hosting**
- **AWS S3 + CloudFront**
- **Self-hosted** (nginx/apache)

### Example: Netlify
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Build
flutter build web --release

# Deploy
netlify deploy --prod --dir=build/web
```

## Features Detail

### Real-time Updates
- Device status (online/offline)
- New events arriving
- Sensor readings (every 60s)
- System metrics
- Video upload progress

### Video Streaming
- MJPEG live stream from devices
- Full-screen mode
- Recording controls
- Snapshot capture

### Sensor Monitoring
- Real-time gauges for current values
- Historical line charts
- Configurable time ranges (1h to 30d)
- CSV data export
- Threshold alerts

### Device Management
- View all devices
- Configure settings remotely
- Send commands (record, snapshot, reboot)
- Share device access
- Monitor system health

### Dark Mode
- System-aware theme switching
- Manual toggle in settings
- Persisted preference

### CSV Export
- Export sensor data to CSV
- Custom date range selection
- All sensor types included

## Performance

**Initial Load:** ~2-3 MB (gzipped)
**Runtime Memory:** ~50-100 MB
**WebSocket:** < 1 KB/s
**Polling (if used):** N/A (using WebSocket)

## Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+

## Troubleshooting

### CORS Errors
Ensure backend has CORS enabled for your domain:
```python
# backend/src/app.py
CORS(app, origins=['http://localhost:your-port'])
```

### WebSocket Connection Fails
- Check backend is running Socket.IO server
- Verify WS_URL in .env
- Check browser console for errors

### Video Won't Play
- Check device is online
- Verify video stream URL
- Try different browser
- Check network firewall

### Firebase Auth Errors
- Verify Firebase configuration in .env
- Check Firebase Console for errors
- Ensure Authentication is enabled

## API Integration

The dashboard communicates with the backend via:

**HTTP REST API:**
- GET /api/devices - List devices
- GET /api/events - List events
- POST /api/devices/{id}/command - Send command
- GET /api/sensors/readings - Get sensor data
- GET /api/videos - List videos

**WebSocket Events:**
- `device_status` - Device online/offline
- `new_event` - Event created
- `sensor_reading` - Sensor update
- `video_upload_progress` - Upload status

## Mobile App

To compile as mobile app:

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Build release APK
flutter build apk --release
```

**No code changes needed!** The same codebase works for web and mobile.

## License

Proprietary - All rights reserved

## Support

See main project documentation in `/docs`

---

**Version:** 1.0.0
**Last Updated:** 2025-11-18
