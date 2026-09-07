import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:am_design_system/core/theme/app_radii.dart';
import 'package:am_design_system/core/theme/app_spacing.dart';

/// Segmented toggle chip shared across dashboard ranking / chart filters.
class AmToggleChip extends StatelessWidget {
  const AmToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  /// When set (e.g. [ModuleColors.portfolio]), overrides theme [actionPrimaryBg].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? colors.actionPrimaryBg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.chip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.18)
                : (isDark
                    ? colors.cardSurface.withValues(alpha: 0.4)
                    : colors.surface),
            borderRadius: AppRadii.chip,
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.55)
                  : colors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? accent : colors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ),
      ),
    );
  }
}
