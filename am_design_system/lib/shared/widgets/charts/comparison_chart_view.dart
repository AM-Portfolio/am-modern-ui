import 'package:flutter/material.dart';

import 'multi_index_chart.dart';
import 'multi_series_chart_config.dart';
import 'multi_series_chart_data.dart';

/// Single public entry point for time-series comparison charts.
class ComparisonChartView extends StatelessWidget {
  const ComparisonChartView({
    super.key,
    required this.data,
    required this.config,
  });

  final MultiSeriesChartData data;
  final MultiSeriesChartConfig config;

  @override
  Widget build(BuildContext context) {
    final labels = config.resolveSelectedSeries(data);
    final Widget chart = switch (config.renderer) {
      MultiSeriesChartRenderer.multiIndex => MultiIndexChart(
          chartData: data,
          selectedIndices: labels,
          embedMode: config.embedMode,
          isLoading: config.isLoading,
          error: config.error,
          isBarChart: config.isBarChart,
          onRemoveIndex: config.onRemoveSeries,
          timeFrameCode: config.timeFrameCode,
          headerLeading: config.headerLeading,
          legendTrailing: config.legendTrailing,
          showExpandButton: config.showExpandButton,
          onOpenExpanded: config.onOpenExpanded,
          expandedChartPath: config.expandedChartPath,
          showEndValuePills: config.showEndValuePills,
          preNormalizedPercent: config.preNormalizedPercent,
        ),
    };

    final height = config.height;
    if (height != null) {
      return SizedBox(height: height, child: chart);
    }
    return chart;
  }
}
