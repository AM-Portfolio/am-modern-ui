import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';

/// Individual index card showing name, price, and change
class IndexCard extends StatelessWidget {
  final StockIndicesMarketData data;

  const IndexCard({
    required this.data,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketProvider>(
      builder: (context, provider, child) {
        final numberFormat = NumberFormat('#,##,###.##', 'en_IN');
        
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
        final accentColor = isLoading 
            ? Colors.white54
            : (isPositive ? const Color(0xFF00FF88) : const Color(0xFFFF6B6B));

        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D26).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Index Name
              Text(
                data.indexSymbol,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                '${numberFormat.format(data.lastPrice)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Change Amount
              Row(
                children: [
                  Icon(
                    isLoading ? Icons.sync : (isPositive ? Icons.arrow_upward : Icons.arrow_downward),
                    color: accentColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLoading ? '...' : '${isPositive ? '+' : ''}${numberFormat.format(displayChange)}',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),

              // Percentage
              Text(
                isLoading ? 'Loading...' : '${isPositive ? '+' : ''}${displayPChange.toStringAsFixed(2)}%$timeframeLabel',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
