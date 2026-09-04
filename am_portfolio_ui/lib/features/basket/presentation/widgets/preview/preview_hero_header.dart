import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_responsive.dart';
import 'preview_layout.dart';

class PreviewHeroHeader extends StatelessWidget {
  final BasketOpportunity opportunity;

  const PreviewHeroHeader({
    super.key,
    required this.opportunity,
  });

  Widget _scoreBadge(
    BuildContext context,
    double heldPct,
    double subPct,
    double missingPct,
  ) {
    Widget pill(String label, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        pill('Held ${heldPct.toStringAsFixed(1)}%', context.statusSuccess),
        if (subPct > 0.05)
          pill('Sub ${subPct.toStringAsFixed(1)}%', context.colors.actionPrimaryBg),
        if (missingPct > 0.05)
          pill('Missing ${missingPct.toStringAsFixed(1)}%', context.statusError),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final compact = BasketResponsive.useCompactPreview(context);
    final pagePad = BasketResponsive.previewPagePadding(context);

    final heldPct = opportunity.heldMatchScore ?? opportunity.matchScore;
    final subPct = opportunity.substituteMatchScore ?? 0.0;
    final missingPct = (100.0 - heldPct - subPct).clamp(0.0, 100.0);
    final available =
        opportunity.remainingPortfolioValue ?? opportunity.totalPortfolioValue ?? 0;
    final constituentCount = opportunity.composition.length;

    final titleAndBadges = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          opportunity.etfName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.15,
                fontSize: compact ? 15 : null,
              ),
          maxLines: compact ? 2 : 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        _scoreBadge(context, heldPct, subPct, missingPct),
      ],
    );

    final stats = Column(
      crossAxisAlignment:
          compact ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Available to Invest',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textSecondary,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          formatter.format(available),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Constituents: $constituentCount',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
              ),
        ),
      ],
    );

    return Padding(
      padding: pagePad.copyWith(
        top: PreviewLayout.sectionGap,
        bottom: 0,
      ),
      child: Container(
        constraints: BoxConstraints(
          minHeight: compact ? 0 : 88,
          maxHeight: compact ? double.infinity : PreviewLayout.heroMaxHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: PreviewLayout.cardPadding,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: context.colors.border),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: context.colors.actionPrimaryBg
                              .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          color: context.colors.actionPrimaryBg,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: titleAndBadges),
                    ],
                  ),
                  const SizedBox(height: 10),
                  stats,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color:
                          context.colors.actionPrimaryBg.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: context.colors.actionPrimaryBg,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: titleAndBadges),
                  const SizedBox(width: AppSpacing.md),
                  stats,
                ],
              ),
      ),
    );
  }
}
