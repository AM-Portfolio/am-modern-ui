import 'package:flutter/material.dart';
import 'package:am_market_common/models/available_indices.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_helpers.dart';
import 'package:am_market_ui/features/market/widgets/ranked_indices_list_body.dart';

class AllIndicesBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String initialTimeframe;
  final List<StockIndicesMarketData> indices;
  final List<StockIndicesMarketData> globalIndices;
  final AvailableIndices? availableIndices;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final Map<String, Map<String, double>> allTimeframeBasePrices;
  final VoidCallback? onNeedGlobal;

  const AllIndicesBottomSheet({
    required this.scrollController,
    required this.initialTimeframe,
    required this.indices,
    required this.globalIndices,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    required this.allTimeframeBasePrices,
    this.availableIndices,
    this.onNeedGlobal,
    super.key,
  });

  @override
  State<AllIndicesBottomSheet> createState() => _AllIndicesBottomSheetState();
}

class _AllIndicesBottomSheetState extends State<AllIndicesBottomSheet> {
  IndicesListFilter _filter = IndicesListFilter.indian;

  @override
  Widget build(BuildContext context) {
    final basePrices =
        widget.allTimeframeBasePrices[widget.initialTimeframe] ?? {};

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
                  'All Indices',
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
          Expanded(
            child: RankedIndicesListBody(
              filter: _filter,
              onFilterChanged: (f) {
                setState(() => _filter = f);
                if (f != IndicesListFilter.indian) {
                  widget.onNeedGlobal?.call();
                }
              },
              timeframe: widget.initialTimeframe,
              indian: widget.indices,
              global: widget.globalIndices,
              basePrices: basePrices,
              availableIndices: widget.availableIndices,
              selectedSymbol: widget.selectedIndexSymbol,
              onIndexSelected: widget.onIndexSelected,
              scrollController: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }
}
