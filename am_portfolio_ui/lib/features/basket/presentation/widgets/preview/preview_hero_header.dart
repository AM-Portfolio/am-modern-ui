import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';

class PreviewHeroHeader extends StatelessWidget {
  final BasketOpportunity opportunity;

  const PreviewHeroHeader({
    super.key,
    required this.opportunity,
  });

  Color _getScoreColor(double score) {
    if (score >= 75) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getSectorColor(String sector) {
    final int hash = sector.hashCode;
    final List<Color> palette = [
      Colors.blueAccent,
      Colors.indigo,
      Colors.deepPurple,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.green,
      Colors.orange,
      Colors.deepOrange,
    ];
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final topHoldings = List<BasketItem>.from(opportunity.composition)
      ..sort((a, b) => b.etfWeight.compareTo(a.etfWeight));
    
    final formatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final scoreColor = _getScoreColor(opportunity.matchScore);

    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.surface,
            context.colors.scaffoldBackground,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: context.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: context.colors.actionPrimaryBg,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            opportunity.etfName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scoreColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scoreColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            'Match: ${opportunity.matchScore.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Value',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  ),
                  Text(
                    formatter.format(opportunity.totalPortfolioValue ?? 0),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
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
          const SizedBox(height: AppSpacing.xl),
          Text(
            'TOP HOLDINGS',
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
                      border: Border.all(
                        color: context.colors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: _getSectorColor(item.sector),
                          child: Text(
                            item.stockSymbol.isNotEmpty ? item.stockSymbol[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          item.stockSymbol,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                        ),
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
