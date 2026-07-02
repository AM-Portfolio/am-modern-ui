import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class DashboardChartWidget extends StatelessWidget {
  final PerformanceResponse performance;

  const DashboardChartWidget({super.key, required this.performance});

  @override
  Widget build(BuildContext context) {
    if (performance.chartData.isEmpty) {
      return const CommonPerformanceChart(
        title: 'Performance',
        primaryData: [],
      );
    }

    final double firstValue = performance.chartData.first.value;

    final primaryPoints = performance.chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      return CommonChartDataPoint(
        x: index.toDouble(),
        y: point.value,
        xLabel: point.date,
        yLabel: point.value.toStringAsFixed(2),
      );
    }).toList();

    final secondaryPoints = performance.chartData.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final double percentChange = firstValue != 0.0
          ? ((point.value - firstValue) / firstValue) * 100
          : 0.0;
      return CommonChartDataPoint(
        x: index.toDouble(),
        y: percentChange,
        xLabel: point.date,
        yLabel:
            '${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
      );
    }).toList();

    return CommonPerformanceChart(
      title: 'Performance',
      primaryData: primaryPoints,
      secondaryData: secondaryPoints,
      primaryToggleLabel: '\$',
      secondaryToggleLabel: '%',
    );
  }
}
