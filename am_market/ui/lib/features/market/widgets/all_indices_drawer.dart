import 'package:flutter/material.dart';
import 'package:am_market_common/models/indices_region.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';
import 'package:am_market_ui/features/market/widgets/market_region_toggle.dart';
import 'drawer_index_card.dart';

class AllIndicesDrawer extends StatefulWidget {
  final List<StockIndicesMarketData> indices;
  final List<StockIndicesMarketData> globalIndices;
  final IndicesRegion region;
  final ValueChanged<IndicesRegion> onRegionChanged;
  final String initialTimeframe;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final VoidCallback onClose;
  final Map<String, Map<String, double>> allTimeframeBasePrices;

  const AllIndicesDrawer({
    required this.indices,
    required this.globalIndices,
    required this.region,
    required this.onRegionChanged,
    required this.initialTimeframe,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    required this.onClose,
    required this.allTimeframeBasePrices,
    super.key,
  });

  @override
  State<AllIndicesDrawer> createState() => _AllIndicesDrawerState();
}

class _AllIndicesDrawerState extends State<AllIndicesDrawer> {
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
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MarketRegionToggle(
            value: widget.region,
            onChanged: widget.onRegionChanged,
          ),
          const SizedBox(height: 12),
          Expanded(
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
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
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
        ],
      ),
    );
  }
}
