import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/portfolio_overview_data.dart';
import '../base/chart_colors.dart';

/// Donut chart for sector allocation
class SectorDonutChart extends StatefulWidget {
  const SectorDonutChart({
    required this.allocations,
    super.key,
    this.onSectionTapped,
  });

  final List<AllocationItem> allocations;
  final ValueChanged<String>? onSectionTapped;

  @override
  State<SectorDonutChart> createState() => _SectorDonutChartState();
}

class _SectorDonutChartState extends State<SectorDonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.allocations.isEmpty) {
      return const Center(child: Text('No allocation data available'));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: _buildSections(),
                centerSpaceRadius: 80,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;

                      if (event is FlTapUpEvent && _touchedIndex >= 0) {
                        widget.onSectionTapped
                            ?.call(widget.allocations[_touchedIndex].label);
                      }
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildLegend(context),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    return widget.allocations.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isTouched = index == _touchedIndex;
      final color = ChartColors.getColorForIndex(index);

      return PieChartSectionData(
        value: item.value,
        title: isTouched ? '${item.percentage.toStringAsFixed(1)}%' : '',
        color: color,
        radius: isTouched ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: isTouched ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widget.allocations.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final color = ChartColors.getColorForIndex(index);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '\$${item.value.toStringAsFixed(0)} (${item.percentage.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
