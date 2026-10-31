import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_colors_theme.dart';
import 'package:am_design_system/core/theme/app_radii.dart';
import 'package:am_design_system/core/theme/app_spacing.dart';
import 'package:am_design_system/core/theme/app_type_scale.dart';

/// Segmented toggle chip shared across dashboard ranking / chart filters.
///
/// [filled] selected = solid accent + [AppColorsTheme.actionPrimaryFg]
/// (mobile Metrics / filter pills). Default stays soft tint + accent label.
class AmToggleChip extends StatelessWidget {
  const AmToggleChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.compact = false,
    this.filled = false,
    this.accentColor,
    this.borderRadius,
    this.contentPadding,
  });

  final String label;
  final bool selected;

  /// When null, the chip is display-only (no ink / tap).
  final VoidCallback? onTap;
  final bool compact;

  /// Solid selected fill (theme accent + on-primary text) vs soft tint.
  final bool filled;

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
    final unselectedFill = isDark
        ? colors.cardSurface.withValues(alpha: 0.4)
        : colors.surface;
    final Color bg;
    final Color fg;
    final Color borderColor;
    if (selected && filled) {
      bg = accent;
      fg = colors.actionPrimaryFg;
      borderColor = accent;
    } else if (selected) {
      bg = accent.withValues(alpha: 0.18);
      fg = accent;
      borderColor = accent.withValues(alpha: 0.55);
    } else {
      bg = unselectedFill;
      fg = colors.textSecondary;
      borderColor = colors.border.withValues(alpha: 0.6);
    }

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: contentPadding ??
          EdgeInsets.symmetric(
            horizontal: compact ? AppSpacing.sm : AppSpacing.md,
            vertical: compact ? AppSpacing.xs : AppSpacing.sm,
          ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
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
