import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../core/providers/video_provider.dart';
import '../../core/providers/websocket_provider.dart';
import 'widgets/stats_card.dart';
import 'widgets/device_card.dart';
import 'widgets/recent_events.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure WebSocket is connected
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(webSocketManagerProvider.notifier).connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final devicesState = ref.watch(devicesProvider);
    final onlineDevicesCount = ref.watch(onlineDevicesCountProvider);
    final offlineDevicesCount = ref.watch(offlineDevicesCountProvider);
    final unreadEventsCount = ref.watch(unreadEventsCountProvider);
    final criticalEventsCount = ref.watch(criticalEventsCountProvider);
    final videoStats = ref.watch(videoStatsProvider);
    final isWebSocketConnected = ref.watch(isWebSocketConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // WebSocket status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isWebSocketConnected
                        ? AppTheme.onlineColor
                        : AppTheme.offlineColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isWebSocketConnected ? 'Live' : 'Offline',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Profile button
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go('/profile'),
            tooltip: 'Profile',
          ),

          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.read(devicesProvider.notifier).fetchDevices(),
            ref.read(eventsProvider.notifier).fetchEvents(),
            ref.read(videosProvider.notifier).fetchVideos(),
          ]);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              currentUser.when(
                data: (user) => user != null
                    ? Text(
                        'Welcome back, ${user.displayName ?? 'User'}!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Statistics grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200
                      ? 4
                      : constraints.maxWidth > 800
                          ? 3
                          : constraints.maxWidth > 600
                              ? 2
                              : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.5,
                    children: [
                      StatsCard(
                        title: 'Online Devices',
                        value: onlineDevicesCount.toString(),
                        icon: Icons.devices,
                        color: AppTheme.onlineColor,
                        onTap: () => context.go('/devices'),
                      ),
                      StatsCard(
                        title: 'Offline Devices',
                        value: offlineDevicesCount.toString(),
                        icon: Icons.devices_other,
                        color: AppTheme.offlineColor,
                        onTap: () => context.go('/devices'),
                      ),
                      StatsCard(
                        title: 'Unread Events',
                        value: unreadEventsCount.toString(),
                        icon: Icons.notifications,
                        color: AppTheme.warningColor,
                        onTap: () => context.go('/events'),
                      ),
                      if (criticalEventsCount > 0)
                        StatsCard(
                          title: 'Critical Alerts',
                          value: criticalEventsCount.toString(),
                          icon: Icons.warning_amber,
                          color: AppTheme.errorColor,
                          onTap: () => context.go('/events'),
                        ),
                      if (videoStats != null)
                        StatsCard(
                          title: 'Videos',
                          value: videoStats.totalVideos.toString(),
                          icon: Icons.video_library,
                          color: AppTheme.infoColor,
                          subtitle: videoStats.getFormattedSize(),
                          onTap: () => context.go('/videos'),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Devices section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Devices',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/devices'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              devicesState.when(
                data: (devices) {
                  if (devices.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.devices_other,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No devices registered yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.go('/devices'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Device'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 900
                          ? 3
                          : constraints.maxWidth > 600
                              ? 2
                              : 1;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          return DeviceCard(device: devices[index]);
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading devices',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref.read(devicesProvider.notifier).fetchDevices(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Recent events
              const RecentEventsWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.baby_changing_station,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  'Baby Monitor',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.devices),
            title: const Text('Devices'),
            onTap: () {
              Navigator.pop(context);
              context.go('/devices');
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Events'),
            onTap: () {
              Navigator.pop(context);
              context.go('/events');
            },
          ),
          ListTile(
            leading: const Icon(Icons.sensors),
            title: const Text('Sensors'),
            onTap: () {
              Navigator.pop(context);
              context.go('/sensors');
            },
          ),
          ListTile(
            leading: const Icon(Icons.video_library),
            title: const Text('Videos'),
            onTap: () {
              Navigator.pop(context);
              context.go('/videos');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              context.go('/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              _handleLogout();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    }
  }
}
