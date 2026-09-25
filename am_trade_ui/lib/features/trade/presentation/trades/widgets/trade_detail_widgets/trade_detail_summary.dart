import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../models/trade_holding_view_model.dart';

class TradeDetailSummary extends StatelessWidget {
  const TradeDetailSummary({required this.trade, super.key});

  final TradeHoldingViewModel trade;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
            _buildMetricBlock(
              context,
              icon: Icons.swap_vert,
              iconColor: Colors.purple,
              title: 'Position',
              value: trade.tradePositionType ?? 'N/A',
            ),
            _buildDivider(context),
            _buildMetricBlock(
              context,
              icon: Icons.tag,
              iconColor: Colors.blue,
              title: 'Quantity',
              value: trade.displayQuantity,
            ),
            _buildDivider(context),
            _buildMetricBlock(
              context,
              icon: Icons.price_change_outlined,
              iconColor: Colors.orange,
              title: 'Avg. Price',
              value: trade.displayAvgPrice,
            ),
            _buildDivider(context),
            _buildMetricBlock(
              context,
              icon: Icons.login,
              iconColor: Colors.teal,
              title: 'Entry Price',
              value: trade.displayEntryPrice,
            ),
            _buildDivider(context),
            _buildMetricBlock(
              context,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: Colors.indigo,
              title: 'Current Value',
              value: trade.displayCurrentValue,
            ),
            _buildDivider(context),
            _buildMetricBlock(
              context,
              icon: Icons.monetization_on_outlined,
              iconColor: trade.isProfit ? Colors.green : Colors.red,
              title: 'Realized P/L',
              value: trade.displayProfitLoss,
            ),
            _buildDivider(context),
            _buildMetricBlock(
              context,
              icon: Icons.show_chart,
              iconColor: Colors.cyan,
              title: 'ROE',
              value: trade.displayReturnOnEquity,
            ),
          ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: context.colors.border.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildMetricBlock(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.textPrimary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
