import 'dart:ui';
import 'package:flutter/material.dart';

/// Theme extension for Market UI — holds all color tokens used across
/// market widgets. Registered locally in am_market/ui main.dart via
/// ThemeData.copyWith(), so no other module is touched.
@immutable
class MarketThemeExtension extends ThemeExtension<MarketThemeExtension> {
  final Color background;
  final Color surface;
  final Color drawerBg;
  final Color border;
  final Color borderHover;
  final Color textPrimary;
  final Color textMuted;
  final Color textSecondary;
  final Color accent;
  final Color accentText;
  final Color positive;
  final Color negative;
  final Color posBadgeBg;
  final Color negBadgeBg;
  final Color blue;

  const MarketThemeExtension({
    required this.background,
    required this.surface,
    required this.drawerBg,
    required this.border,
    required this.borderHover,
    required this.textPrimary,
    required this.textMuted,
    required this.textSecondary,
    required this.accent,
    required this.accentText,
    required this.positive,
    required this.negative,
    required this.posBadgeBg,
    required this.negBadgeBg,
    required this.blue,
  });

  // ---------------------------------------------------------------------------
  // Dark palette — matches the original MarketColors exactly
  // ---------------------------------------------------------------------------
  factory MarketThemeExtension.dark() => const MarketThemeExtension(
        background: Color(0xFF0F1117),
        surface: Color(0xFF1A1F2E),
        drawerBg: Color(0xFF141824),
        border: Color(0xFF2A3347),
        borderHover: Color(0xFF3A4A63),
        textPrimary: Color(0xFFE2E8F0),
        textMuted: Color(0xFF64748B),
        textSecondary: Color(0xFF94A3B8),
        accent: Color(0xFF00C896),
        accentText: Color(0xFF000000),
        positive: Color(0xFF00C896),
        negative: Color(0xFFF87171),
        posBadgeBg: Color(0xFF0A2A1F),
        negBadgeBg: Color(0xFF2A0A0A),
        blue: Color(0xFF378ADD),
      );

  // ---------------------------------------------------------------------------
  // Light palette — designed to match the dark palette's structure in a
  // clean, high-contrast light mode
  // ---------------------------------------------------------------------------
  factory MarketThemeExtension.light() => const MarketThemeExtension(
        background: Color(0xFFF0F2F7),
        surface: Color(0xFFFFFFFF),
        drawerBg: Color(0xFFF8FAFC),
        border: Color(0xFFCBD5E1),
        borderHover: Color(0xFF94A3B8),
        textPrimary: Color(0xFF1E293B),
        textMuted: Color(0xFF64748B),
        textSecondary: Color(0xFF475569),
        accent: Color(0xFF00C896),
        accentText: Color(0xFFFFFFFF),
        positive: Color(0xFF059669),
        negative: Color(0xFFDC2626),
        posBadgeBg: Color(0xFFD1FAE5),
        negBadgeBg: Color(0xFFFEE2E2),
        blue: Color(0xFF2563EB),
      );

  // ---------------------------------------------------------------------------
  // ThemeExtension overrides
  // ---------------------------------------------------------------------------
  @override
  MarketThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? drawerBg,
    Color? border,
    Color? borderHover,
    Color? textPrimary,
    Color? textMuted,
    Color? textSecondary,
    Color? accent,
    Color? accentText,
    Color? positive,
    Color? negative,
    Color? posBadgeBg,
    Color? negBadgeBg,
    Color? blue,
  }) {
    return MarketThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      drawerBg: drawerBg ?? this.drawerBg,
      border: border ?? this.border,
      borderHover: borderHover ?? this.borderHover,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textSecondary: textSecondary ?? this.textSecondary,
      accent: accent ?? this.accent,
      accentText: accentText ?? this.accentText,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
      posBadgeBg: posBadgeBg ?? this.posBadgeBg,
      negBadgeBg: negBadgeBg ?? this.negBadgeBg,
      blue: blue ?? this.blue,
    );
  }

  @override
  ThemeExtension<MarketThemeExtension> lerp(
    covariant ThemeExtension<MarketThemeExtension>? other,
    double t,
  ) {
    if (other is! MarketThemeExtension) return this;
    return MarketThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      drawerBg: Color.lerp(drawerBg, other.drawerBg, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderHover: Color.lerp(borderHover, other.borderHover, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      posBadgeBg: Color.lerp(posBadgeBg, other.posBadgeBg, t)!,
      negBadgeBg: Color.lerp(negBadgeBg, other.negBadgeBg, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
    );
  }
}

/// Convenience extension on BuildContext so any widget can write:
///   final mt = context.marketTheme;
extension MarketThemeContext on BuildContext {
  MarketThemeExtension get marketTheme =>
      Theme.of(this).extension<MarketThemeExtension>() ??
      MarketThemeExtension.dark(); // safe fallback — never crashes
}
