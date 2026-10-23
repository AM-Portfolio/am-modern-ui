import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Compact top-nav CTA: flask tile + "Paper Trading" + "Try" badge.
///
/// Opens the paper desk when tapped. Fits the Dashboard glass pill track.
class PaperTradingNavChip extends StatelessWidget {
  const PaperTradingNavChip({
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final VoidCallback onTap;

  /// Icon + "Try" only (very narrow widths).
  final bool compact;

  static const double _height = AppComponentSizes.iconButtonSize;

  @override
  Widget build(BuildContext context) {
    final accent = ModuleColors.dashboard;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final narrow = compact || MediaQuery.sizeOf(context).width < 440;
    final onAccent = context.colors.actionPrimaryFg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('dashboard-paper-chip'),
        onTap: onTap,
        borderRadius: AppRadii.chip,
        child: Container(
          height: _height,
          padding: EdgeInsets.only(
            left: AppSpacing.xs,
            right: narrow ? AppSpacing.xs : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.chip,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: isDark ? 0.22 : 0.14),
                accent.withValues(alpha: isDark ? 0.18 : 0.10),
              ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.55 : 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isDark ? 0.18 : 0.10),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppTypeScale.h2,
                height: AppTypeScale.h2,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: AppTypeScale.sm,
                  color: onAccent,
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Paper Trading',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: AppTypeScale.sm,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs + AppSpacing.xxs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.28 : 0.20),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.65),
                  ),
                ),
                child: Text(
                  'Try',
                  style: TextStyle(
                    color: isDark ? context.textPrimary : accent,
                    fontSize: AppTypeScale.xs,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
