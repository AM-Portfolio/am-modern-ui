import 'package:flutter/material.dart';
import 'package:am_market_common/models/available_indices.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/ranked_index_helpers.dart';
import 'package:am_market_ui/features/market/widgets/ranked_indices_list_body.dart';

class AllIndicesDrawer extends StatefulWidget {
  final List<StockIndicesMarketData> indices;
  final List<StockIndicesMarketData> globalIndices;
  final AvailableIndices? availableIndices;
  final String initialTimeframe;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final VoidCallback onClose;
  final Map<String, Map<String, double>> allTimeframeBasePrices;
  final VoidCallback? onNeedGlobal;

  const AllIndicesDrawer({
    required this.indices,
    required this.globalIndices,
    required this.initialTimeframe,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    required this.onClose,
    required this.allTimeframeBasePrices,
    this.availableIndices,
    this.onNeedGlobal,
    super.key,
  });

  @override
  State<AllIndicesDrawer> createState() => _AllIndicesDrawerState();
}

class _AllIndicesDrawerState extends State<AllIndicesDrawer> {
  IndicesListFilter _filter = IndicesListFilter.indian;

  @override
  Widget build(BuildContext context) {
    final basePrices =
        widget.allTimeframeBasePrices[widget.initialTimeframe] ?? {};

    return Container(
      width: 460,
      height: double.infinity,
      decoration: BoxDecoration(
        color: MarketColors.drawerBg(context),
        border: Border(
          left: BorderSide(
            color: MarketColors.borderDefault(context),
            width: MarketColors.borderWidth(context),
          ),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
