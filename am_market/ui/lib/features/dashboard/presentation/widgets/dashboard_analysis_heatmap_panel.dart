import 'package:flutter/material.dart';
import 'package:am_market_ui/shared/widgets/index_heatmap_panel.dart';

/// Dashboard index heatmap — thin host over [IndexHeatmapPanel].
class DashboardAnalysisHeatmapPanel extends StatelessWidget {
  const DashboardAnalysisHeatmapPanel({
    super.key,
    required this.indexSymbol,
    required this.timeframe,
    this.pageSize = 40,
    this.onSelectStock,
  });

  final String indexSymbol;
  final String timeframe;
  final int pageSize;
  final ValueChanged<String>? onSelectStock;

  @override
  Widget build(BuildContext context) {
    return IndexHeatmapPanel(
      indexSymbol: indexSymbol,
      timeframe: timeframe,
      pageSize: pageSize,
      onSelectStock: onSelectStock,
    );
  }
}
