import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import '../providers/diagnostic_provider.dart';

class SdkHealthCard extends StatelessWidget {
  final HealthMetric metric;

  const SdkHealthCard({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final hasErrors = metric.errors > 0;
    final statusColor = hasErrors ? Colors.orangeAccent : Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                metric.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                width: 10,
                height: 10,
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
            ],
          ),
          const SizedBox(height: 16),
          _MetricRow(
            label: 'Success Rate',
            value: '${metric.successRate.toStringAsFixed(1)}%',
            color: _getRateColor(metric.successRate),
          ),
          _MetricRow(
            label: 'Avg Latency',
            value: '${metric.avgLatency.inMilliseconds}ms',
          ),
          _MetricRow(
            label: 'Requests',
            value: '${metric.requests}',
          ),
          _MetricRow(
            label: 'Errors',
            value: '${metric.errors}',
            color: metric.errors > 0 ? Colors.redAccent : Colors.white60,
          ),
        ],
      ),
    );
  }

  Color _getRateColor(double rate) {
    if (rate > 95) return Colors.greenAccent;
    if (rate > 80) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
