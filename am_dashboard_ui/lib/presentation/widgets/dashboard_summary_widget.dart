import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardSummaryWidget extends StatelessWidget {
  final DashboardSummary summary;

  const DashboardSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);

    return Column(
      children: [
        // Main Value Card
        AmStatCard(
          title: 'Total Portfolio Value',
          value: currencyFormat.format(summary.totalValue),
          subtitle: '${percentFormat.format(summary.dayChangePercentage / 100)} Today',
          type: StatType.accent,
          icon: Icons.account_balance_wallet,
          progress: 1.0, // Full bar for main value
        ),
        const SizedBox(height: 16),
        
        // Secondary Metrics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            // Responsive grid calculation
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 1;
            final gap = 16.0;
            
            if (crossAxisCount == 1) {
              return Column(
                children: [
                   _buildInvestedCard(currencyFormat),
                   SizedBox(height: gap),
                   _buildReturnCard(currencyFormat, percentFormat),
                   SizedBox(height: gap),
                   _buildPortfoliosCard(),
                ],
              );
            }
            
            return Row(
              children: [
                Expanded(child: _buildInvestedCard(currencyFormat)),
                SizedBox(width: gap),
                Expanded(child: _buildReturnCard(currencyFormat, percentFormat)),
                SizedBox(width: gap),
                Expanded(child: _buildPortfoliosCard()),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildInvestedCard(NumberFormat currencyFormat) {
    return AmStatCard(
      title: 'Total Invested',
      value: currencyFormat.format(summary.totalInvested),
      type: StatType.neutral,
      icon: Icons.monetization_on_outlined,
    );
  }

  Widget _buildReturnCard(NumberFormat currencyFormat, NumberFormat percentFormat) {
    final isPositive = summary.totalGainLoss >= 0;
    return AmStatCard(
      title: 'Total Return',
      value: currencyFormat.format(summary.totalGainLoss),
      subtitle: percentFormat.format(summary.totalGainLossPercentage / 100),
      type: isPositive ? StatType.positive : StatType.negative,
      icon: isPositive ? Icons.trending_up : Icons.trending_down,
    );
  }

  Widget _buildPortfoliosCard() {
    return AmStatCard(
      title: 'Active Portfolios',
      value: summary.totalPortfolios.toString(),
      type: StatType.neutral,
      icon: Icons.pie_chart_outline,
    );
  }
}

