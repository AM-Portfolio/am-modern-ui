import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_responsive.dart';

class PreviewHeroHeader extends StatelessWidget {
  final BasketOpportunity opportunity;

  const PreviewHeroHeader({
    super.key,
    required this.opportunity,
  });

  Color _getScoreColor(BuildContext context, double score) {
    if (score >= 75) return context.statusSuccess;
    if (score >= 50) return context.statusWarning;
    return context.statusError;
  }

  Color _getSectorColor(String sector) {
    final int hash = sector.hashCode;
    return AppColors.getMultiColor(hash.abs());
  }

  Widget _scoreBadge(
    BuildContext context,
    Color scoreColor,
    double heldPct,
    double subPct,
    double missingPct,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scoreColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: [
          Text(
            'Held: ${heldPct.toStringAsFixed(1)}%',
            style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
          if (subPct > 0)
            Text(
              'Sub: ${subPct.toStringAsFixed(1)}%',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          if (missingPct > 0)
            Text(
              'Missing: ${missingPct.toStringAsFixed(1)}%',
              style: TextStyle(color: context.statusError, fontWeight: FontWeight.bold, fontSize: 11),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topHoldings = List<BasketItem>.from(opportunity.composition)
      ..sort((a, b) => b.etfWeight.compareTo(a.etfWeight));

    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final scoreColor = _getScoreColor(context, opportunity.matchScore);
    final compact = BasketResponsive.useCompactPreview(context);

    final heldPct = opportunity.heldMatchScore ?? opportunity.matchScore;
    final subPct = opportunity.substituteMatchScore ?? 0.0;
    final missingPct = (100.0 - heldPct - subPct).clamp(0.0, 100.0);
    final available =
        opportunity.remainingPortfolioValue ?? opportunity.totalPortfolioValue ?? 0;

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.md : AppSpacing.xl,
        compact ? AppSpacing.lg : AppSpacing.xxl,
        compact ? AppSpacing.md : AppSpacing.xl,
        compact ? AppSpacing.md : AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colors.surface, context.colors.scaffoldBackground],
        ),
        border: Border(bottom: BorderSide(color: context.colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: context.colors.actionPrimaryBg, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.etfName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        opportunity.etfIsin,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            _scoreBadge(context, scoreColor, heldPct, subPct, missingPct),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available to Invest',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                            )),
                    Text(formatter.format(available),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                  ],
                ),
                Text(
                  '${opportunity.composition.length} constituents',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                ),
              ],
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.auto_awesome, color: context.colors.actionPrimaryBg, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.etfName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _scoreBadge(context, scoreColor, heldPct, subPct, missingPct),
                      const SizedBox(height: 2),
                      Text(
                        opportunity.etfIsin,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Replicate this ETF as a custom basket',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Available to Invest',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                            )),
                    Text(formatter.format(available),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Constituents: ${opportunity.composition.length}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: context.colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'ETF CONSTITUENTS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.colors.textTertiary,
                  letterSpacing: 1.2,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: topHoldings.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: _getSectorColor(item.sector),
                          child: Text(
                            item.stockSymbol.isNotEmpty ? item.stockSymbol[0].toUpperCase() : '?',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textPrimaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(item.stockSymbol,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                )),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${item.etfWeight.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
