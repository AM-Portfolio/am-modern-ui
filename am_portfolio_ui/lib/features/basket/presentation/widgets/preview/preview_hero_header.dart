import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/basket_opportunity.dart';
import '../../utils/basket_responsive.dart';
import '../coverage_bar_widget.dart';
import 'preview_layout.dart';

class PreviewHeroHeader extends StatelessWidget {
  final BasketOpportunity opportunity;

  const PreviewHeroHeader({
    super.key,
    required this.opportunity,
  });

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

    return Padding(
      padding: pagePad.copyWith(
        top: PreviewLayout.sectionGap,
        bottom: 0,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: PreviewLayout.cardPadding,
          vertical: compact ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: context.colors.cardSurface,
          borderRadius: AppRadii.card,
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color:
                        ModuleColors.portfolio.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome,
                    color: ModuleColors.portfolio,
                    size: compact ? 18 : 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    opportunity.etfName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          fontSize: compact ? 15 : null,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(available),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        '$constituentCount stocks',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: context.colors.textTertiary,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            CoverageBarWidget(
              heldPct: heldPct,
              substitutePct: subPct,
              missingPct: missingPct,
              compact: compact,
            ),
            if (compact) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Avail ',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: context.colors.textSecondary,
                                    ),
                          ),
                          TextSpan(
                            text: formatter.format(available),
                            style:
                                Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$constituentCount stocks',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
