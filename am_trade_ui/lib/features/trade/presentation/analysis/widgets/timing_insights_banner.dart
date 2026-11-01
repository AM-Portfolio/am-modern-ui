import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_design_system/am_design_system.dart';

/// Compact trade-count chip — intrinsic width only (never expands).
class TimingInsightsBanner extends StatelessWidget {
  const TimingInsightsBanner({
    super.key,
    required this.tradeCount,
    this.accent,
  });

  final int? tradeCount;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final moduleAccent = accent ??
        ModuleColorProvider.maybeOf(context) ??
        ModuleColors.trade;
    final countLabel = tradeCount == null
        ? '…'
        : NumberFormat.decimalPattern('en_IN').format(tradeCount);

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      constrainedAxis: Axis.vertical,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.cardSurface,
          borderRadius: AppRadii.button,
          border: Border.all(
            color: colors.border.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_rounded, size: 16, color: moduleAccent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$countLabel Trades',
              style: context.text.label(compact: true).copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'In selected period',
              style: context.text.caption(compact: true).copyWith(
                    color: colors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
