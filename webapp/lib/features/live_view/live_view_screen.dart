import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../core/providers/device_provider.dart';
import '../../core/providers/websocket_provider.dart';

class LiveViewScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const LiveViewScreen({
    super.key,
    required this.deviceId,
  });

  @override
  ConsumerState<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends ConsumerState<LiveViewScreen> {
  @override
  void initState() {
    super.initState();
    // Subscribe to device updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(deviceSubscriptionProvider.notifier).subscribeToDevice(widget.deviceId);
    });
  }

  @override
  void dispose() {
    // Unsubscribe from device updates
    ref.read(deviceSubscriptionProvider.notifier).unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(deviceProvider(widget.deviceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live View'),
      ),
      body: deviceAsync.when(
        data: (device) {
          if (device == null) {
            return const Center(child: Text('Device not found'));
          }

          if (!device.onlineStatus) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Device is offline'),
                  const SizedBox(height: 8),
                  Text(
                    device.deviceName,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          final streamUrl = '${AppConstants.apiBaseUrl}/api/devices/${widget.deviceId}/stream';

          return Column(
            children: [
              // Video player area
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam,
                          size: 64,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'MJPEG Stream',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          streamUrl,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white54,
                              ),
                        ),
                        const SizedBox(height: 24),
                        // In production, use Image.network(streamUrl) for MJPEG stream
                        const Text(
                          'Video streaming will appear here when device is recording',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Controls panel
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Snapshot',
                      onPressed: () => _captureSnapshot(),
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.fiber_manual_record,
                      label: 'Record',
                      color: AppTheme.errorColor,
                      onPressed: () => _startRecording(),
                    ),
                    _buildControlButton(
                      context,
                      icon: Icons.fullscreen,
                      label: 'Fullscreen',
                      onPressed: () => _toggleFullscreen(),
                    ),
                  ],
                ),
              ),
            ],
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
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 32,
          color: color ?? AppTheme.primaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Future<void> _captureSnapshot() async {
    // TODO: Implement snapshot capture
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Capturing snapshot...')),
    );
  }

  Future<void> _startRecording() async {
    // TODO: Implement recording start/stop
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting recording...')),
    );
  }

  void _toggleFullscreen() {
    // TODO: Implement fullscreen toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fullscreen mode')),
    );
  }
}
