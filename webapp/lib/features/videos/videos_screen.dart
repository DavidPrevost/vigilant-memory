import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../core/models/video.dart';
import '../../core/providers/video_provider.dart';

class VideosScreen extends ConsumerWidget {
  const VideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosState = ref.watch(videosProvider);
    final videoStats = ref.watch(videoStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        actions: [
          if (videoStats != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  videoStats.getFormattedSize(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(videosProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: videosState.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No videos yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(videosProvider.notifier).refresh(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 300,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return _VideoCard(video: video);
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
              const Text('Error loading videos'),
              TextButton(
                onPressed: () => ref.read(videosProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Video video;

  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final sizeInMB = (video.fileSizeBytes / 1024 / 1024).toStringAsFixed(1);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/videos/${video.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black87,
                child: video.thumbnailUrl != null
                    ? Image.network(
                        video.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => const Icon(
                          Icons.video_library,
                          size: 48,
                          color: Colors.white54,
                        ),
                      )
                    : const Icon(
                        Icons.video_library,
                        size: 48,
                        color: Colors.white54,
                      ),
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    RecordingTypes.getDisplayName(video.recordingType),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (video.deviceName != null)
                    Text(
                      video.deviceName!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        timeago.format(video.recordedAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '$sizeInMB MB',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
