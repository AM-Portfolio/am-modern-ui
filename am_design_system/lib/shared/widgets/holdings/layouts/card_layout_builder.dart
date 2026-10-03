import 'package:flutter/material.dart';
import 'package:am_design_system/shared/models/holding.dart';

import '../../../../core/theme/color_extensions.dart';
import '../../cards/investment_card.dart';
import 'holdings_layout_builder.dart';

/// Card layout builder for holdings (mobile-optimized)
class CardLayoutBuilder extends HoldingsLayoutBuilder {
  @override
  Widget build(
    BuildContext context,
    List<Holding> holdings, {
    required HoldingsSortBy sortBy,
    required bool sortAscending,
    required HoldingsDisplayFormat displayFormat,
    required HoldingsChangeType changeType,
    ValueChanged<Holding>? onHoldingTap,
    double? width,
    double? height,
  }) {
    final sortedHoldings = sortHoldings(holdings, sortBy, sortAscending);

    if (sortedHoldings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: context.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'No holdings found',
              style: TextStyle(
                fontSize: 16,
                color: context.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedHoldings.length,
      itemBuilder: (context, index) {
        final holding = sortedHoldings[index];
        final changeValue = getChangeValue(holding, changeType);
        final changePercent = getChangePercentage(holding, changeType);
        final isPositive = changeValue >= 0;

        return InvestmentCard.legacy(
          symbol: holding.symbol,
          name: holding.companyName,
          currentValue: holding.currentValue,
          investedAmount: holding.investedAmount,
          avgPrice: holding.avgPrice,
          quantity: holding.quantity.toInt(),
          currentPrice: holding.currentPrice,
          changeValue: changeValue,
          changePercent: changePercent,
          isPositive: isPositive,
          onTap: () => onHoldingTap?.call(holding),
          customBottomWidget: _buildBottomRow(
            context,
            holding,
            changeValue,
            changePercent,
            isPositive,
            displayFormat,
          ),
        );
      },
    );
  }

  Widget _buildBottomRow(
    BuildContext context,
    Holding holding,
    double changeValue,
    double changePercent,
    bool isPositive,
    HoldingsDisplayFormat displayFormat,
  ) {
    final muted = context.textTertiary;
    final pnl = isPositive ? context.marketPositive : context.marketNegative;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Investment details
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Inv. ',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                Text(
                  formatCurrency(holding.investedAmount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: pnl,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  'Avg ${holding.avgPrice.toStringAsFixed(2)}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.inventory_2_outlined,
                  color: muted,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${holding.quantity.toInt()}',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        // Right: P&L and Current Price
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              displayFormat == HoldingsDisplayFormat.value
                  ? '${isPositive ? '+' : ''}${formatCurrency(changeValue)}'
                  : formatPercentage(changePercent),
              style: TextStyle(
                color: pnl,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Live ',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                Text(
                  holding.currentPrice.toStringAsFixed(2),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
