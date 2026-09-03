import 'package:flutter/material.dart';
import 'package:am_market_common/models/indices_region.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/market_region_toggle.dart';
import 'drawer_index_card.dart';

class AllIndicesBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String initialTimeframe;
  final List<StockIndicesMarketData> indices;
  final List<StockIndicesMarketData> globalIndices;
  final IndicesRegion region;
  final ValueChanged<IndicesRegion> onRegionChanged;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final Map<String, Map<String, double>> allTimeframeBasePrices;

  const AllIndicesBottomSheet({
    required this.scrollController,
    required this.initialTimeframe,
    required this.indices,
    required this.globalIndices,
    required this.region,
    required this.onRegionChanged,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    required this.allTimeframeBasePrices,
    super.key,
  });

  @override
  State<AllIndicesBottomSheet> createState() => _AllIndicesBottomSheetState();
}

class _AllIndicesBottomSheetState extends State<AllIndicesBottomSheet> {
  List<StockIndicesMarketData> get _activeIndices =>
      widget.region == IndicesRegion.global ? widget.globalIndices : widget.indices;

  double _displayPChange(
    StockIndicesMarketData data,
    Map<String, double> basePricesForTf,
  ) {
    if (widget.initialTimeframe != '1D') {
      final base = basePricesForTf[data.indexSymbol];
      if (base != null && base > 0) {
        return ((data.lastPrice - base) / base) * 100;
      }
      return 0.0;
    }
    return data.pChange;
  }

  @override
  Widget build(BuildContext context) {
    final basePricesForTf =
        widget.allTimeframeBasePrices[widget.initialTimeframe] ?? {};
    final active = List<StockIndicesMarketData>.from(_activeIndices)
      ..sort((a, b) => _displayPChange(b, basePricesForTf)
          .compareTo(_displayPChange(a, basePricesForTf)));

    return Container(
      decoration: BoxDecoration(
        color: MarketColors.drawerBg(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: MarketColors.borderDefault(context),
            width: MarketColors.borderWidth(context),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: MarketColors.borderDefault(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All indices',
                  style: TextStyle(
                    fontSize: 14,
                    color: MarketColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: MarketColors.borderDefault(context),
                      width: MarketColors.borderWidth(context),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 16),
                    color: MarketColors.textMuted(context),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MarketRegionToggle(
              value: widget.region,
              onChanged: widget.onRegionChanged,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: active.isEmpty
                  ? Center(
                      child: Text(
                        widget.region == IndicesRegion.global
                            ? 'No global indices available'
                            : 'No indices available',
                        style: TextStyle(
                          fontSize: 13,
                          color: MarketColors.textMuted(context),
                        ),
                      ),
                    )
                  : GridView.builder(
                      controller: widget.scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1.35,
                      ),
                      itemCount: active.length,
                      itemBuilder: (context, index) {
                        final data = active[index];
                        final isSelected = data.indexSymbol == widget.selectedIndexSymbol;
                        final basePrice = basePricesForTf[data.indexSymbol];
                        return DrawerIndexCard(
                          data: data,
                          isSelected: isSelected,
                          timeframe: widget.initialTimeframe,
                          basePrice: basePrice,
                          onTap: () => widget.onIndexSelected(data),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
