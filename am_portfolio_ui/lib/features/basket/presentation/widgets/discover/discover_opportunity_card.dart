import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../../domain/models/basket_opportunity.dart';
import '../../utils/discover_view_state.dart';
import 'discover_layout.dart';
import 'discover_match_ring.dart';
import 'discover_sparkline.dart';

class DiscoverOpportunityCard extends StatelessWidget {
  const DiscoverOpportunityCard({
    super.key,
    required this.opportunity,
    required this.onTap,
    this.compactList = false,
    this.period = DiscoverPerformancePeriod.oneY,
  });

  final BasketOpportunity opportunity;
  final VoidCallback onTap;
  final bool compactList;
  final DiscoverPerformancePeriod period;

  @override
  Widget build(BuildContext context) {
    if (compactList) return _buildListCard(context);
    return _buildGridCard(context);
  }

  Color _retColor(BuildContext context, double? ret) {
    if (ret == null) return context.colors.textSecondary;
    return ret >= 0 ? context.statusSuccess : context.statusError;
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final ret = opportunity.returnForPeriod(period);
    final retColor = _retColor(context, ret);
    final cat = opportunity.categoryLabel?.trim();
    final initial = opportunity.etfName.isNotEmpty
        ? opportunity.etfName[0].toUpperCase()
        : '?';
    final subtitle = DiscoverViewState(period: period).periodReturnSubtitle;

    return SizedBox(
      height: DiscoverLayout.cardHeight,
      child: Material(
        color: context.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: context.dividerColor.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: DiscoverLayout.avatarRadius,
                      backgroundColor:
                          ModuleColors.portfolio.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: ModuleColors.portfolio,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cat != null && cat.isNotEmpty)
                            Text(
                              cat,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: ModuleColors.portfolio,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            opportunity.etfName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              fontSize: 13.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            opportunity.displayTicker,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DiscoverSparkline(
                      data: opportunity.sparklineCloses,
                      color: retColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    DiscoverMatchRing(
                      score: opportunity.matchScore,
                      size: DiscoverLayout.matchRingCard,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Portfolio match',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: context.textSecondary,
                            ),
                          ),
                          Text(
                            '${opportunity.heldCount} held · ${opportunity.missingCount} missing',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DiscoverViewState.formatReturn(ret),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: retColor,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: context.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          if (opportunity.totalItems > 0)
                            '${opportunity.totalItems} constituents',
                          DiscoverViewState.formatRequiredInr(
                            opportunity.minimumInvestmentAmount,
                          ),
                        ].join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: context.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _DiscoverCtaButton(onPressed: onTap, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final accent = ModuleColors.portfolio;
    final ret = opportunity.returnForPeriod(period);
    final retColor = _retColor(context, ret);
    final cat = opportunity.categoryLabel?.trim();
    final score = opportunity.matchScore.clamp(0, 100);
    final subtitle = DiscoverViewState(period: period).periodReturnSubtitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: DiscoverLayout.mobileListGap),
      child: Material(
        color: colors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(color: colors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Padding(
            padding: const EdgeInsets.all(DiscoverLayout.mobileCardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (cat != null && cat.isNotEmpty)
                            Text(
                              cat,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          Text(
                            opportunity.etfName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            opportunity.displayTicker,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    DiscoverSparkline(
                      data: opportunity.sparklineCloses,
                      color: retColor,
                    ),
                  ],
                ),
                const SizedBox(height: DiscoverLayout.mobileListGap),
                Row(
                  children: [
                    DiscoverMatchRing(
                      score: score.toDouble(),
                      size: DiscoverLayout.matchRingMobile,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${opportunity.heldCount} held · ${opportunity.missingCount} missing',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DiscoverViewState.formatReturn(ret),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: retColor,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        [
                          if (opportunity.totalItems > 0)
                            '${opportunity.totalItems} constituents',
                          DiscoverViewState.formatRequiredInr(
                            opportunity.minimumInvestmentAmount,
                          ),
                        ].join(' · '),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _DiscoverCtaButton(onPressed: onTap, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoverCtaButton extends StatelessWidget {
  const _DiscoverCtaButton({
    required this.onPressed,
    this.compact = false,
  });

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ModuleColors.portfolio,
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white70,
        minimumSize: Size(
          compact ? 0 : DiscoverLayout.actionMinWidth,
          DiscoverLayout.ctaMinHeight,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.sm : AppSpacing.md,
          vertical: 0,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: const Text(
        'Preview →',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
