import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_section_id.dart';
import 'package:am_market_ui/features/dashboard/domain/dashboard_section_port.dart';
import 'package:am_market_ui/features/dashboard/domain/section_view_model.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_helpers.dart';

class OverviewSectionPort implements DashboardSectionPort {
  OverviewSectionPort(this._provider, {Map<String, double>? basePrices})
      : _basePrices = basePrices ?? const {};

  final MarketProvider _provider;
  final Map<String, double> _basePrices;

  @override
  DashboardSectionId get id => DashboardSectionId.overview;

  @override
  Future<SectionViewModel> load({
    required String timeframe,
    String? focusedIndex,
  }) async {
    final indices = _provider.allIndicesData;
    final strip = [
      for (final d in indices)
        SectionStripItem(
          id: d.indexSymbol,
          label: d.indexSymbol,
          valueText:
              '${rankedDisplayPChange(d, timeframe, _basePrices).toStringAsFixed(2)}%',
          signedValue: rankedDisplayPChange(d, timeframe, _basePrices),
        ),
    ];

    final movers = _indexMovers(indices, timeframe);
    final heatmap = Map<String, double>.from(_provider.heatmapValues ?? {});

    return SectionViewModel(
      stripItems: strip,
      chartSpec: const SectionChartSpec(
        symbols: ['NIFTY 50', 'SENSEX', 'NIFTY BANK'],
      ),
      gainers: movers.$1,
      losers: movers.$2,
      stripEmpty: strip.isEmpty,
      moversEmpty: movers.$1.isEmpty && movers.$2.isEmpty,
      lower: SectionLowerVm(
        heatmapValues: heatmap,
        isEmpty: false,
        message: heatmap.isEmpty ? 'Live map unavailable' : null,
      ),
    );
  }

  (List<SectionMoverItem>, List<SectionMoverItem>) _indexMovers(
    List<StockIndicesMarketData> indices,
    String timeframe,
  ) {
    final scored = [
      for (final d in indices)
        (
          d: d,
          pct: rankedDisplayPChange(d, timeframe, _basePrices),
          ch: rankedDisplayChange(d, timeframe, _basePrices),
        ),
    ]..sort((a, b) => b.pct.compareTo(a.pct));

    SectionMoverItem toItem(
            ({StockIndicesMarketData d, double pct, double ch}) e) =>
        SectionMoverItem(
          symbol: e.d.indexSymbol,
          name: e.d.indexSymbol,
          ltp: e.d.lastPrice,
          change: e.ch,
          pChange: e.pct,
        );

    final gainers = scored
        .where((e) => e.pct > 0)
        .take(5)
        .map(toItem)
        .toList();
    final losers = scored.reversed
        .where((e) => e.pct < 0)
        .take(5)
        .map(toItem)
        .toList();
    return (gainers, losers);
  }
}
