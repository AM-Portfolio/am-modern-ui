import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';

class DrawerIndexCard extends StatelessWidget {
  final StockIndicesMarketData data;
  final bool isSelected;
  final VoidCallback onTap;
  final String timeframe;
  final double? basePrice;

  const DrawerIndexCard({
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.timeframe,
    this.basePrice,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final mt = context.marketTheme;

    double displayChange = data.change;
    double displayPChange = data.pChange;

    if (timeframe != '1D' && basePrice != null && basePrice! > 0) {
      displayChange = data.lastPrice - basePrice!;
      displayPChange = (displayChange / basePrice!) * 100;
    } else if (timeframe != '1D') {
      displayChange = 0.0;
      displayPChange = 0.0;
    }

    final isPositive = displayChange >= 0;
    final sign = isPositive ? '+' : '';
    final prefix = isPositive ? '↑' : '↓';
    final accentColor = isPositive ? mt.positive : mt.negative;
    final badgeBgColor = isPositive ? mt.posBadgeBg : mt.negBadgeBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: mt.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? mt.accent : mt.border,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: Name & Change Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data.indexSymbol.toUpperCase(),
                      style: TextStyle(
                        fontSize: isMobile ? 9 : 10,
                        color: mt.textMuted,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.04 * (isMobile ? 9 : 10),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 11.0,
                          color: accentColor,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isPositive
                              ? '+${displayPChange.toStringAsFixed(2)}%'
                              : '${displayPChange.toStringAsFixed(2)}%',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: accentColor,
                            fontWeight: FontWeight.w400,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Index Value
              Text(
                data.lastPrice.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: isMobile ? 14 : 17,
                  color: mt.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              // Change Detail
              Text(
                '$timeframe change: $sign${displayChange.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: isMobile ? 10 : 12,
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
