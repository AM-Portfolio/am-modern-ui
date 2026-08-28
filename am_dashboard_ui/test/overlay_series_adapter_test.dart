import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/domain/models/overlay_series_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overlayStateToChartData', () {
    test('maps raw points to MultiSeriesChartData contract', () {
      const state = OverlayChartState(
        timeFrame: '1W',
        selectedIds: [OverlayChartIds.overall, OverlayChartIds.nifty50],
        availablePortfolios: [],
        series: {
          OverlayChartIds.overall: OverlaySeries(
            id: OverlayChartIds.overall,
            label: OverlayChartIds.overall,
            points: [
              OverlayPoint(xLabel: '2026-08-20', value: 0),
              OverlayPoint(xLabel: '2026-08-21', value: 10),
            ],
            rawPoints: [
              OverlayPoint(xLabel: '2026-08-20', value: 100),
              OverlayPoint(xLabel: '2026-08-21', value: 110),
            ],
          ),
          OverlayChartIds.nifty50: OverlaySeries(
            id: OverlayChartIds.nifty50,
            label: OverlayChartIds.nifty50,
            points: [
              OverlayPoint(xLabel: '2026-08-20', value: 0),
              OverlayPoint(xLabel: '2026-08-21', value: 0.42),
            ],
            rawPoints: [
              OverlayPoint(xLabel: '2026-08-20', value: 24000),
              OverlayPoint(xLabel: '2026-08-21', value: 24100),
            ],
          ),
        },
        pendingIds: {},
        failedIds: {},
      );

      final data = overlayStateToChartData(state);
      expect(data.labels(), [OverlayChartIds.overall, OverlayChartIds.nifty50]);
      expect(data.series[OverlayChartIds.overall]!.first.time, '2026-08-20');
      expect(data.series[OverlayChartIds.overall]!.first.value, 0);
      expect(data.series[OverlayChartIds.overall]!.last.value, 10);
      expect(overlaySelectedLabels(state), data.labels());
    });
  });
}
