import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shared panel/card decorations for basket flow screens.
/// Mirrors dashboard [AmGlassCard]: solid surface in light, soft glass in dark.
abstract final class BasketPanelStyles {
  BasketPanelStyles._();

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
}
