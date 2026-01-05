import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/portfolio_overview_data.dart';
import '../base/chart_colors.dart';

/// Bar chart for sector allocation
class SectorBarChart extends StatelessWidget {
  const SectorBarChart({
    required this.allocations,
    super.key,
    this.onBarTapped,
  });

  final List<AllocationItem> allocations;
  final ValueChanged<String>? onBarTapped;

  @override
  Widget build(BuildContext context) {
    if (allocations.isEmpty) {
      return const Center(child: Text('No allocation data available'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: allocations.map((e) => e.percentage).reduce((a, b) => a > b ? a : b) * 1.2,
        barGroups: _buildBarGroups(),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= allocations.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    allocations[index].label,
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(
                  '${value.toInt()}%',
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            if (event is FlTapUpEvent && barTouchResponse != null) {
              final touchedIndex = barTouchResponse.spot?.touchedBarGroupIndex;
              if (touchedIndex != null && touchedIndex < allocations.length) {
                onBarTapped?.call(allocations[touchedIndex].label);
              }
            }
          },
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return allocations.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final color = ChartColors.getColorForIndex(index);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.percentage,
            color: color,
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();
  }
}
