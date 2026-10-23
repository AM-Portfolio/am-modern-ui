import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:am_design_system/core/theme/app_radii.dart';
import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_type_scale.dart';

/// Segmented toggle chip shared across dashboard ranking / chart filters.
class AmToggleChip extends StatelessWidget {
  const AmToggleChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.compact = false,
    this.accentColor,
    this.borderRadius,
    this.contentPadding,
  });

  final String label;
  final bool selected;

  /// When null, the chip is display-only (no ink / tap).
  final VoidCallback? onTap;
  final bool compact;

  /// When set (e.g. [ModuleColors.portfolio]), overrides theme [actionPrimaryBg].
  final Color? accentColor;

  /// Defaults to [AppRadii.chip] (pill). Pass `AppRadii.xs` for compact header badges.
  final BorderRadius? borderRadius;

  /// Overrides the compact/regular padding when the mock needs a denser chip.
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColorsTheme>() ?? AppColorsTheme.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? colors.actionPrimaryBg;
    final radius = borderRadius ?? AppRadii.chip;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: contentPadding ??
          EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
      decoration: BoxDecoration(
        color: selected
            ? accent.withValues(alpha: 0.18)
            : (isDark
                ? colors.cardSurface.withValues(alpha: 0.4)
                : colors.surface),
        borderRadius: radius,
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
          fontSize: compact ? AppTypeScale.sm : AppTypeScale.md,
        ),
      ),
    );

    if (onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: child,
      ),
    );
  }
}
