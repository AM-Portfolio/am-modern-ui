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
        borderRadius: BorderRadius.circular(12),
        child: AmGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LetterAvatar(letter: initial, color: avatarColor),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      symbol,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatActivityDate(item.timestamp),
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 11,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (avgAtQty != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 12,
                            color: onSurfaceVariant.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              avgAtQty,
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontSize: 10,
                                fontFamily: 'Inter',
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
              const SizedBox(width: 6),
              SizedBox(
                width: 88,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Invested',
                      style: TextStyle(
                        color: onSurfaceVariant,
                        fontSize: 9,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatCurrencyInr(totalInvested),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: onSurface,
                        fontFamily: 'Inter',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: colors.border.withValues(alpha: 0.35),
              ),
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatusBadge(label: statusLabel(status), color: accent),
                    const SizedBox(height: 4),
                    Text(
                      formatReturnPercent(item.profitLossPercent),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: accent,
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPnlLine(item.profitLoss),
                      style: TextStyle(
                        fontSize: 9,
                        color: accent.withValues(alpha: 0.9),
                        fontFamily: 'Inter',
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colors.actionPrimaryBg,
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
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: color,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 9,
          fontFamily: 'Inter',
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
