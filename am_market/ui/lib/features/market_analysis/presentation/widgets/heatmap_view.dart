import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/shared/widgets/index_heatmap_panel.dart';

/// Analysis / explorer heatmap — delegates to [IndexHeatmapPanel].
class HeatmapView extends StatelessWidget {
  final ValueChanged<String>? onSelectStock;
  final String timeframe;

  const HeatmapView({
    super.key,
    this.onSelectStock,
    this.timeframe = '1D',
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketProvider>();
    final data = provider.currentIndexData;

    if (provider.isLoading && (data == null || data.stocks.isEmpty)) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (data == null || data.stocks.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: MarketColors.textMuted(context)),
        ),
      );
    }

    final symbol = (data.indexSymbol as String?)?.trim() ?? '';
    if (symbol.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: MarketColors.textMuted(context)),
        ),
      );
    }

    final indexLabel = data.indexName?.isNotEmpty == true
        ? data.indexName!
        : symbol;

    return IndexHeatmapPanel(
      indexSymbol: symbol,
      timeframe: timeframe,
      onSelectStock: onSelectStock,
      showPercentFilters: true,
      title: 'Market Heatmap · $indexLabel',
    );
  }
}
