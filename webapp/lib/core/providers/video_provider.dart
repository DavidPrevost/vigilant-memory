import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../models/video.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../../config/constants.dart';
import 'websocket_provider.dart';

// Videos State Notifier
class VideosNotifier extends StateNotifier<AsyncValue<List<Video>>> {
  final ApiClient _apiClient;
  final Ref _ref;
  VideoFilter? _currentFilter;

  VideosNotifier(this._apiClient, this._ref) : super(const AsyncValue.loading()) {
    fetchVideos();
    _listenToWebSocketUpdates();
  }

  // Listen to WebSocket video upload progress
  void _listenToWebSocketUpdates() {
    _ref.listen(videoUploadStreamProvider, (previous, next) {
      next.whenData((uploadData) {
        final status = uploadData['status'] as String?;
        if (status == 'completed') {
          // Video upload completed, refresh the list
          refresh();
        }
      });
    });
  }

  // Fetch videos with optional filter
  Future<void> fetchVideos([VideoFilter? filter]) async {
    _currentFilter = filter;
    state = const AsyncValue.loading();

    try {
      final queryParams = filter?.toQueryParameters() ?? {};
      final response = await _apiClient.get(
        ApiEndpoints.videos,
        queryParameters: queryParams,
      );

      final videos = (response.data as List)
          .map((json) => Video.fromJson(json))
          .toList();

      state = AsyncValue.data(videos);
    } catch (e, stack) {
      state = AsyncValue.error(
        ApiException.fromDioException(e as DioException),
        stack,
      );
    }
  }

  // Refresh videos (using current filter)
  Future<void> refresh() async {
    await fetchVideos(_currentFilter);
  }

  // Get single video
  Future<Video?> getVideo(String videoId) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.video(videoId));
      return Video.fromJson(response.data);
    } catch (e) {
      print('Error fetching video: $e');
      return null;
    }
  }

  // Delete video
  Future<bool> deleteVideo(String videoId) async {
    try {
      await _apiClient.delete(ApiEndpoints.video(videoId));

      // Remove from state
      state.whenData((videos) {
        final newVideos = videos.where((v) => v.id != videoId).toList();
        state = AsyncValue.data(newVideos);
      });

      return true;
    } catch (e) {
      print('Error deleting video: $e');
      return false;
    }
  }

  // Load more videos (pagination)
  Future<void> loadMore() async {
    state.whenData((currentVideos) async {
      try {
        final filter = _currentFilter?.copyWith(
          offset: currentVideos.length,
        ) ?? VideoFilter(offset: currentVideos.length);

        final queryParams = filter.toQueryParameters();
        final response = await _apiClient.get(
          ApiEndpoints.videos,
          queryParameters: queryParams,
        );

        final newVideos = (response.data as List)
            .map((json) => Video.fromJson(json))
            .toList();

        // Append new videos to existing list
        final allVideos = [...currentVideos, ...newVideos];
        state = AsyncValue.data(allVideos);
      } catch (e) {
        print('Error loading more videos: $e');
      }
    });
  }

  // Get download URL for video
  String getDownloadUrl(String videoId) {
    return '${AppConstants.apiBaseUrl}${ApiEndpoints.videoDownload(videoId)}';
  }
}

// Videos Provider
final videosProvider = StateNotifierProvider<VideosNotifier, AsyncValue<List<Video>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return VideosNotifier(apiClient, ref);
});

// Device videos provider
final deviceVideosProvider = FutureProvider.family<List<Video>, String>((ref, deviceId) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final response = await apiClient.get(ApiEndpoints.videosByDevice(deviceId));
    return (response.data as List).map((json) => Video.fromJson(json)).toList();
  } catch (e) {
    print('Error fetching device videos: $e');
    return [];
  }
});

// Event video provider
final eventVideoProvider = FutureProvider.family<Video?, String>((ref, eventId) async {
  final videosState = ref.watch(videosProvider);

  return videosState.when(
    data: (videos) {
      try {
        return videos.firstWhere((v) => v.eventId == eventId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Video stats provider
final videoStatsProvider = Provider<VideoStats?>((ref) {
  final videosState = ref.watch(videosProvider);

  return videosState.when(
    data: (videos) {
      final continuousCount = videos.where((v) => v.recordingType == RecordingTypes.continuous).length;
      final eventTriggeredCount =
          videos.where((v) => v.recordingType == RecordingTypes.eventTriggered).length;
      final manualCount = videos.where((v) => v.recordingType == RecordingTypes.manual).length;
      final snapshotCount = videos.where((v) => v.recordingType == RecordingTypes.snapshot).length;
      final totalSizeBytes = videos.fold<int>(0, (sum, v) => sum + v.fileSizeBytes);

      return VideoStats(
        totalVideos: videos.length,
        totalSizeBytes: totalSizeBytes,
        continuousCount: continuousCount,
        eventTriggeredCount: eventTriggeredCount,
        manualCount: manualCount,
        snapshotCount: snapshotCount,
      );
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Videos by recording type provider
final videosByTypeProvider = Provider<Map<String, List<Video>>>((ref) {
  final videosState = ref.watch(videosProvider);

  return videosState.when(
    data: (videos) {
      final grouped = <String, List<Video>>{};
      for (final type in RecordingTypes.all) {
        grouped[type] = videos.where((v) => v.recordingType == type).toList();
      }
      return grouped;
    },
    loading: () => {},
    error: (_, __) => {},
  );
});

// Recent videos provider (last 10)
final recentVideosProvider = Provider<List<Video>>((ref) {
  final videosState = ref.watch(videosProvider);

  return videosState.when(
    data: (videos) => videos.take(10).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
