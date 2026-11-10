import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';
import 'glass_card.dart';

/// Summary KPI cards using design-system text/spacing/radii tokens.
class DashboardSummaryWidget extends StatelessWidget {
  final DashboardSummary summary;

  const DashboardSummaryWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gap = SizedBox(width: AppSpacing.md, height: AppSpacing.md);
        final unknown = _costBasisUnknown;
        final mobile = width < 960;
        Widget slot2Built() => unknown
            ? _buildHoldingsCard(context, showIcon: !mobile)
            : _buildInvestedCard(context, showIcon: !mobile);
        Widget slot3Built() => unknown
            ? _buildDayChangeCard(context, showIcon: !mobile)
            : _buildReturnCard(context, showIcon: !mobile);

        if (mobile) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildPortfolioCard(context, isMobile: true),
                    ),
                    gap,
                    Expanded(child: slot2Built()),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: slot3Built()),
                    gap,
                    Expanded(
                      child: _buildPortfoliosCard(context, showIcon: false),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildPortfolioCard(context, isMobile: false)),
              gap,
              Expanded(child: slot2Built()),
              gap,
              Expanded(child: slot3Built()),
              gap,
              Expanded(child: _buildPortfoliosCard(context, showIcon: true)),
            ],
          ),
        );
      },
    );
  }

  /// CDSL/CAS books often have market value only — invested ≈ balance and overall return ≈ 0.
  bool get _costBasisUnknown {
    final value = summary.totalValue;
    if (value <= 0) return false;
    final invested = summary.totalInvested;
    if (invested <= 0) return true;
    return (invested - value).abs() / value < 0.005;
  }

  Widget _buildPortfolioCard(BuildContext context, {required bool isMobile}) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final isPositiveDay = summary.dayChangePercentage >= 0;
    return _KpiTile(
      icon: Icons.account_balance_wallet_rounded,
      showIcon: !isMobile,
      title: 'Total Portfolio Value',
      value: currencyFormat.format(summary.totalValue),
      secondary:
          '${isPositiveDay ? "+" : ""}${summary.dayChangePercentage}% Today',
      secondaryColor: isPositiveDay
          ? context.colors.statusSuccess
          : context.colors.statusError,
      compactValue: isMobile,
    );
  }

  Widget _buildInvestedCard(BuildContext context, {required bool showIcon}) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    return _KpiTile(
      icon: Icons.savings_outlined,
      showIcon: showIcon,
      title: 'Total Invested',
      value: currencyFormat.format(summary.totalInvested),
      secondary: 'Principal Capital',
    );
  }

  Widget _buildReturnCard(BuildContext context, {required bool showIcon}) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    final isPositiveReturn = summary.totalGainLoss >= 0;
    final valueColor = isPositiveReturn
        ? context.colors.statusSuccess
        : context.colors.statusError;
    return _KpiTile(
      icon: Icons.trending_up_rounded,
      showIcon: showIcon,
      title: 'Total Return',
      value:
          '${isPositiveReturn ? "+" : "-"}${currencyFormat.format(summary.totalGainLoss.abs())}',
      valueColor: valueColor,
      secondary:
          '${isPositiveReturn ? "+" : ""}${percentFormat.format(summary.totalGainLossPercentage / 100)}',
      secondaryColor: valueColor,
    );
  }

  Widget _buildHoldingsCard(BuildContext context, {required bool showIcon}) {
    return _KpiTile(
      icon: Icons.layers_rounded,
      showIcon: showIcon,
      title: 'Total Holdings',
      value: summary.totalHoldings.toString(),
      secondary: 'Securities in Portfolio',
    );
  }

  Widget _buildDayChangeCard(BuildContext context, {required bool showIcon}) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final isPositive = summary.dayChange >= 0;
    final valueColor = isPositive
        ? context.colors.statusSuccess
        : context.colors.statusError;
    return _KpiTile(
      icon: Icons.bar_chart_rounded,
      showIcon: showIcon,
      title: '1D Price Change',
      value:
          '${isPositive ? "+" : "-"}${currencyFormat.format(summary.dayChange.abs())}',
      valueColor: valueColor,
      secondary:
          '${isPositive ? "+" : ""}${summary.dayChangePercentage.toStringAsFixed(2)}%',
      secondaryColor: valueColor,
    );
  }

  Widget _buildPortfoliosCard(BuildContext context, {required bool showIcon}) {
    return _KpiTile(
      icon: Icons.layers_outlined,
      showIcon: showIcon,
      title: 'Active Portfolios',
      value: summary.totalPortfolios.toString(),
      secondary: 'Live Strategies',
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.secondary,
    this.showIcon = true,
    this.valueColor,
    this.secondaryColor,
    this.compactValue = false,
  });

  final IconData icon;
  final bool showIcon;
  final String title;
  final String value;
  final String secondary;
  final Color? valueColor;
  final Color? secondaryColor;
  final bool compactValue;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final muted = context.colors.textSecondary;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.label().copyWith(color: muted),
        ),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: context.text.pageTitle(compact: compactValue).copyWith(
                  color: valueColor ?? context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          secondary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.label().copyWith(
                color: secondaryColor ?? muted,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    return AmGlassCard(
      padding: EdgeInsets.all(showIcon ? AppSpacing.md : AppSpacing.sm),
      child: showIcon
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
