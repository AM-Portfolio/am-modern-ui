import 'package:flutter/material.dart';

/// Central source of truth for all application colors
/// Supports theme-aware colors, module-specific accents, and financial indicators
class AppColors {
  // ============================================================================
  // BRAND COLORS
  // ============================================================================
  
  static const Color primary = Color(0xFF6C5DD3);
  static const Color primaryDark = Color(0xFF5B4EB5);
  static const Color primaryLight = Color(0xFF8B7EE0);
  
  // ============================================================================
  // MODULE ACCENT COLORS
  // ============================================================================
  
  static const Color marketAccent = Color(0xFF06b6d4);      // Cyan
  static const Color portfolioAccent = Color(0xFF6C5DD3);   // Purple
  static const Color tradeAccent = Color(0xFFB06EE0);       // Violet
  static const Color authAccent = Color(0xFF6C63FF);        // Indigo
  static const Color userAccent = Color(0xFF8B7EE0);        // Light Purple
  
  // ============================================================================
  // FINANCIAL STATUS COLORS
  // ============================================================================
  
  static const Color profit = Color(0xFF00B894);            // Green
  static const Color loss = Color(0xFFFF7675);              // Red/Salmon
  static const Color neutral = Color(0xFFFFA502);           // Orange
  static const Color warning = Color(0xFFFDCB6E);           // Yellow
  static const Color info = Color(0xFF0984E3);              // Blue
  static const Color error = Color(0xFFFF7675);             // Red
  static const Color success = Color(0xFF00B894);           // Green
  
  // ============================================================================
  // DARK MODE PALETTE
  // ============================================================================
  
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkBackgroundLight = Color(0xFF16213E);
  static const Color darkBackgroundDeep = Color(0xFF0F3460);
  static const Color darkCard = Color(0xFF2C2C3E);
  static const Color darkCardLight = Color(0xFF3C3C5E);
  static const Color darkSurface = Color(0xFF2D2D44);
  static const Color darkBorder = Color(0xFF3E3E5E);
  static const Color darkDivider = Color(0xFF2E2E3E);
  
  // ============================================================================
  // LIGHT MODE PALETTE
  // ============================================================================
  
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightBackgroundAlt = Color(0xFFF0F3FA);
  static const Color lightCard = Colors.white;
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);
  
  // ============================================================================
  // TEXT COLORS
  // ============================================================================
  
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;
  static const Color textTertiaryDark = Colors.white54;
  static const Color textDisabledDark = Colors.white38;
  
  static const Color textPrimaryLight = Color(0xFF2D3436);
  static const Color textSecondaryLight = Color(0xFF636E72);
  static const Color textTertiaryLight = Color(0xFF95A5A6);
  static const Color textDisabledLight = Color(0xFFBDC3C7);
  
  // ============================================================================
  // ACCENT COLORS (Legacy support)
  // ============================================================================
  
  static const Color accent = Color(0xFFFF9F43);            // Orange
  static const Color accentBlue = Color(0xFF00D2D3);        // Cyan
  static const Color accentPink = Color(0xFFFF6B6B);        // Pink/Red
  
  // ============================================================================
  // GRADIENTS
  // ============================================================================
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white24, Colors.white10],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient darkBackgroundGradient = LinearGradient(
    colors: [darkBackground, darkBackgroundLight, darkBackgroundDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================================================
  // MULTICOLOR PALETTE (For charts, tags, etc.)
  // ============================================================================
  
  static const List<Color> multiColors = [
    Color(0xFF6C5DD3), // Purple
    Color(0xFFFF9F43), // Orange
    Color(0xFF00D2D3), // Cyan
    Color(0xFFFF6B6B), // Red
    Color(0xFF0984E3), // Blue
    Color(0xFF00B894), // Green
    Color(0xFFA29BFE), // Lavender
    Color(0xFFFF7675), // Salmon
  ];
  
  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  
  /// Get multicolor by index (cycles through palette)
  static Color getMultiColor(int index) => multiColors[index % multiColors.length];
  
  /// Get module accent color by module name
  static Color getModuleAccent(String moduleName) {
    switch (moduleName.toLowerCase()) {
      case 'market':
        return marketAccent;
      case 'portfolio':
        return portfolioAccent;
      case 'trade':
        return tradeAccent;
      case 'auth':
        return authAccent;
      case 'user':
        return userAccent;
      default:
        return primary;
    }
  }
  
  /// Get color based on profit/loss value
  static Color profitLossColor(double value) => value >= 0 ? profit : loss;
  
  /// Get color based on win rate percentage
  static Color winRateColor(double rate) => rate >= 50 ? success : warning;
  
  /// Get glassmorphism overlay color for dark theme
  static Color glassOverlayDark(double opacity) => Colors.white.withOpacity(opacity);
  
  /// Get glassmorphism overlay color for light theme
  static Color glassOverlayLight(double opacity) => Colors.black.withOpacity(opacity);
  
  /// Get shadow color for dark theme
  static Color shadowDark(double opacity) => Colors.black.withOpacity(opacity);
  
  /// Get shadow color for light theme
  static Color shadowLight(double opacity) => Colors.black.withOpacity(opacity);
}

