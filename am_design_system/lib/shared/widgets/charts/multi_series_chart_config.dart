import 'package:equatable/equatable.dart';

import 'multi_series_chart_data.dart';

enum MultiSeriesChartRenderer {
  multiIndex,
}

/// Presentation config for [ComparisonChartView] — no domain/API types.
class MultiSeriesChartConfig extends Equatable {
  const MultiSeriesChartConfig({
    this.selectedSeries,
    this.preferredSeriesOrder,
    this.renderer = MultiSeriesChartRenderer.multiIndex,
    this.embedMode = false,
    this.isLoading = false,
    this.error,
    this.isBarChart = false,
    this.height,
    this.onRemoveSeries,
  });

  /// When null, [resolveSelectedSeries] uses [preferredSeriesOrder] + data labels.
  final List<String>? selectedSeries;
  final List<String>? preferredSeriesOrder;
  final MultiSeriesChartRenderer renderer;
  final bool embedMode;
  final bool isLoading;
  final String? error;
  final bool isBarChart;
  final double? height;
  final void Function(String label)? onRemoveSeries;

  List<String> resolveSelectedSeries(MultiSeriesChartData data) =>
      selectedSeries ?? data.labels(preferredOrder: preferredSeriesOrder);

  @override
  List<Object?> get props => [
        selectedSeries,
        preferredSeriesOrder,
        renderer,
        embedMode,
        isLoading,
        error,
        isBarChart,
        height,
      ];
}
