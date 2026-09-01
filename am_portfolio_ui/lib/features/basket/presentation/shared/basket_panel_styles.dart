import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shared panel/card decorations for basket flow screens.
abstract final class BasketPanelStyles {
  BasketPanelStyles._();

  static BoxDecoration glassCard(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          context.cardColor.withValues(alpha: context.isDark ? 0.35 : 0.55),
          context.cardColor.withValues(alpha: context.isDark ? 0.15 : 0.25),
        ],
      ),
      border: Border.all(
        color: context.isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.06),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration insetPanel(BuildContext context) {
    return BoxDecoration(
      color: context.backgroundColor,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.borderColor),
    );
  }
}
