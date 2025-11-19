import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/device_provider.dart';
import '../dashboard/widgets/device_card.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesState = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(devicesProvider.notifier).fetchDevices(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: devicesState.when(
        data: (devices) {
          if (devices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.devices_other, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No devices registered', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Show device registration instructions
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Device registration coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Device'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(devicesProvider.notifier).fetchDevices(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 400,
                childAspectRatio: 1.3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                return DeviceCard(device: devices[index]);
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
              const Text('Error loading devices'),
              TextButton(
                onPressed: () => ref.read(devicesProvider.notifier).fetchDevices(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
