import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/live_view/live_view_screen.dart';
import '../features/events/events_screen.dart';
import '../features/devices/devices_screen.dart';
import '../features/devices/device_details_screen.dart';
import '../features/sensors/sensors_screen.dart';
import '../features/videos/videos_screen.dart';
import '../features/videos/video_player_screen.dart';
import '../features/profile/profile_screen.dart';

class AppRouter {
  static GoRouter router(User? authState) {
    return GoRouter(
      initialLocation: authState != null ? '/dashboard' : '/login',
      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authState != null;
        final isAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/register');

        // If not authenticated and trying to access protected route, redirect to login
        if (!isAuthenticated && !isAuthRoute) {
          return '/login';
        }

        // If authenticated and trying to access auth route, redirect to dashboard
        if (isAuthenticated && isAuthRoute) {
          return '/dashboard';
        }

        return null; // No redirect needed
      },
      routes: [
        // Auth Routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Dashboard
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),

        // Live View
        GoRoute(
          path: '/live/:deviceId',
          name: 'live-view',
          builder: (context, state) {
            final deviceId = state.pathParameters['deviceId']!;
            return LiveViewScreen(deviceId: deviceId);
          },
        ),

        // Events
        GoRoute(
          path: '/events',
          name: 'events',
          builder: (context, state) => const EventsScreen(),
        ),

        // Devices
        GoRoute(
          path: '/devices',
          name: 'devices',
          builder: (context, state) => const DevicesScreen(),
          routes: [
            GoRoute(
              path: ':deviceId',
              name: 'device-details',
              builder: (context, state) {
                final deviceId = state.pathParameters['deviceId']!;
                return DeviceDetailsScreen(deviceId: deviceId);
              },
            ),
          ],
        ),

        // Sensors
        GoRoute(
          path: '/sensors',
          name: 'sensors',
          builder: (context, state) => const SensorsScreen(),
        ),

        // Videos
        GoRoute(
          path: '/videos',
          name: 'videos',
          builder: (context, state) => const VideosScreen(),
          routes: [
            GoRoute(
              path: ':videoId',
              name: 'video-player',
              builder: (context, state) {
                final videoId = state.pathParameters['videoId']!;
                return VideoPlayerScreen(videoId: videoId);
              },
            ),
          ],
        ),

        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],

      // Error handling
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                '404 - Page Not Found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error?.toString() ?? 'The requested page does not exist.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.home),
                label: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Navigation helper methods
  static void goToDashboard(BuildContext context) {
    context.go('/dashboard');
  }

  static void goToLiveView(BuildContext context, String deviceId) {
    context.go('/live/$deviceId');
  }

  static void goToEvents(BuildContext context) {
    context.go('/events');
  }

  static void goToDevices(BuildContext context) {
    context.go('/devices');
  }

  static void goToDeviceDetails(BuildContext context, String deviceId) {
    context.go('/devices/$deviceId');
  }

  static void goToSensors(BuildContext context) {
    context.go('/sensors');
  }

  static void goToVideos(BuildContext context) {
    context.go('/videos');
  }

  static void goToVideoPlayer(BuildContext context, String videoId) {
    context.go('/videos/$videoId');
  }

  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToRegister(BuildContext context) {
    context.go('/register');
  }
}
