import 'package:flutter/material.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_design_system/am_design_system.dart';

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
        double displayLastPrice = data.lastPrice;
        double displayChange = data.change;
        double displayPChange = data.pChange;
        final liveQuote = provider.getPrice(data.indexSymbol);
        final liveLastPrice = (liveQuote?['lastPrice'] as num?)?.toDouble();
        final liveChange = (liveQuote?['change'] as num?)?.toDouble();
        final liveChangePercent =
            (liveQuote?['changePercent'] as num?)?.toDouble();
        if (provider.selectedIndicesTimeframe == '1D') {
          if (liveLastPrice != null && liveLastPrice > 0) {
            displayLastPrice = liveLastPrice;
          }
          if (liveChange != null && liveChangePercent != null) {
            displayChange = liveChange;
            displayPChange = liveChangePercent;
          }
        }
        final liveChangeUnavailable =
            provider.selectedIndicesTimeframe == '1D' &&
                liveQuote?['lastPrice'] != null &&
                liveQuote?['changePercent'] == null &&
                liveQuote?['previousClose'] == null;
        String timeframeLabel = '';

        if (provider.selectedIndicesTimeframe != '1D') {
          timeframeLabel = ' (${provider.selectedIndicesTimeframe})';
          if (provider.isLoadingBasePrices) {
            isLoading = true;
          }
        }

        final isPositive = displayChange >= 0;
        final accentColor = isLoading || liveChangeUnavailable
            ? context.colors.textSecondary
            : (isPositive
                ? context.colors.statusSuccess
                : context.colors.statusError);

        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.actionPrimaryBg.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.1),
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
                  color: context.colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Price
              Text(
                numberFormat.format(displayLastPrice),
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),

              // Change Amount
              Row(
                children: [
                  Icon(
                    isLoading
                        ? Icons.sync
                        : (liveChangeUnavailable
                            ? Icons.remove
                            : (isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward)),
                    color: accentColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isLoading
                        ? '...'
                        : (liveChangeUnavailable
                            ? '—'
                            : '${isPositive ? '+' : ''}${numberFormat.format(displayChange)}'),
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
                isLoading
                    ? 'Loading...'
                    : (liveChangeUnavailable
                        ? 'Change pending'
                        : '${isPositive ? '+' : ''}${displayPChange.toStringAsFixed(2)}%$timeframeLabel'),
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
