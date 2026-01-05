import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/portfolio_overview_data.dart';
import '../base/chart_colors.dart';

/// Pie chart for sector allocation
class SectorPieChart extends StatelessWidget {
  const SectorPieChart({
    required this.allocations,
    super.key,
    this.onSectionTapped,
  });

  final List<AllocationItem> allocations;
  final ValueChanged<String>? onSectionTapped;

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return const Center(child: Text('No allocation data available'));
    }

    return PieChart(
      PieChartData(
        sections: _buildSections(),
        centerSpaceRadius: 0,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (event is FlTapUpEvent && pieTouchResponse != null) {
              final touchedIndex = pieTouchResponse.touchedSection?.touchedSectionIndex;
              if (touchedIndex != null && touchedIndex < allocations.length) {
                onSectionTapped?.call(allocations[touchedIndex].label);
              }
            }
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return allocations.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final color = ChartColors.getColorForIndex(index);

      return PieChartSectionData(
        value: item.value,
        title: '${item.percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 100,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
