import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'index_card.dart';

class PinnedIndicesGrid extends StatelessWidget {
  final List<StockIndicesMarketData> indices;
  final String selectedIndexSymbol;
  final ValueChanged<StockIndicesMarketData> onIndexSelected;

  const PinnedIndicesGrid({
    required this.indices,
    required this.selectedIndexSymbol,
    required this.onIndexSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final itemsToShow = indices.take(isMobile ? 4 : 6).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 6,
        crossAxisSpacing: isMobile ? 8.0 : 10.0,
        mainAxisSpacing: isMobile ? 8.0 : 10.0,
        childAspectRatio: isMobile ? 1.6 : 1.8,
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
