import 'package:flutter/material.dart';

import '../../../models/trade_holding_view_model.dart';

class TradeDetailSummary extends StatelessWidget {
  const TradeDetailSummary({required this.trade, super.key});

  final TradeHoldingViewModel trade;

  @override
  Widget build(BuildContext context) {
    final isProfit = trade.isProfit;

    return Column(
      children: [
        // Trade Details Card
        _buildModernCard(
          context,
          icon: Icons.receipt_long_rounded,
          iconColor: Colors.purple.shade600,
          title: 'Trade Details',
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildModernInfoRow(context, 'Position', trade.tradePositionType ?? 'N/A'),
                      _buildModernInfoRow(context, 'Quantity', trade.displayQuantity),
                      _buildModernInfoRow(context, 'Executions', '${trade.executionCount}'),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      _buildModernInfoRow(context, 'Average Price', trade.displayAvgPrice),
                      _buildModernInfoRow(context, 'Holding Period', trade.displayHoldingPeriod),
                      _buildModernInfoRow(context, 'Currency', trade.displayCurrency),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Price, Fees, Performance Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildModernCard(
                context,
                icon: Icons.price_change_rounded,
                iconColor: Colors.indigo.shade600,
                title: 'Price & Value',
                children: [
                  _buildModernInfoRow(context, 'Entry Price', trade.displayEntryPrice),
                  _buildModernInfoRow(context, 'Exit Price', trade.displayExitPrice),
                  _buildModernInfoRow(context, 'Average Price', trade.displayAvgPrice),
                  _buildModernInfoRow(context, 'Current Price', trade.displayCurrentPrice),
                  _buildModernInfoRow(context, 'Current Value', trade.displayCurrentValue),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildModernCard(
                context,
                icon: Icons.receipt_rounded,
                iconColor: Colors.orange.shade600,
                title: 'Fees & Charges',
                children: [
                  _buildModernInfoRow(context, 'Entry Fees', trade.displayEntryFees),
                  _buildModernInfoRow(context, 'Exit Fees', trade.displayExitFees),
                  const SizedBox(height: 8),
                  Divider(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  _buildModernInfoRow(context, 'Total Fees', trade.displayTotalFees, isBold: true),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildModernCard(
                context,
                icon: Icons.analytics_rounded,
                iconColor: isProfit ? Colors.green.shade600 : Colors.red.shade600,
                title: 'Performance Metrics',
                children: [
                  _buildModernInfoRow(
                    context,
                    'Profit/Loss',
                    trade.displayProfitLoss,
                    valueColor: isProfit ? Colors.green.shade700 : Colors.red.shade700,
                    isBold: true,
                  ),
                  _buildModernInfoRow(context, 'Return on Equity', trade.displayReturnOnEquity),
                  const SizedBox(height: 8),
                  Divider(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                  const SizedBox(height: 8),
                  _buildModernInfoRow(context, 'Risk Amount', trade.displayRiskAmount),
                  _buildModernInfoRow(context, 'Reward Amount', trade.displayRewardAmount),
                  _buildModernInfoRow(context, 'Risk/Reward Ratio', trade.displayRiskRewardRatio),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.15)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Card Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [iconColor.withOpacity(0.08), iconColor.withOpacity(0.03)],
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Card Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: children),
        ),
      ],
    ),
  );

  Widget _buildModernInfoRow(
    BuildContext context,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 14 : 13,
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}
