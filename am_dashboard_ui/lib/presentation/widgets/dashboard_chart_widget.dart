import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/shared/widgets/charts/chart_factory.dart';
import 'package:am_design_system/shared/widgets/charts/chart_types.dart';
import 'package:flutter/material.dart';

class DashboardChartWidget extends StatelessWidget {
  final PerformanceResponse performance;

  const DashboardChartWidget({
    super.key,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance',
            style: Theme.of(context).textTheme.titleLarge,
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
