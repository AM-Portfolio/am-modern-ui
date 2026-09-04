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

        if (width < 960) {
          return Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildPortfolioCard(context, true)),
                    gap,
                    Expanded(child: _buildInvestedCard(context)),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildReturnCard(context)),
                    gap,
                    Expanded(child: _buildPortfoliosCard(context)),
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
              Expanded(child: _buildPortfolioCard(context, false)),
              gap,
              Expanded(child: _buildInvestedCard(context)),
              gap,
              Expanded(child: _buildReturnCard(context)),
              gap,
              Expanded(child: _buildPortfoliosCard(context)),
            ],
          ),
        );
      },
    );
  }

  TextStyle _labelStyle(BuildContext context) =>
      context.text.label().copyWith(color: context.colors.textSecondary);

  TextStyle _valueStyle(BuildContext context, {bool compact = false}) =>
      context.text
          .pageTitle(compact: compact)
          .copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          );

  Widget _buildPortfolioCard(BuildContext context, bool isMobile) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final isPositiveDay = summary.dayChangePercentage >= 0;
    final isDark = context.isDark;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Total Portfolio Value', style: _labelStyle(context)),
        const SizedBox(height: AppSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            currencyFormat.format(summary.totalValue),
            style: _valueStyle(context, compact: isMobile),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${isPositiveDay ? "+" : ""}${summary.dayChangePercentage}% Today',
          style: context.text.label().copyWith(
                color: isPositiveDay
                    ? context.colors.statusSuccess
                    : context.colors.statusError,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );

    if (!isDark) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.colors.actionPrimaryBg,
          borderRadius: AppRadii.dialog,
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.2),
          ),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: context.colors.actionPrimaryFg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Portfolio Value',
                style: context.text.label().copyWith(
                      color: context.colors.actionPrimaryFg
                          .withValues(alpha: 0.85),
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  currencyFormat.format(summary.totalValue),
                  style: context.text
                      .pageTitle(compact: isMobile)
                      .copyWith(
                        color: context.colors.actionPrimaryFg,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${isPositiveDay ? "+" : ""}${summary.dayChangePercentage}% Today',
                style: context.text.label().copyWith(
                      color: context.colors.actionPrimaryFg,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return AmGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: content,
    );
  }

  Widget _buildInvestedCard(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);

    return AmGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total Invested', style: _labelStyle(context)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currencyFormat.format(summary.totalInvested),
              style: _valueStyle(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Principal Capital',
            style: context.text
                .caption()
                .copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final percentFormat = NumberFormat.decimalPercentPattern(decimalDigits: 2);
    final isPositiveReturn = summary.totalGainLoss >= 0;
    final valueColor = isPositiveReturn
        ? context.colors.statusSuccess
        : context.colors.statusError;

    return AmGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Total Return', style: _labelStyle(context)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${isPositiveReturn ? "+" : "-"}${currencyFormat.format(summary.totalGainLoss.abs())}',
              style: _valueStyle(context).copyWith(color: valueColor),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${isPositiveReturn ? "+" : ""}${percentFormat.format(summary.totalGainLossPercentage / 100)}',
            style: context.text.label().copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfoliosCard(BuildContext context) {
    return AmGlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Active Portfolios', style: _labelStyle(context)),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              summary.totalPortfolios.toString(),
              style: _valueStyle(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Live Strategies',
            style: context.text
                .caption()
                .copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
