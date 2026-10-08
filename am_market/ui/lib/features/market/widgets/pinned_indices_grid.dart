import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'index_card.dart';

class PinnedIndicesGrid extends StatelessWidget {
  final List<StockIndicesMarketData> indices;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;

  static const List<String> defaultFallbackSymbols = [
    'INDIA VIX',
    'NIFTY 50',
    'NIFTY NEXT 50',
    'NIFTY 100',
    'NIFTY 200',
    'NIFTY 500',
  ];

  const PinnedIndicesGrid({
    required this.indices,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final maxCount = isMobile ? 4 : 6;

    final List<StockIndicesMarketData> itemsToShow;
    if (indices.isNotEmpty) {
      itemsToShow = indices.take(maxCount).toList();
    } else {
      itemsToShow = defaultFallbackSymbols
          .take(maxCount)
          .map((sym) => StockIndicesMarketData(
                indexSymbol: sym,
                metadata: IndexMetadata(
                  last: 0.0,
                  percChange: 0.0,
                  change: 0.0,
                ),
              ))
          .toList();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 6,
        crossAxisSpacing: isMobile ? 8.0 : 10.0,
        mainAxisSpacing: isMobile ? 8.0 : 10.0,
        // Fixed compact height matching target design — prevents vertical stretching
        mainAxisExtent: isMobile ? 68.0 : 72.0,
      ),
      itemCount: itemsToShow.length,
      itemBuilder: (context, index) {
        final data = itemsToShow[index];
        final isSelected = data.indexSymbol == selectedIndexSymbol;
        return IndexCard(
          data: data,
          isSelected: isSelected,
          onTap: () => onIndexSelected(data),
        );
      },
    );
  }
}
