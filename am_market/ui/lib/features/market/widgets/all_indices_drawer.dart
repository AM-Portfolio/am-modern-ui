import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'market_header.dart';
import 'timeframe_selector.dart';
import 'drawer_index_card.dart';

class AllIndicesDrawer extends StatefulWidget {
  final List<StockIndicesMarketData> indices;
  final String initialTimeframe;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;
  final VoidCallback onClose;
  final Map<String, Map<String, double>> allTimeframeBasePrices;

  const AllIndicesDrawer({
    required this.indices,
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
      width: 460,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: MarketColors.drawerBg,
        border: Border(
          left: BorderSide(color: MarketColors.border, width: 1.0),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
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
                  border: Border.all(color: MarketColors.border, width: 1.0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close, size: 16),
                  color: MarketColors.textMuted,
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Timeframe Selector inside Drawer
          TimeframeSelector(
            selectedTimeframe: _selectedTimeframe,
            onTimeframeChanged: (tf) {
              setState(() {
                _selectedTimeframe = tf;
              });
            },
          ),

          const SizedBox(height: 16),

          // Index Grid inside Drawer
          Expanded(
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
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
        ],
      ),
    );
  }
}
