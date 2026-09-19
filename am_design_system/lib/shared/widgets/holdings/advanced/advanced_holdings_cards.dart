import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_component_sizes.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_type_scale.dart';
import '../../../../core/theme/color_extensions.dart';
import 'advanced_holding_row.dart';

/// Card grid layout for [AdvancedHoldingsTemplate].
class AdvancedHoldingsCards extends StatelessWidget {
  const AdvancedHoldingsCards({
    required this.holdings,
    required this.isDarkChrome,
    super.key,
    this.onRowTap,
  });

  final List<AdvancedHoldingRow> holdings;
  final bool isDarkChrome;
  final ValueChanged<AdvancedHoldingRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        const maxCardWidth = 360.0;
        final usable = constraints.maxWidth - 24;
        var crossAxisCount = (usable / (maxCardWidth + spacing)).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        final cardWidth =
            (usable - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: SizedBox(
            width: constraints.maxWidth,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (var i = 0; i < holdings.length; i++)
                  SizedBox(
                    width: cardWidth,
                    child: _Card(
                      holding: holdings[i],
                      index: i,
                      isDarkChrome: isDarkChrome,
                      onRowTap: onRowTap,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.holding,
    required this.index,
    required this.isDarkChrome,
    this.onRowTap,
  });

  final AdvancedHoldingRow holding;
  final int index;
  final bool isDarkChrome;
  final ValueChanged<AdvancedHoldingRow>? onRowTap;

  @override
  Widget build(BuildContext context) {
    final isPositive = holding.isProfit;
    final pnlColor =
        isPositive ? context.marketPositive : context.marketNegative;
    final theme = context.colors;
    final titleColor = context.textPrimary;
    final muted = context.textSecondary;
    final avatarLetter = holding.displaySymbol.isNotEmpty
        ? holding.displaySymbol.substring(0, 1).toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRowTap != null ? () => onRowTap!(holding) : null,
        borderRadius: AppRadii.card,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardSurface,
            borderRadius: AppRadii.card,
            border: Border.all(color: theme.border),
            boxShadow: [
              BoxShadow(
                color: context.shadow(isDarkChrome ? 0.35 : 0.08),
                blurRadius: isDarkChrome ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: AppComponentSizes.iconButtonSize,
                      height: AppComponentSizes.iconButtonSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: pnlColor.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: Text(
                        avatarLetter,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypeScale.lg,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            holding.displaySymbol,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppTypeScale.md,
                              color: titleColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (holding.hasDistinctCompanyName) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              holding.displayCompanyName,
                              style: TextStyle(
                                color: muted,
                                fontSize: AppTypeScale.sm,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      holding.displayCurrentValue,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: AppTypeScale.lg,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: pnlColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        border: Border.all(
                          color: pnlColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        holding.displayProfitLossPercentage,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: AppTypeScale.sm,
                          color: pnlColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: theme.divider),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _quickMetric(
                        context,
                        'Avg',
                        holding.displayAvgPrice,
                        titleColor,
                      ),
                    ),
                    _metricDivider(theme.divider),
                    Expanded(
                      child: _quickMetric(
                        context,
                        'LTP',
                        holding.displayCurrentPrice,
                        context.statusWarning,
                      ),
                    ),
                    _metricDivider(theme.divider),
                    Expanded(
                      child: _quickMetric(
                        context,
                        'Qty',
                        holding.displayQuantity,
                        titleColor,
                      ),
                    ),
                    _metricDivider(theme.divider),
                    Expanded(
                      child: _quickMetric(
                        context,
                        'P&L',
                        holding.displayProfitLoss,
                        pnlColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 400.ms);
  }

  Widget _metricDivider(Color color) => Container(
        width: 1,
        height: AppSpacing.xl,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
        color: color,
      );

  Widget _quickMetric(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final muted = context.textSecondary;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: muted,
            fontSize: AppTypeScale.xs,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: AppTypeScale.sm,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
