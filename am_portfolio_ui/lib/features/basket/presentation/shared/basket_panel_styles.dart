import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shared panel/card decorations for basket flow screens.
/// Mirrors dashboard [AmGlassCard]: solid surface in light, soft glass in dark.
abstract final class BasketPanelStyles {
  BasketPanelStyles._();

  /// Portfolio-module brand accent (never theme purple).
  static const Color accent = ModuleColors.portfolio;

  static BoxDecoration glassCard(BuildContext context) {
    final colors = context.colors;
    if (!context.isDark) {
      return BoxDecoration(
        color: colors.cardSurface,
        borderRadius: AppRadii.card,
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: context.shadow(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: context.glassOverlay(0.04),
      borderRadius: AppRadii.card,
      border: Border.all(color: context.glassOverlay(0.08)),
      boxShadow: [
        BoxShadow(
          color: context.shadow(0.2),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration insetPanel(BuildContext context) {
    return BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadii.md),
      border: Border.all(color: context.colors.border),
    );
  }

  /// Remap theme purple → portfolio pink for chips, segmented, and primary CTAs.
  static ThemeData accentTheme(BuildContext context) {
    final base = Theme.of(context);
    final soft = accent.withValues(alpha: 0.18);
    final appColors = context.colors.copyWith(actionPrimaryBg: accent);
    return base.copyWith(
      primaryColor: accent,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        onPrimary: Colors.white,
        secondaryContainer: soft,
        onSecondaryContainer: accent,
        primaryContainer: soft,
        onPrimaryContainer: accent,
      ),
      extensions: [
        ...base.extensions.values.where((e) => e is! AppColorsTheme),
        appColors,
      ],
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: soft,
        checkmarkColor: accent,
        secondarySelectedColor: soft,
        labelStyle: base.textTheme.labelMedium?.copyWith(
          color: context.colors.textSecondary,
        ),
        secondaryLabelStyle: base.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: context.colors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          selectedBackgroundColor: soft,
          selectedForegroundColor: accent,
          foregroundColor: context.colors.textSecondary,
          backgroundColor: context.colors.cardSurface,
          side: BorderSide(color: context.colors.border),
        ),
      ),
    );
  }
}
