import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import '../widgets/heatmap_filters.dart';
import '../widgets/heatmap_grid.dart';

class HeatmapView extends StatefulWidget {
  const HeatmapView({super.key});

  @override
  State<HeatmapView> createState() => _HeatmapViewState();
}

class _HeatmapViewState extends State<HeatmapView> {
  String? _percentFilter;

  final List<String> _filters = const [
    'Above +5%',
    '+2 to +5%',
    '0 to +2%',
    '0 to -2%',
    '-2 to -5%',
    'Below -5%',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketProvider>();
    final data = provider.currentIndexData;

    if (data == null || data.stocks.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: MarketColors.textMuted(context)),
        ),
      );
    }

    List stocks = List.from(data.stocks);
    if (_percentFilter != null) {
      stocks = stocks.where((s) {
        final live = provider.getPrice(s.symbol);
        final p = (live?['changePercent'] as num?)?.toDouble() ??
            (live?['pChange'] as num?)?.toDouble() ??
            s.pChange;
        switch (_percentFilter) {
          case 'Above +5%':
            return p > 5;
          case '+2 to +5%':
            return p > 2 && p <= 5;
          case '0 to +2%':
            return p >= 0 && p <= 2;
          case '0 to -2%':
            return p < 0 && p >= -2;
          case '-2 to -5%':
            return p < -2 && p >= -5;
          case 'Below -5%':
            return p < -5;
          default:
            return true;
        }
      }).toList();
    }

    stocks.sort((a, b) {
      final liveA = provider.getPrice(a.symbol);
      final liveB = provider.getPrice(b.symbol);
      final pA = (liveA?['changePercent'] as num?)?.toDouble() ?? a.pChange;
      final pB = (liveB?['changePercent'] as num?)?.toDouble() ?? b.pChange;
      return pB.compareTo(pA);
    });

    final indexLabel = data.indexName?.isNotEmpty == true
        ? data.indexName!
        : data.indexSymbol;

    return Column(
      children: [
        HeatmapFilters(
          title: 'Market Heatmap · $indexLabel',
          percentFilter: _percentFilter,
          onPercentFilterChanged: (val) => setState(() => _percentFilter = val),
          filters: _filters,
        ),
        Expanded(
          child: HeatmapGrid(
            stocks: stocks,
            provider: provider,
          ),
        ),
      ],
    );
  }
}
