import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Market UI color facade — maps to [AppColorsTheme] semantic tokens.
class MarketColors {
  MarketColors._();

  static AppColorsTheme _c(BuildContext context) =>
      Theme.of(context).extension<AppColorsTheme>() ??
      (Theme.of(context).brightness == Brightness.dark
          ? AppColorsTheme.dark
          : AppColorsTheme.light);

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBg(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  // ── Card surface ──────────────────────────────────────────
  static Color cardSurface(BuildContext context) => _c(context).marketCardSurface;

  static Color drawerBg(BuildContext context) => _c(context).cardSurface;

  // ── Borders ───────────────────────────────────────────────
  static Color borderDefault(BuildContext context) =>
      _c(context).marketBorderDefault;

  static Color borderStrong(BuildContext context) => _c(context).marketBorderDefault;

  static Color borderSelected(BuildContext context) =>
      _c(context).marketPositiveIndicator;

  // ── Border widths ─────────────────────────────────────────
  static double borderWidth(BuildContext context) =>
      _isDark(context) ? 1.0 : 1.5;

  // ── Text ──────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) => _c(context).textPrimary;

  static Color textMuted(BuildContext context) => _c(context).textSecondary;

  static Color textSecondary(BuildContext context) => _c(context).textSecondary;

  // ── Timeframe bar ─────────────────────────────────────────
  static Color tfBarBg(BuildContext context) => _c(context).marketCardSurface;

  static Color tfPillDefaultText(BuildContext context) => _c(context).textSecondary;

  // ── "All indices" button ──────────────────────────────────
  static Color allIndicesBtnText(BuildContext context) =>
      textMuted(context);

  static Color positive(BuildContext context) => _c(context).marketPositiveIndicator;

  static Color negative(BuildContext context) => _c(context).marketNegativeIndicator;

  static Color positiveBg(BuildContext context) => _c(context).marketPositiveBg;

  static Color negativeBg(BuildContext context) => _c(context).marketNegativeBg;

  // ── Selected card glow ────────────────────────────────────
  static List<BoxShadow> selectedGlow(BuildContext context) {
    final glow = _c(context).marketPositiveIndicator.withValues(alpha: 0.12);
    return _isDark(context)
        ? [
            BoxShadow(
              color: glow,
              blurRadius: 12,
              spreadRadius: 0,
            )
          ]
        : [
            BoxShadow(
              color: glow,
              blurRadius: 0,
              spreadRadius: 3,
            )
          ];
  }

  // ── Positive/negative badge (drawer cards) ────────────────
  static Color posBadgeBg(BuildContext context) => _c(context).marketPositiveBg;

  static Color negBadgeBg(BuildContext context) => _c(context).marketNegativeBg;
}
