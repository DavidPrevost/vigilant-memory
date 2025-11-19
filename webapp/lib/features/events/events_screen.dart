import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/theme.dart';
import '../../core/models/event.dart';
import '../../core/providers/event_provider.dart';

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsState = ref.watch(eventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter dialog
            },
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(eventsProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: eventsState.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No events yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(eventsProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                final severityColor = AppTheme.getSeverityColor(event.severity);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.event,
                        color: severityColor,
                      ),
                    ),
                    title: Text(EventTypes.getDisplayName(event.eventType)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (event.deviceName != null) Text(event.deviceName!),
                        Text(timeago.format(event.occurredAt)),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(EventSeverity.getDisplayName(event.severity)),
                      backgroundColor: severityColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: severityColor, fontSize: 12),
                    ),
                  ),
                );
              },
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
              const Text('Error loading events'),
              TextButton(
                onPressed: () => ref.read(eventsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
