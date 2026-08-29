import 'package:am_design_system/am_design_system.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';

/// Maps dashboard overlay state to the shared comparison chart contract.
///
/// Uses pre-computed % change ([OverlaySeries.points]) so the chart does not
/// re-baseline raw wealth/index levels (which caused invalid values like -110%).
MultiSeriesChartData overlayStateToChartData(OverlayChartState state) {
  final series = <String, List<MultiSeriesPoint>>{};
  for (final id in state.selectedIds) {
    final overlaySeries = state.series[id];
    if (overlaySeries == null) continue;
    final percentPoints = overlaySeries.points;
    if (percentPoints.length < 2) continue;

    final points = <MultiSeriesPoint>[];
    for (final point in percentPoints) {
      if (!point.value.isFinite) continue;
      if (point.xLabel.isEmpty) continue;
      points.add(MultiSeriesPoint(time: point.xLabel, value: point.value));
    }
    if (points.length >= 2) {
      series[overlaySeries.label] = points;
    }
  }
  return MultiSeriesChartData(series: series);
}

/// Preferred label order for the overlay chart.
List<String> overlaySelectedLabels(OverlayChartState state) {
  return overlayStateToChartData(state).labels(
    preferredOrder: [
      for (final id in state.selectedIds)
        if (state.series[id] != null) state.series[id]!.label,
    ],
  );
}
