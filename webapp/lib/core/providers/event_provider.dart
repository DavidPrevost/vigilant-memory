import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/event.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import 'websocket_provider.dart';

// Events State Notifier
class EventsNotifier extends StateNotifier<AsyncValue<List<Event>>> {
  final ApiClient _apiClient;
  final Ref _ref;
  EventFilter? _currentFilter;

  EventsNotifier(this._apiClient, this._ref) : super(const AsyncValue.loading()) {
    fetchEvents();
    _listenToWebSocketUpdates();
  }

  // Listen to WebSocket new event updates
  void _listenToWebSocketUpdates() {
    _ref.listen(eventStreamProvider, (previous, next) {
      next.whenData((eventData) {
        addNewEvent(Event.fromJson(eventData));
      });
    });
  }

  // Fetch events with optional filter
  Future<void> fetchEvents([EventFilter? filter]) async {
    _currentFilter = filter;
    state = const AsyncValue.loading();

    try {
      final queryParams = filter?.toQueryParameters() ?? {};
      final response = await _apiClient.get(
        ApiEndpoints.events,
        queryParameters: queryParams,
      );

      final events = (response.data as List)
          .map((json) => Event.fromJson(json))
          .toList();

      state = AsyncValue.data(events);
    } catch (e, stack) {
      state = AsyncValue.error(
        ApiException.fromDioException(e as DioException),
        stack,
      );
    }
  }

  // Refresh events (using current filter)
  Future<void> refresh() async {
    await fetchEvents(_currentFilter);
  }

  // Add new event from WebSocket
  void addNewEvent(Event newEvent) {
    state.whenData((events) {
      // Add to beginning of list
      final newEvents = [newEvent, ...events];
      state = AsyncValue.data(newEvents);
    });
  }

  // Mark event as read
  Future<bool> markEventAsRead(String eventId) async {
    try {
      await _apiClient.post(ApiEndpoints.eventMarkRead(eventId));

      // Update in state
      state.whenData((events) {
        final index = events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          final newEvents = [...events];
          newEvents[index] = events[index].copyWith(isRead: true);
          state = AsyncValue.data(newEvents);
        }
      });

      return true;
    } catch (e) {
      print('Error marking event as read: $e');
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      await _apiClient.delete(ApiEndpoints.event(eventId));

      // Remove from state
      state.whenData((events) {
        final newEvents = events.where((e) => e.id != eventId).toList();
        state = AsyncValue.data(newEvents);
      });

      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // Load more events (pagination)
  Future<void> loadMore() async {
    state.whenData((currentEvents) async {
      try {
        final filter = _currentFilter?.copyWith(
          offset: currentEvents.length,
        ) ?? EventFilter(offset: currentEvents.length);

        final queryParams = filter.toQueryParameters();
        final response = await _apiClient.get(
          ApiEndpoints.events,
          queryParameters: queryParams,
        );

        final newEvents = (response.data as List)
            .map((json) => Event.fromJson(json))
            .toList();

        // Append new events to existing list
        final allEvents = [...currentEvents, ...newEvents];
        state = AsyncValue.data(allEvents);
      } catch (e) {
        print('Error loading more events: $e');
      }
    });
  }
}

// Events Provider
final eventsProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<Event>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return EventsNotifier(apiClient, ref);
});

// Filtered events provider (by device)
final deviceEventsProvider = FutureProvider.family<List<Event>, String>((ref, deviceId) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.get(ApiEndpoints.eventsByDevice(deviceId));
    return (response.data as List).map((json) => Event.fromJson(json)).toList();
  } catch (e) {
    print('Error fetching device events: $e');
    return [];
  }
});

// Unread events count provider
final unreadEventsCountProvider = Provider<int>((ref) {
  final eventsState = ref.watch(eventsProvider);

  return eventsState.when(
    data: (events) => events.where((e) => !e.isRead).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Critical events count provider
final criticalEventsCountProvider = Provider<int>((ref) {
  final eventsState = ref.watch(eventsProvider);

  return eventsState.when(
    data: (events) => events.where((e) => e.severity == EventSeverity.critical).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

// Events by severity provider
final eventsBySeverityProvider = Provider<Map<String, int>>((ref) {
  final eventsState = ref.watch(eventsProvider);

  return eventsState.when(
    data: (events) {
      final counts = <String, int>{};
      for (final severity in EventSeverity.all) {
        counts[severity] = events.where((e) => e.severity == severity).length;
      }
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Events by type provider
final eventsByTypeProvider = Provider<Map<String, int>>((ref) {
  final eventsState = ref.watch(eventsProvider);

  return eventsState.when(
    data: (events) {
      final counts = <String, int>{};
      for (final event in events) {
        counts[event.eventType] = (counts[event.eventType] ?? 0) + 1;
      }
      return counts;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});
