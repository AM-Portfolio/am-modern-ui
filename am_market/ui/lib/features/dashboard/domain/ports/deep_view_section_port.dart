import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_section_id.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_section_port.dart';
import 'package:am_market_ui/features/dashboard/domain/section_view_model.dart';

class DeepViewSectionPort implements DashboardSectionPort {
  DeepViewSectionPort(this._provider);

  final MarketProvider _provider;

  @override
  DashboardSectionId get id => DashboardSectionId.deepView;

  @override
  Future<SectionViewModel> load({
    required String timeframe,
    String? focusedIndex,
  }) async {
    final symbol = (focusedIndex == null || focusedIndex.isEmpty)
        ? 'NIFTY 50'
        : focusedIndex;
    final heatmap = Map<String, double>.from(_provider.heatmapValues ?? {});
    final hist = _provider.historicalPerformance;
    final hasHist = hist != null;

    return SectionViewModel(
      stripItems: [
        SectionStripItem(
          id: symbol,
          label: symbol,
          valueText: timeframe,
          signedValue: 0,
        ),
      ],
      chartSpec: SectionChartSpec(symbols: [symbol]),
      stripEmpty: false,
      moversEmpty: true,
      lower: SectionLowerVm(
        heatmapValues: heatmap,
        isEmpty: false,
        message: (!hasHist && heatmap.isEmpty)
            ? 'Deep view unavailable for this timeframe'
            : null,
      ),
    );
  }
}
