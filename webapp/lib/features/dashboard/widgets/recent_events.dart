import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../config/theme.dart';
import '../../../core/models/event.dart';
import '../../../core/providers/event_provider.dart';

class RecentEventsWidget extends ConsumerWidget {
  const RecentEventsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState = ref.watch(eventsProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Events',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.go('/events'),
                  child: const Text('View All'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Events list
          eventsState.when(
            data: (events) {
              if (events.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No events yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final recentEvents = events.take(5).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentEvents.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final event = recentEvents[index];
                  return _EventListTile(event: event);
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Padding(
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
                      'Error loading events',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventListTile extends StatelessWidget {
  final Event event;

  const _EventListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(event.severity);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: severityColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getEventIcon(event.eventType),
          color: severityColor,
          size: 20,
        ),
      ),
      title: Text(
        EventTypes.getDisplayName(event.eventType),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.deviceName != null) ...[
            const SizedBox(height: 4),
            Text(event.deviceName!),
          ],
          const SizedBox(height: 4),
          Text(timeago.format(event.occurredAt)),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: severityColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          EventSeverity.getDisplayName(event.severity),
          style: TextStyle(
            color: severityColor,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: () {
        // Could show event details dialog here
      },
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case EventTypes.motionDetected:
        return Icons.directions_walk;
      case EventTypes.soundDetected:
        return Icons.volume_up;
      case EventTypes.cryDetected:
        return Icons.child_care;
      case EventTypes.temperatureAlert:
        return Icons.thermostat;
      case EventTypes.humidityAlert:
        return Icons.water_drop;
      case EventTypes.deviceOnline:
        return Icons.power;
      case EventTypes.deviceOffline:
        return Icons.power_off;
      case EventTypes.lowBattery:
        return Icons.battery_alert;
      case EventTypes.systemAlert:
        return Icons.warning;
      case EventTypes.recordingStarted:
        return Icons.videocam;
      case EventTypes.recordingStopped:
        return Icons.stop_circle;
      case EventTypes.snapshotCaptured:
        return Icons.camera_alt;
      default:
        return Icons.info;
    }
  }
}
