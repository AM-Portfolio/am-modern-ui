import 'package:am_design_system/am_design_system.dart';
import 'package:am_library/am_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/diagnostic_provider.dart';
import '../widgets/sdk_health_card.dart';

class DiagnosticDashboardPage extends ConsumerWidget {
  const DiagnosticDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(sdkHealthMetricsProvider);
    final historyAsync = ref.watch(telemetryHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('AM Technical Lab'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => ServiceRegistry.reset(),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar: Health Metrics
          Container(
            width: 350,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white10.withOpacity(0.05))),
              color: AppColors.secondary.withOpacity(0.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SDK Health',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Switch(
                        value: ref.watch(mockDataEnabledProvider),
                        onChanged: (val) => ref.read(mockDataEnabledProvider.notifier).state = val,
                        activeColor: Colors.greenAccent,
                      ),
                    ],
                  ),
                ),
                if (ref.watch(mockDataEnabledProvider))
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'MOCK DATA ENABLED',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    children: metrics.entries.map((e) => SdkHealthCard(metric: e.value)).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Area: Live Event Log
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Live Traffic Log',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${ref.watch(telemetryLogProvider).length} events recorded',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: ref.watch(telemetryLogProvider).length,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemBuilder: (context, index) {
                      final event = ref.watch(telemetryLogProvider)[index];
                      return _TelemetryListTile(event: event);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TelemetryListTile extends StatelessWidget {
  final TelemetryEvent event;

  const _TelemetryListTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final isError = event.type == TelemetryType.apiError;
    final color = isError ? Colors.redAccent : Colors.greenAccent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      event.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (event.metadata != null && event.metadata!['full_url'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.metadata!['full_url'],
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${event.statusCode ?? ""}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (event.duration != null)
                Text(
                  '${event.duration!.inMilliseconds}ms',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
