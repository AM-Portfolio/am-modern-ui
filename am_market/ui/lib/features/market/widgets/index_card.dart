import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'market_header.dart';

class IndexCard extends StatelessWidget {
  final StockIndicesMarketData data;
  final bool isSelected;
  final VoidCallback onTap;

  const IndexCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final numberFormat = NumberFormat('#,##,###.##', 'en_IN');

    return Consumer<MarketProvider>(
      builder: (context, provider, child) {
        bool isLoading = false;
        double displayChange = data.change;
        double displayPChange = data.pChange;
        String timeframeLabel = '';

        if (provider.selectedIndicesTimeframe != '1D') {
          timeframeLabel = ' (${provider.selectedIndicesTimeframe})';
          if (provider.isLoadingBasePrices) {
            isLoading = true;
          } else {
            final basePrice = provider.timeframeBasePrices[data.indexSymbol];
            if (basePrice != null && basePrice > 0) {
              displayChange = data.lastPrice - basePrice;
              displayPChange = (displayChange / basePrice) * 100;
            } else {
              displayChange = 0;
              displayPChange = 0;
            }
          }
        }

        final isPositive = displayChange >= 0;
        final changeColor = isLoading
            ? MarketColors.textMuted
            : (isPositive ? MarketColors.positive : MarketColors.negative);
        final prefix = isPositive ? '↑' : '↓';
        final sign = isPositive ? '+' : '';

        final cardContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Index Name (All Caps, 0.04em letter-spacing)
            Text(
              data.indexSymbol.toUpperCase(),
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                color: MarketColors.textMuted,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.04 * (isMobile ? 9 : 10),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Index Value
            Text(
              isLoading ? '...' : numberFormat.format(data.lastPrice),
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: MarketColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Change Amount & Percentage
            Text(
              isLoading
                  ? 'Loading...'
                  : '$prefix $sign${displayPChange.toStringAsFixed(2)}%$timeframeLabel',
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                color: changeColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Stack(
              children: [
                // Animated Card Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  height: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 10 : 12,
                    horizontal: isMobile ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: MarketColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? MarketColors.accent : MarketColors.border,
                      width: 0.5,
                    ),
                  ),
                  child: cardContent,
                ),

                // Selected Indicator (Desktop only)
                if (!isMobile && isSelected)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 24,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: MarketColors.accent,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(2),
                            topRight: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
