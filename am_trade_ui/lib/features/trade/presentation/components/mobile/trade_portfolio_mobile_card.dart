import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/trade_portfolio_view_model.dart';

class TradePortfolioMobileCard extends StatelessWidget {
  const TradePortfolioMobileCard({required this.portfolio, required this.onTap, super.key});
  final TradePortfolioViewModel portfolio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPositive = portfolio.isProfit;
    final formattedDate = portfolio.lastUpdated != null
        ? DateFormat('MMM dd, HH:mm').format(portfolio.lastUpdated!)
        : 'N/A';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isPositive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
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
                            ? [Colors.green.withOpacity(0.15), Colors.green.withOpacity(0.05)]
                            : [Colors.red.withOpacity(0.15), Colors.red.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isPositive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Icon(Icons.assessment, color: isPositive ? Colors.green : Colors.red, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                portfolio.displayName,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.purple.withOpacity(0.3)),
                              ),
                              child: Text(
                                'TRADE',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${portfolio.displayHoldingsCount} • $formattedDate',
                          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  // Performance indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPositive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          size: 10,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          portfolio.displayGainLossPercentage,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (portfolio.description != null) ...[
                const SizedBox(height: 6),
                Text(
                  portfolio.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                ),
              ],

              const SizedBox(height: 8),

              // Trade Metrics - Compact 3 columns
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric(context, 'Trades', portfolio.displayTotalTrades, Icons.swap_horiz, Colors.purple),
                    Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                    _buildMetric(
                      context,
                      'Net P&L',
                      portfolio.displayNetProfitLoss,
                      portfolio.isTradeProfit ? Icons.trending_up : Icons.trending_down,
                      portfolio.isTradeProfit ? Colors.green : Colors.red,
                    ),
                    Container(width: 1, height: 24, color: Theme.of(context).dividerColor),
                    _buildMetric(
                      context,
                      'Win Rate',
                      portfolio.displayWinRate,
                      Icons.show_chart,
                      (portfolio.winRate ?? 0) >= 50 ? Colors.green : Colors.orange,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

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
                        style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(portfolio.displayValue, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${portfolio.displayGainLoss}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isPositive ? Colors.green : Colors.red,
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

  Widget _buildMetric(BuildContext context, String label, String value, IconData icon, Color color) => Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 11),
            const SizedBox(width: 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 8, color: Colors.grey[600], fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
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
