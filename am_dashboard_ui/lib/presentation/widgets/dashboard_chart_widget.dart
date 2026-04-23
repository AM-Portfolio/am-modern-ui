import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/shared/widgets/charts/chart_factory.dart';
import 'package:am_design_system/shared/widgets/charts/chart_types.dart';
import 'package:flutter/material.dart';

class DashboardChartWidget extends StatelessWidget {
  final PerformanceResponse performance;
  final ValueChanged<String>? onTimeFrameChanged;

  const DashboardChartWidget({
    super.key,
    required this.performance,
    this.onTimeFrameChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Performance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              _buildTimeFrameSelector(context),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: ChartFactory.line(
              data: _mapDataPoints(performance.chartData),
              config: const CommonChartConfig(
                showGrid: false,
                showTitles: true,
                showLegend: false,
                showTooltips: true,
              ),
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFrameSelector(BuildContext context) {
    if (onTimeFrameChanged == null) return const SizedBox.shrink();
    
    final timeFrames = ['1D', '1W', '1M', '3M', '1Y', 'YTD'];
    return ToggleButtons(
      isSelected: timeFrames.map((tf) => tf == performance.timeFrame).toList(),
      onPressed: (index) => onTimeFrameChanged!(timeFrames[index]),
      borderRadius: BorderRadius.circular(8),
      constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
      children: timeFrames.map((tf) => Text(tf, style: const TextStyle(fontSize: 12))).toList(),
    );
  }

  List<CommonChartDataPoint> _mapDataPoints(List<DataPoint> points) {
    if (points.isEmpty) return [];
    
    return points.asMap().entries.map((entry) {
        final index = entry.key;
        final point = entry.value;
        return CommonChartDataPoint(
            x: index.toDouble(),
            y: point.value,
            xLabel: point.date, // Assuming date is a string label
            yLabel: point.value.toStringAsFixed(2),
        );
    }).toList();
  }
}
