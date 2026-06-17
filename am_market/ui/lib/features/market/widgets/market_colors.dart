import 'package:flutter/material.dart';

class MarketColors {
  MarketColors._();

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ── Page / scaffold ───────────────────────────────────────
  static Color pageBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F1117) : const Color(0xFFEEF1F6);

  // ── Card surface ──────────────────────────────────────────
  static Color cardSurface(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);

  // ── Drawer / bottom sheet background ─────────────────────
  static Color drawerBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF141824) : const Color(0xFFFFFFFF);

  // ── Borders ───────────────────────────────────────────────
  static Color borderDefault(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2A3347) : const Color(0xFFCBD5E1);

  static Color borderStrong(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2A3347) : const Color(0xFF64748B);

  static Color borderSelected(BuildContext context) =>
      const Color(0xFF00C896); // same in both themes

  // ── Border widths ─────────────────────────────────────────
  static double borderWidth(BuildContext context) =>
      _isDark(context) ? 1.0 : 1.5;

  // ── Text ──────────────────────────────────────────────────
  static Color textPrimary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);

  static Color textMuted(BuildContext context) =>
      _isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static Color textSecondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);

  // ── Timeframe bar ─────────────────────────────────────────
  static Color tfBarBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1F2E) : const Color(0xFFFFFFFF);

  // ── TF pill states ────────────────────────────────────────
  static Color tfPillDefaultText(BuildContext context) =>
      _isDark(context) ? const Color(0xFF64748B) : const Color(0xFF1E293B);

  // Active pill: always #00C896 bg, black text — no change needed

  // ── "All indices" button ──────────────────────────────────
  static Color allIndicesBtnText(BuildContext context) =>
      _isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF1E293B);

  // ── Change indicators ─────────────────────────────────────
  static Color positive(BuildContext context) =>
      _isDark(context) ? const Color(0xFF00C896) : const Color(0xFF00956B);

  static Color negative(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF87171) : const Color(0xFFDC2626);

  static Color positiveBg(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFF00C896).withOpacity(0.15)
          : const Color(0xFF00956B).withOpacity(0.12);

  static Color negativeBg(BuildContext context) =>
      _isDark(context)
          ? const Color(0xFFF87171).withOpacity(0.14)
          : const Color(0xFFDC2626).withOpacity(0.10);

  // ── Selected card glow ────────────────────────────────────
  static List<BoxShadow> selectedGlow(BuildContext context) =>
      _isDark(context)
          ? [
              BoxShadow(
                color: const Color(0xFF00C896).withOpacity(0.12),
                blurRadius: 12,
                spreadRadius: 0,
              )
            ]
          : [
              BoxShadow(
                color: const Color(0xFF00C896).withOpacity(0.12),
                blurRadius: 0,
                spreadRadius: 3,
              )
            ];

  // ── Positive/negative badge (drawer cards) ────────────────
  static Color posBadgeBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0A2A1F) : const Color(0xFFDCFAF0);

  static Color negBadgeBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2A0A0A) : const Color(0xFFFEE2E2);
}
