import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';  // Temporarily disabled
import 'app_colors.dart';
import 'app_type_scale.dart';

/// Centralized text styles using Google Fonts (Inter)
class AppTypography {
  static const String fontFamily = 'Inter';

  static TextTheme getTextTheme({required bool isDark}) {
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return TextTheme(
      displayLarge: TextStyle(
        fontSize: AppTypeScale.display,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -1.0,
      ),
      displayMedium: TextStyle(
        fontSize: AppTypeScale.h1,
        fontWeight: FontWeight.bold,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: AppTypeScale.h2,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: AppTypeScale.h3,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: AppTypeScale.h4,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: AppTypeScale.h5,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: AppTypeScale.xl,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: AppTypeScale.base,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: AppTypeScale.md,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: AppTypeScale.xl,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: AppTypeScale.base,
        fontWeight: FontWeight.normal,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: AppTypeScale.sm,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
      ),
      labelLarge: TextStyle(
        fontSize: AppTypeScale.base,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelMedium: TextStyle(
        fontSize: AppTypeScale.sm,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.25,
      ),
      labelSmall: TextStyle(
        fontSize: AppTypeScale.xs,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        letterSpacing: 0.5,
      ),
    );
  }
}
