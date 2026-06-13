import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'market_header.dart';
import 'timeframe_selector.dart';
import 'drawer_index_card.dart';

class AllIndicesBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String initialTimeframe;
  final List<StockIndicesMarketData> indices;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final Map<String, Map<String, double>> allTimeframeBasePrices;

  const AllIndicesBottomSheet({
    required this.scrollController,
    required this.initialTimeframe,
    required this.indices,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    required this.allTimeframeBasePrices,
    super.key,
  });

  @override
  State<AllIndicesBottomSheet> createState() => _AllIndicesBottomSheetState();
}

class _AllIndicesBottomSheetState extends State<AllIndicesBottomSheet> {
  late String _selectedTimeframe;

  @override
  void initState() {
    super.initState();
    _selectedTimeframe = widget.initialTimeframe;
  }

  @override
  Widget build(BuildContext context) {
    final basePricesForTf = widget.allTimeframeBasePrices[_selectedTimeframe] ?? {};

    return Container(
      decoration: const BoxDecoration(
        color: MarketColors.drawerBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: MarketColors.border, width: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 14),
              width: 36,
              height: 3,
              decoration: BoxDecoration(
                color: MarketColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All indices',
                  style: TextStyle(
                    fontSize: 14,
                    color: MarketColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    border: Border.all(color: MarketColors.border, width: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.close, size: 16),
                    color: MarketColors.textMuted,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Timeframe Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TimeframeSelector(
                selectedTimeframe: _selectedTimeframe,
                onTimeframeChanged: (tf) {
                  setState(() {
                    _selectedTimeframe = tf;
                  });
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Index Grid inside Bottom Sheet
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                controller: widget.scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.35,
                ),
                itemCount: widget.indices.length,
                itemBuilder: (context, index) {
                  final data = widget.indices[index];
                  final isSelected = data.indexSymbol == widget.selectedIndexSymbol;
                  final basePrice = basePricesForTf[data.indexSymbol];
                  return DrawerIndexCard(
                    data: data,
                    isSelected: isSelected,
                    timeframe: _selectedTimeframe,
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
