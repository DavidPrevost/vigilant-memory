import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../core/models/sensor_reading.dart';
import '../../core/providers/sensor_provider.dart';

class SensorsScreen extends ConsumerWidget {
  const SensorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorStats = ref.watch(currentSensorStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(sensorReadingsProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: sensorStats.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sensors_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No sensor data available', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(sensorReadingsProvider.notifier).refresh(),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: sensorStats.length,
                itemBuilder: (context, index) {
                  final sensorType = sensorStats.keys.elementAt(index);
                  final stats = sensorStats[sensorType]!;
                  return _SensorCard(stats: stats);
                },
              ),
            ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final SensorStats stats;

  const _SensorCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final unit = SensorTypes.getUnit(stats.sensorType);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header
            Row(
              children: [
                Text(
                  SensorTypes.getIcon(stats.sensorType),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    SensorTypes.getDisplayName(stats.sensorType),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),

            // Current value
            Text(
              '${stats.currentValue.toStringAsFixed(1)} $unit',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),

            // Min/Max/Avg
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(context, 'Min', stats.minValue, unit),
                _buildStatItem(context, 'Max', stats.maxValue, unit),
                _buildStatItem(context, 'Avg', stats.avgValue, unit),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, double value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        Text(
          '${value.toStringAsFixed(1)} $unit',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
