import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/available_indices.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/indices_advances_header.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_helpers.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_row.dart';

/// Shared ranked indices list (filter + TF dropdown + advances + rows).
class RankedIndicesListBody extends StatelessWidget {
  const RankedIndicesListBody({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.timeframe,
    required this.indian,
    required this.global,
    required this.basePrices,
    required this.availableIndices,
    required this.selectedSymbol,
    required this.onIndexSelected,
    this.scrollController,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 0),
    this.clockLabel,
  });

  final IndicesListFilter filter;
  final ValueChanged<IndicesListFilter> onFilterChanged;
  final String timeframe;
  final List<StockIndicesMarketData> indian;
  final List<StockIndicesMarketData> global;
  final Map<String, double> basePrices;
  final AvailableIndices? availableIndices;
  final String? selectedSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry padding;
  final String? clockLabel;

  @override
  Widget build(BuildContext context) {
    final sorted = rankedSortedIndices(
      indian: indian,
      global: global,
      filter: filter,
      timeframe: timeframe,
      basePrices: basePrices,
    );

    var advances = 0;
    var declines = 0;
    var maxAbs = 0.0;
    for (final d in sorted) {
      final p = rankedDisplayPChange(d, timeframe, basePrices);
      if (p > 0) advances++;
      if (p < 0) declines++;
      final a = p.abs();
      if (a > maxAbs) maxAbs = a;
    }
    if (maxAbs <= 0) maxAbs = 1;

    final globalSet = {
      ...global.map((e) => e.indexSymbol.toUpperCase()),
      ...?availableIndices?.globalIndices.map((e) => e.toUpperCase()),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: padding,
          child: Row(
            children: [
              Expanded(
                child: IndicesListFilterToggle(
                  value: filter,
                  onChanged: onFilterChanged,
                ),
              ),
              const SizedBox(width: 8),
              const GlobalTimeFrameBar(
                variant: GlobalTimeFrameVariant.dropdown,
                dropdownWidth: 72,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: padding,
          child: IndicesAdvancesHeader(
            advances: advances,
            declines: declines,
            clockLabel: clockLabel,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: sorted.isEmpty
              ? Center(
                  child: Text(
                    filter == IndicesListFilter.global
                        ? 'No global indices available'
                        : 'No indices available',
                    style: TextStyle(
                      fontSize: 13,
                      color: MarketColors.textMuted(context),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    (padding is EdgeInsets)
                        ? (padding as EdgeInsets).left
                        : 16,
                    0,
                    (padding is EdgeInsets)
                        ? (padding as EdgeInsets).right
                        : 16,
                    16,
                  ),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data = sorted[index];
                    final pChange =
                        rankedDisplayPChange(data, timeframe, basePrices);
                    final change =
                        rankedDisplayChange(data, timeframe, basePrices);
                    final isGlobal = globalSet
                        .contains(data.indexSymbol.toUpperCase());
                    return RankedIndexRow(
                      rank: index + 1,
                      data: data,
                      category: rankedCategoryTag(
                        data.indexSymbol,
                        availableIndices,
                        isGlobal: isGlobal,
                      ),
                      ltp: data.lastPrice,
                      change: change,
                      pChange: pChange,
                      barFraction: pChange.abs() / maxAbs,
                      isSelected: data.indexSymbol == selectedSymbol,
                      onTap: () => onIndexSelected(data),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
