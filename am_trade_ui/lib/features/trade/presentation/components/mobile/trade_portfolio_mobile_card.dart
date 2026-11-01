import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';

import '../../models/trade_portfolio_view_model.dart';

class TradePortfolioMobileCard extends StatelessWidget {
  const TradePortfolioMobileCard({
    required this.portfolio,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    super.key,
  });
  final TradePortfolioViewModel portfolio;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final isPositive = portfolio.isProfit;
    final formattedDate = portfolio.lastUpdated != null
        ? DateFormat('MMM dd, HH:mm').format(portfolio.lastUpdated!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Compact
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isPositive
                            ? [
                                context.marketPositive.withValues(alpha: 0.15),
                                context.marketPositive.withValues(alpha: 0.05),
                              ]
                            : [
                                context.marketNegative.withValues(alpha: 0.15),
                                context.marketNegative.withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPositive
                            ? context.marketPositive.withValues(alpha: 0.3)
                            : context.marketNegative.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(Icons.assessment, color: isPositive ? context.marketPositive : context.marketNegative, size: 16),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                portfolio.displayName,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (onEdit != null || onDelete != null)
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    Icons.more_vert,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  onPressed: () => _showOptions(context),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                decoration: BoxDecoration(
                                  color: ModuleColors.trade.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(color: ModuleColors.trade.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'TRADE',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                    color: ModuleColors.trade,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${portfolio.displayHoldingsCount} • $formattedDate',
                          style: TextStyle(fontSize: 9, color: context.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Performance indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? context.marketPositive.withValues(alpha: 0.1)
                          : context.marketNegative.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 10,
                          color: isPositive ? context.marketPositive : context.marketNegative,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          portfolio.displayGainLossPercentage,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? context.marketPositive : context.marketNegative,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (portfolio.description != null) ...[
                const SizedBox(height: AppSpacing.xs + 2),
                Text(
                  portfolio.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.textSecondary, fontSize: 11),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),

              // Trade Metrics — equal Expanded columns (flat, no nested outline)
              Row(
                  children: [
                    _buildMetric(context, 'Trades', portfolio.displayTotalTrades, Icons.swap_horiz, ModuleColors.trade),
                    _buildMetric(
                      context,
                      'Realized',
                      portfolio.displayNetProfitLoss,
                      portfolio.isTradeProfit ? Icons.trending_up : Icons.trending_down,
                      portfolio.isTradeProfit ? context.marketPositive : context.marketNegative,
                    ),
                    _buildMetric(
                      context,
                      'Live P&L',
                      portfolio.displayGainLoss,
                      portfolio.isProfit ? Icons.show_chart : Icons.trending_down,
                      portfolio.isProfit ? context.marketPositive : context.marketNegative,
                    ),
                    _buildMetric(
                      context,
                      'Win %',
                      portfolio.displayWinRate,
                      Icons.pie_chart,
                      (portfolio.winRate ?? 0) >= 50 ? context.marketPositive : context.statusWarning,
                    ),
                  ],
                ),

              const SizedBox(height: AppSpacing.sm),

              // Portfolio Value and Gain/Loss - Compact
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Value',
                        style: TextStyle(fontSize: 10, color: context.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(portfolio.displayValue, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${portfolio.displayGainLoss}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? context.marketPositive : context.marketNegative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 12, bottom: 32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (onEdit != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.edit, color: Theme.of(context).colorScheme.onSurface),
                  title: Text('Edit Portfolio', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    onEdit?.call();
                  },
                ),
              if (onDelete != null)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: Icon(Icons.delete, color: context.statusError),
                  title: Text('Delete Portfolio', style: TextStyle(fontSize: 16, color: context.statusError)),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete?.call();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon, Color color) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 8, color: context.textSecondary, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}
