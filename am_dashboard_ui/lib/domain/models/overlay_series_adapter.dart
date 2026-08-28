import 'package:am_design_system/am_design_system.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';

/// Maps dashboard overlay state to the shared comparison chart contract.
MultiSeriesChartData overlayStateToChartData(OverlayChartState state) {
  final series = <String, List<MultiSeriesPoint>>{};
  for (final id in state.selectedIds) {
    final overlaySeries = state.series[id];
    if (overlaySeries == null) continue;
    final raw = overlaySeries.rawPoints ?? overlaySeries.points;
    if (raw.length < 2) continue;

    final points = <MultiSeriesPoint>[];
    for (final point in raw) {
      if (!point.value.isFinite || point.value <= 0) continue;
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
