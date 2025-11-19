import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../core/providers/device_provider.dart';

class DeviceDetailsScreen extends ConsumerWidget {
  final String deviceId;

  const DeviceDetailsScreen({
    super.key,
    required this.deviceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceProvider(deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Delete Device',
          ),
        ],
      ),
      body: deviceAsync.when(
        data: (device) {
          if (device == null) {
            return const Center(child: Text('Device not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Device info card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: device.onlineStatus
                                    ? AppTheme.onlineColor
                                    : AppTheme.offlineColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                device.deviceName,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Status', device.onlineStatus ? 'Online' : 'Offline'),
                        _buildInfoRow('Device ID', device.id),
                        if (device.batteryLevel != null)
                          _buildInfoRow('Battery', '${device.batteryLevel}%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quick actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.videocam),
                        title: const Text('View Live Stream'),
                        enabled: device.onlineStatus,
                        onTap: () => context.go('/live/$deviceId'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('View Events'),
                        onTap: () => context.go('/events'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.video_library),
                        title: const Text('View Videos'),
                        onTap: () => context.go('/videos'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Settings (placeholder)
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Device settings will appear here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error loading device'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: const Text('Are you sure you want to delete this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(devicesProvider.notifier).deleteDevice(deviceId);
      if (context.mounted) {
        context.go('/devices');
      }
    }
  }
}
