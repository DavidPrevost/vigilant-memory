import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
import '../../../core/models/device.dart';

class DeviceCard extends ConsumerWidget {
  final Device device;

  const DeviceCard({
    super.key,
    required this.device,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = device.onlineStatus;
    final statusColor = isOnline ? AppTheme.onlineColor : AppTheme.offlineColor;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/devices/${device.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Status indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Device name
                  Expanded(
                    child: Text(
                      device.deviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Battery indicator
                  if (device.batteryLevel != null) ...[
                    Icon(
                      _getBatteryIcon(device.batteryLevel!),
                      size: 20,
                      color: _getBatteryColor(device.batteryLevel!),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.batteryLevel}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Status
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: statusColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (device.lastSeenAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '• ${timeago.format(device.lastSeenAt!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Metrics (if available)
              if (device.metrics != null) ...[
                _buildMetricRow(
                  context,
                  Icons.thermostat_outlined,
                  device.metrics!.cpuTemperature != null
                      ? '${device.metrics!.cpuTemperature!.toStringAsFixed(1)}°C'
                      : 'N/A',
                  'CPU Temp',
                ),
                const SizedBox(height: 8),
                _buildMetricRow(
                  context,
                  Icons.memory_outlined,
                  device.metrics!.memoryUsage != null
                      ? '${device.metrics!.memoryUsage!.toStringAsFixed(0)}%'
                      : 'N/A',
                  'Memory',
                ),
              ],

              const SizedBox(height: 12),

              // Quick actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: isOnline ? () => _viewLive(context) : null,
                    icon: const Icon(Icons.videocam, size: 18),
                    label: const Text('Live View'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/devices/${device.id}'),
                    icon: const Icon(Icons.settings),
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  void _viewLive(BuildContext context) {
    context.go('/live/${device.id}');
  }

  IconData _getBatteryIcon(int level) {
    if (level >= 90) return Icons.battery_full;
    if (level >= 70) return Icons.battery_6_bar;
    if (level >= 50) return Icons.battery_5_bar;
    if (level >= 30) return Icons.battery_3_bar;
    if (level >= 10) return Icons.battery_1_bar;
    return Icons.battery_0_bar;
  }

  Color _getBatteryColor(int level) {
    if (level >= 50) return AppTheme.accentColor;
    if (level >= 20) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
