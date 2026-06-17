import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/features/market/widgets/market_colors.dart';

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
            ? MarketColors.textMuted(context)
            : (isPositive ? MarketColors.positive(context) : MarketColors.negative(context));

        final displayPChangeFormatted = displayPChange.toStringAsFixed(2);
        final displayChangeFormatted = numberFormat.format(displayChange.abs());

        final cardContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Index Name (All Caps, 0.04em letter-spacing)
            Text(
              data.indexSymbol.toUpperCase(),
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                color: MarketColors.textMuted(context),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.04 * (isMobile ? 9 : 10),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 4),

            // Index Value
            Text(
              isLoading ? '...' : numberFormat.format(data.lastPrice),
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                color: MarketColors.textPrimary(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 3),

            // Change Amount & Percentage (stacked vertically)
            if (isLoading)
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 11,
                  color: changeColor,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Native Arrow Icon + Absolute Point Change
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                        size: isMobile ? 11.0 : 12.0,
                        color: isPositive ? MarketColors.positive(context) : MarketColors.negative(context),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        isPositive
                            ? '+$displayChangeFormatted'
                            : '-$displayChangeFormatted',
                        style: TextStyle(
                          fontSize: isMobile ? 10.0 : 11.0,
                          color: isPositive ? MarketColors.positive(context) : MarketColors.negative(context),
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 3),

                  // Row 2: Percentage Change + Timeframe Label
                  Text(
                    isPositive
                        ? '+$displayPChangeFormatted%$timeframeLabel'
                        : '$displayPChangeFormatted%$timeframeLabel',
                    style: TextStyle(
                      fontSize: isMobile ? 9.5 : 10.5,
                      color: isPositive ? MarketColors.positive(context) : MarketColors.negative(context),
                      fontWeight: FontWeight.w400,
                      height: 1.0,
                    ),
                  ),
                ],
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
                  padding: EdgeInsets.only(
                    top: isMobile ? 10 : 12,
                    bottom: isMobile ? 10 : 12,
                    left: isMobile ? 12 : 14,
                    right: isMobile ? 12 : 14,
                  ),
                  decoration: BoxDecoration(
                    color: MarketColors.cardSurface(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? MarketColors.borderSelected(context) : MarketColors.borderDefault(context),
                      width: MarketColors.borderWidth(context),
                    ),
                    boxShadow: isSelected ? MarketColors.selectedGlow(context) : [],
                  ),
                  child: cardContent,
                ),

                // Selected Indicator (Desktop only)
                if (!isMobile)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        width: isSelected ? 24.0 : 0.0,
                        height: 2.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C896),
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
