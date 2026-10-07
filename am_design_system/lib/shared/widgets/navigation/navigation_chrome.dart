import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/app_colors_theme.dart';

/// Shared floating navigation chrome (top pill track + bottom bar).
///
/// Accent colors belong on active icons/indicators only — not on this shell.
/// Fill follows [AppColorsTheme.surface] (same source as web sidebar).
class NavigationChrome {
  NavigationChrome._();

  static const Color darkSurface = AppColors.darkSurface;
  static const double blurSigma = 20;
  static const double surfaceAlpha = 0.85;

  static Color surfaceColor(BuildContext context, {required bool isDark}) {
    final themeSurface =
        Theme.of(context).extension<AppColorsTheme>()?.surface;
    final base = themeSurface ?? (isDark ? darkSurface : Colors.white);
    return base.withValues(alpha: surfaceAlpha);
  }

  static Color borderColor({required bool isDark}) => isDark
      ? Colors.white.withValues(alpha: 0.10)
      : Colors.black.withValues(alpha: 0.08);

  static List<BoxShadow> shadows({required bool isDark}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration decoration(
    BuildContext context, {
    required bool isDark,
    double borderRadius = 28,
  }) =>
      BoxDecoration(
        color: surfaceColor(context, isDark: isDark),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor(isDark: isDark), width: 1.2),
        boxShadow: shadows(isDark: isDark),
      );

  /// Glass shell: blur + [decoration]. Use as the outer chrome wrapper.
  static Widget glass({
    required BuildContext context,
    required bool isDark,
    required Widget child,
    double borderRadius = 28,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: decoration(
            context,
            isDark: isDark,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
