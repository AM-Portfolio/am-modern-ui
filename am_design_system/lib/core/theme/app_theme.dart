import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_animations.dart';

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

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color primaryColor,
    required Color textColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = AppTypography.getTextTheme(isDark: isDark);
    
    // Apply Google Fonts Inter globally if desired, overlaying our custom TextTheme
    final fontTheme = GoogleFonts.interTextTheme(textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: 'Inter',
      
      // Color Scheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: surfaceColor,
        onSurface: textColor, // Usually text color
        // Surface Container Highest is often used for input fields / cards in M3
        surfaceContainerHighest: isDark ? AppColors.darkCard : AppColors.lightCard,
        outline: isDark ? Colors.white24 : Colors.grey.shade300,
      ),
      
      // Typography
      textTheme: fontTheme,
      
      // Component Themes
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        elevation: 0,
        margin: EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
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
        color: isDark ? Colors.white10 : Colors.black12,
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
        fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: primaryColor,
            width: 1.5,
          ),
        ),
        hintStyle: fontTheme.bodyMedium?.copyWith(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
      
      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: fontTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
