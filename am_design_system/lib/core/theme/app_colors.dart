import 'package:flutter/material.dart';

/// Central source of truth for all application colors
/// Supports gradients and multicolor definitions
class AppColors {
  // Primary Brand Colors
  static const Color primary = Color(0xFF6C5DD3);
  static const Color primaryDark = Color(0xFF5B4EB5);
  static const Color primaryLight = Color(0xFF8B7EE0);
  
  // Secondary / Accent Colors
  static const Color accent = Color(0xFFFF9F43);
  static const Color accentBlue = Color(0xFF00D2D3);
  static const Color accentPink = Color(0xFFFF6B6B);
  
  // Neutral Colors (Dark Mode)
  static const Color darkBackground = Color(0xFF1E1E2C);
  static const Color darkSurface = Color(0xFF2D2D44);
  static const Color darkCard = Color(0xFF262636);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Colors.white70;
  
  // Neutral Colors (Light Mode)
  static const Color lightBackground = Color(0xFFF5F6FA);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF2D3436);
  static const Color lightTextSecondary = Color(0xFF636E72); // Corrected from Colors.black70 (runtime error?) - no, just standard const

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color error = Color(0xFFFF7675);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF0984E3);
  
  // Gradients
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

  // Multicolor Palette (For dropdowns/tags)
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
  
  static Color getMultiColor(int index) => multiColors[index % multiColors.length];
}
