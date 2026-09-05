import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_detail.dart';
import '../../../../portfolio/presentation/widgets/portfolio_metric_card.dart';
import 'bd_dashboard_math.dart';

class BdKpiRow extends StatelessWidget {
  final BasketDetail basket;

  const BdKpiRow({super.key, required this.basket});

  @override
  Widget build(BuildContext context) {
    final cards = _buildMetricCards(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final isSmallMobile = w < 600;
        final isMobile = w < 800;

        if (isSmallMobile) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[3]),
                ],
              ),
              const SizedBox(height: 10),
              cards[4],
            ],
          );
        }

        if (isMobile) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[1]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[2]),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cards[3]),
                  const SizedBox(width: 10),
                  Expanded(child: cards[4]),
                ],
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: cards[i]),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _buildMetricCards(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final hasMarket = BdDashboardMath.basketHasMarketPrices(basket);
    final pnlSign = basket.totalPnL >= 0 ? '+' : '';
    final created = basket.createdAt;
    final days = BdDashboardMath.daysSince(created);
    final coverage = BdDashboardMath.coverageAtCreation(basket);
    final isCompact = MediaQuery.sizeOf(context).width < 1100;

    final pnlValue = hasMarket
        ? '$pnlSign${fmt.format(basket.totalPnL)}'
        : '—';
    final pnlSub = hasMarket
        ? '$pnlSign${basket.pnlPercent.toStringAsFixed(2)}%'
        : 'Awaiting live prices';
    final currentSub = hasMarket
        ? '$pnlSign${basket.pnlPercent.toStringAsFixed(2)}% / $pnlSign${fmt.format(basket.totalPnL)}'
        : 'Valued at cost';

    return [
      PortfolioMetricCard(
        title: 'Invested Value',
        value: fmt.format(basket.totalInvestedValue),
        subtitle: 'Total amount invested',
        accentColor: ModuleColors.portfolio,
        icon: Icons.account_balance_wallet_outlined,
        tone: PortfolioMetricTone.info,
        compact: isCompact,
        glowBorder: false,
      ),
      PortfolioMetricCard(
        title: 'Current Value',
        value: fmt.format(basket.totalCurrentValue),
        subtitle: currentSub,
        accentColor: context.statusSuccess,
        icon: Icons.trending_up_rounded,
        tone: PortfolioMetricTone.profit,
        isPositive: hasMarket ? basket.totalPnL >= 0 : null,
        compact: isCompact,
        glowBorder: false,
      ),
      PortfolioMetricCard(
        title: 'Total P&L',
        value: pnlValue,
        subtitle: pnlSub,
        accentColor: basket.totalPnL >= 0 ? context.statusSuccess : context.statusError,
        icon: basket.totalPnL >= 0
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded,
        tone: basket.totalPnL >= 0
            ? PortfolioMetricTone.profit
            : PortfolioMetricTone.loss,
        isPositive: hasMarket ? basket.totalPnL >= 0 : null,
        compact: isCompact,
        glowBorder: false,
      ),
      PortfolioMetricCard(
        title: 'Invested On',
        value: created != null ? _formatDate(created) : '—',
        subtitle: '$days days',
        accentColor: ModuleColors.portfolio,
        icon: Icons.calendar_today_outlined,
        tone: PortfolioMetricTone.neutral,
        compact: isCompact,
        glowBorder: false,
      ),
      PortfolioMetricCard(
        title: 'Coverage',
        value: '${coverage.toStringAsFixed(0)}%',
        subtitle: 'of original ETF',
        accentColor: Colors.orangeAccent,
        icon: Icons.donut_large_outlined,
        tone: PortfolioMetricTone.custom,
        compact: isCompact,
        glowBorder: false,
      ),
    ];
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
