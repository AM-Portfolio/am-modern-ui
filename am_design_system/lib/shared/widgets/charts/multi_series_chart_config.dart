import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

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
    this.timeFrameCode,
    this.headerLeading,
    this.legendTrailing,
    this.showExpandButton = true,
    this.onOpenExpanded,
    this.expandedChartPath,
    this.showEndValuePills = true,
    this.preNormalizedPercent = false,
    this.initialShowAbsoluteValues = false,
    this.accentColor,
  });

  /// When null, [resolveSelectedSeries] uses [preferredSeriesOrder] + data labels.
  final List<String>? selectedSeries;
  final List<String>? preferredSeriesOrder;
  final MultiSeriesChartRenderer renderer;
  /// When true, skips outer card padding/shadow only (legend + toggles still show).
  final bool embedMode;
  final bool isLoading;
  final String? error;
  final bool isBarChart;
  final double? height;
  final void Function(String label)? onRemoveSeries;

  /// Selected timeframe code (1D, 1W, …) for stable X-axis labels.
  final String? timeFrameCode;

  /// Optional row above legend (e.g. dashboard wealth summary).
  final Widget? headerLeading;

  /// Trailing control beside legend (e.g. add-series popup).
  final Widget? legendTrailing;

  final bool showExpandButton;
  final VoidCallback? onOpenExpanded;

  /// Deep-link path for expand button new-tab (Ctrl/Cmd+click).
  final String? expandedChartPath;

  /// Colored % badges at the right edge of the line chart.
  final bool showEndValuePills;

  /// Values are already % change from each series baseline (overlay charts).
  final bool preNormalizedPercent;

  /// When true, chart opens by default in Absolute Price (123 / ₹) mode instead of % Change mode.
  final bool initialShowAbsoluteValues;

  /// Module brand for the first series (line + area fill). Later series keep the shared palette.
  final Color? accentColor;

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
        timeFrameCode,
        showExpandButton,
        expandedChartPath,
        showEndValuePills,
        preNormalizedPercent,
        initialShowAbsoluteValues,
        accentColor,
      ];
}
