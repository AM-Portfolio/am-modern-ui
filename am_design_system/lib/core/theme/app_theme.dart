import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_colors_theme.dart';
import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Main Theme Engine for the Application
/// Provides Light and Dark modes with granular control
class AppTheme {
  
  //-- Theme Definitions --//
  
  static ThemeData get darkTheme {
    return _buildTheme(
      brightness: Brightness.dark,
      backgroundColor: AppColors.darkBackground,
      surfaceColor: AppColors.darkSurface,
      primaryColor: AppColors.primary,
      textColor: AppColors.textPrimaryDark,
    );
  }

  static ThemeData get lightTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: AppColors.lightBackground,
      surfaceColor: AppColors.lightSurface,
      primaryColor: AppColors.primary,
      textColor: AppColors.textPrimaryLight,
    );
  }

  static ThemeData get whiteTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: Colors.white,
      surfaceColor: Colors.white,
      primaryColor: AppColors.primary,
      textColor: AppColors.textPrimaryLight,
    );
  }

  static ThemeData get skyBlueTheme {
    return _buildTheme(
      brightness: Brightness.light,
      backgroundColor: const Color(0xFFD1ECF9),
      surfaceColor: const Color(0xFFD1ECF9),
      primaryColor: const Color(0xFF0288D1),
      textColor: AppColors.textPrimaryLight,
      customColors: AppColorsTheme.skyBlue,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
    AppColorsTheme? customColors,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = AppTypography.getTextTheme(isDark: isDark);
    final colors = customColors ?? (isDark ? AppColorsTheme.dark : AppColorsTheme.light);
    
    // Apply Google Fonts Inter globally if desired, overlaying our custom TextTheme
    // final fontTheme = GoogleFonts.interTextTheme(textTheme);
    final fontTheme = textTheme; // Temporarily using default textTheme

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      extensions: <ThemeExtension<dynamic>>[colors],
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: colors.actionPrimaryFg,
        secondary: AppColors.accent,
        onSecondary: colors.actionPrimaryFg,
        error: colors.statusError,
        onError: colors.actionPrimaryFg,
        surface: surfaceColor,
        onSurface: textColor, // Usually text color
        // Surface Container Highest is often used for input fields / cards in M3
        surfaceContainerHighest: colors.cardSurface,
        outline: colors.border,
      ),
      
      // Typography
      textTheme: fontTheme,
      
      // Component Themes
      cardTheme: CardThemeData(
        color: colors.cardSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(
            color: colors.border.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: fontTheme.headlineSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      
      iconTheme: IconThemeData(
        color: textColor,
        size: 24,
      ),
      
      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? colors.cardSurface.withValues(alpha: 0.55)
            : colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(
            color: colors.border.withValues(alpha: 0.45),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.input,
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        hintStyle: fontTheme.bodyMedium?.copyWith(
          color: colors.textDisabled,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: colors.actionPrimaryFg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.input,
          ),
          textStyle: fontTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
