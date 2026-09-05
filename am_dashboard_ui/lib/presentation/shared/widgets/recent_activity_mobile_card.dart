import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/glass_card.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/recent_activity_formatters.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Compact mobile activity card — letter avatar, invested, performance.
class RecentActivityMobileCard extends StatelessWidget {
  const RecentActivityMobileCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final ActivityItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onSurface = colors.textPrimary;
    final onSurfaceVariant = colors.textSecondary;
    final symbol = (item.symbol ?? item.title).toUpperCase();
    final status = resolveStatus(item);
    final accent = statusAccentColor(context, status);
    final initial = symbolInitial(item);
    final avatarColor = avatarColorForSymbol(symbol);
    final totalInvested = resolveTotalInvested(item);
    final avgAtQty = formatAvgPriceAtQty(item.avgBuyingPrice, item.quantity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: AmGlassCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 4,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LetterAvatar(letter: initial, color: avatarColor),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: context.text.body().copyWith(
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs + 1),
                    Text(
                      formatActivityDate(item.timestamp),
                      style: context.text
                          .caption()
                          .copyWith(color: onSurfaceVariant),
                    ),
                    if (avgAtQty != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 12,
                            color: onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              avgAtQty,
                              style: context.text.caption().copyWith(
                                    color: onSurfaceVariant,
                                    fontSize: AppTypeScale.xs,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm - 2),
              SizedBox(
                width: 88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invested',
                      style: context.text.caption().copyWith(
                            color: onSurfaceVariant,
                            fontSize: AppTypeScale.xs,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      formatCurrencyInr(totalInvested),
                      style: context.text.label().copyWith(
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                width: 1,
                height: 36,
                color: colors.divider.withValues(alpha: 0.5),
              ),
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatReturnPercent(item.profitLossPercent),
                      style: context.text.label().copyWith(
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      formatPnlLine(item.profitLoss),
                      style: context.text.caption().copyWith(
                            color: onSurfaceVariant,
                            fontSize: AppTypeScale.xs,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _StatusChip(label: statusLabel(status), color: accent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.letter, required this.color});

  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: AppRadii.button,
      ),
      child: Text(
        letter,
        style: context.text.sectionTitle(compact: true).copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm - 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Text(
        label,
        style: context.text.caption().copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: AppTypeScale.xs,
            ),
      ),
    );
  }
}
