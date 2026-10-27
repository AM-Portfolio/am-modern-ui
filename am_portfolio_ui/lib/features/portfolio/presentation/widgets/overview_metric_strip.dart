import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../internal/domain/entities/portfolio_holding.dart';
import '../../internal/domain/entities/portfolio_summary.dart';
import 'portfolio_metric_card.dart';

/// Overview KPI strip. Mail / zero-cost books omit Total Return and
/// Invested Amount. Broker books (and the loading frame) keep all four.
class OverviewMetricStrip extends StatelessWidget {
  const OverviewMetricStrip({
    super.key,
    required this.summary,
    required this.holdings,
    required this.isPhone,
    this.compact = false,
    this.glowBorder = true,
    this.animate = false,
  });

  final PortfolioSummary summary;
  final List<PortfolioHolding> holdings;
  final bool isPhone;
  final bool compact;
  final bool glowBorder;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final cards = _cards(context);
    if (cards.isEmpty) return const SizedBox.shrink();
    if (isPhone) return _phoneLayout(cards);
    return _wideLayout(cards);
  }

  List<Widget> _cards(BuildContext context) {
    final showCost = overviewShowsCostMetrics(
      investmentValue: summary.investmentValue,
      totalInvested: summary.totalInvested,
      holdings: holdings,
    );
    final periodReturn = summary.totalGainLoss;
    final periodReturnPct = summary.totalGainLossPercentage;
    final todayLooksCollapsedZero = !summary.isLivePrices &&
        summary.todayChange != null &&
        summary.todayChange!.abs() < 0.005;
    final effectiveToday =
        todayLooksCollapsedZero ? null : summary.todayChange;
    final effectiveTodayPct =
        todayLooksCollapsedZero ? null : summary.todayChangePercentage;
    final todayUnavailable = effectiveToday == null;
    final todayChange = effectiveToday ?? 0;
    final todayChangePct = effectiveTodayPct ?? 0;
    final modulePink = ModuleColors.portfolio;

    return [
      if (showCost)
        PortfolioMetricCard(
          title: 'Total Return',
          value: _formatCurrency(periodReturn),
          subtitle:
              '${periodReturnPct >= 0 ? "+" : ""}${periodReturnPct.toStringAsFixed(2)}% in total',
          accentColor: periodReturn == 0
              ? context.statusNeutral
              : (periodReturn > 0
                  ? context.marketPositive
                  : context.marketNegative),
          chromeColor: modulePink,
          icon: periodReturn >= 0
              ? Icons.trending_up_rounded
              : Icons.trending_down_rounded,
          isPositive: periodReturn == 0 ? null : periodReturn > 0,
          compact: compact,
          glowBorder: glowBorder,
          tooltip: 'Total unrealized profit or loss across all holdings',
        ),
      PortfolioMetricCard(
        title: "Today's P&L",
        value: todayUnavailable ? '—' : _formatCurrency(todayChange),
        subtitle: todayUnavailable
            ? 'Unavailable'
            : '${todayChangePct >= 0 ? "+" : ""}${todayChangePct.toStringAsFixed(2)}%',
        accentColor: todayUnavailable || todayChange == 0
            ? context.statusNeutral
            : (todayChange > 0
                ? context.marketPositive
                : context.marketNegative),
        chromeColor: modulePink,
        icon: todayUnavailable || todayChange >= 0
            ? Icons.keyboard_double_arrow_up_rounded
            : Icons.keyboard_double_arrow_down_rounded,
        isPositive: todayUnavailable || todayChange == 0
            ? null
            : todayChange > 0,
        compact: compact,
        glowBorder: glowBorder,
        tooltip: todayUnavailable
            ? 'Day P&L unavailable (missing prior session close)'
            : 'Unrealized profit or loss for the last cash session',
      ),
      PortfolioMetricCard(
        title: 'Total Balance',
        value: _formatCurrency(summary.totalValue),
        subtitle: '${summary.totalAssets} holdings',
        accentColor: modulePink,
        icon: null,
        isPositive: null,
        compact: compact,
        glowBorder: false,
        tooltip: 'Total value of all holdings based on current market price',
      ),
      if (showCost)
        PortfolioMetricCard(
          title: 'Invested Amount',
          value: _formatCurrency(summary.investmentValue),
          subtitle: 'Total Principal',
          accentColor: modulePink,
          icon: null,
          isPositive: null,
          isHighlight: false,
          compact: compact,
          glowBorder: false,
          tooltip: 'Total principal amount invested',
        ),
    ];
  }

  Widget _phoneLayout(List<Widget> cards) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      final right = i + 1 < cards.length ? cards[i + 1] : null;
      if (i > 0) rows.add(const SizedBox(height: 10));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: cards[i]),
            if (right != null) ...[
              const SizedBox(width: 10),
              Expanded(child: right),
            ],
          ],
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _wideLayout(List<Widget> cards) {
    Widget anim(Widget child, int index) {
      if (!animate) return child;
      return child
          .animate()
          .fadeIn(duration: 400.ms, delay: (100 * index).ms)
          .slideY(begin: 0.2, end: 0);
    }

    if (cards.length <= 2) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: anim(cards[i], i)),
          ],
        ],
      );
    }

    final leftGroup = Row(
      children: [
        Expanded(child: anim(cards[0], 0)),
        const SizedBox(width: 12),
        Expanded(child: anim(cards[1], 1)),
      ],
    );
    final rightGroup = Row(
      children: [
        Expanded(child: anim(cards[2], 2)),
        if (cards.length > 3) ...[
          const SizedBox(width: 12),
          Expanded(child: anim(cards[3], 3)),
        ],
      ],
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 14, child: leftGroup),
        const SizedBox(width: 16),
        Expanded(flex: 10, child: rightGroup),
      ],
    );
  }
}

String _formatCurrency(double amount) {
  if (!amount.isFinite) return '₹0';
  final formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  return formatter.format(amount);
}
