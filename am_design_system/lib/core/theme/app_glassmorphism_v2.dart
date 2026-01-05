import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Enhanced glassmorphic styles matching premium architecture diagrams
class AppGlassmorphismV2 {
  // Color schemes for different card types
  static const colorSchemes = {
    'primary': [Color(0xFF6C5DD3), Color(0xFF8B7EE0)], // Purple
    'accent': [Color(0xFFFF9F43), Color(0xFFFFB76B)], // Orange/Amber
    'success': [Color(0xFF00B894), Color(0xFF00D2A0)], // Green
    'info': [Color(0xFF00D2D3), Color(0xFF00E8E9)], // Cyan
    'neutral': [Color(0xFF505166), Color(0xFF6B6C7E)], // Gray-Blue
  };

  /// Premium glass card with gradient colored border (like reference image)
  static BoxDecoration colorCodedGlassCard({
    required String colorScheme,
    double borderWidth = 2.0,
    double borderRadius = 20.0,
    bool isGlowing = true,
    bool isDark = true,
  }) {
    final colors = colorSchemes[colorScheme] ?? colorSchemes['primary']!;
    
    // Google Labs Style (White Mode) - Pastel Fills
    if (!isDark) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [
            colors[0].withOpacity(0.15), // Very light pastel version of the color
            colors[1].withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // No border in Labs style, just soft rounded colored cards
        // But we can add a very subtle border for definition
        border: Border.all(
          color: colors[0].withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          // Soft bloom using the color
          BoxShadow(
            color: colors[0].withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );
    }

    // Dark Mode - Glass Border Style (Existing)
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF1E1E2C).withOpacity(0.7),
          const Color(0xFF262636).withOpacity(0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        width: borderWidth,
        color: Colors.transparent, // Painted by GradientBorderPainter usually, or we can leave transparent here
      ),
      boxShadow: [
        if (isGlowing)
          BoxShadow(
            color: colors[0].withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Gradient border painter for colored borders
  static BoxDecoration gradientBorderCard({
    required List<Color> borderColors,
    double borderWidth = 2.0,
    double borderRadius = 20.0,
    bool isGlowing = true,
    bool isDark = true,
  }) {
    if (!isDark) {
      // White Mode: Labs Style - Soft fill, no heavy borders
      return BoxDecoration(
        color: borderColors.first.withOpacity(0.2), // Visible pastel
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColors.first.withOpacity(0.3),
          width: 1,
        ),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF1E1E2C).withOpacity(0.8),
          const Color(0xFF262636).withOpacity(0.6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        // Colored glow effect (like reference image)
        if (isGlowing)
          BoxShadow(
            color: borderColors.first.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        // Depth shadow
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Tech/futuristic background (like reference image)
  static BoxDecoration techBackground({bool isDark = true}) {
    if (!isDark) {
      return const BoxDecoration(
        color: Colors.white, // Pure white for "Labs" feel
      );
    }
    
    return const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xFF0A0A0F),
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  /// Premium icon container with glass effect
  static BoxDecoration iconGlassContainer({
    required Color color,
    double size = 60.0,
    bool isDark = true,
  }) {
    if (!isDark) {
      // White Mode: Simple soft colored circle
      return BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      );
    }

    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.2),
          blurRadius: 12,
          spreadRadius: 1,
        ),
      ],
    );
  }

  /// Badge/pill with glass effect (like "220 lines" in reference)
  static BoxDecoration glassPill({
    required Color color,
    bool isDark = true,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.2),
        ],
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: color.withOpacity(0.4),
        width: 1,
      ),
    );
  }

  // --- FinDash Design Implementation (White Theme) ---

  /// FinDash Sidebar Background (Subtle Gradient)
  static BoxDecoration finDashSidebarBackground({bool isDark = true}) {
    if (!isDark) {
      return const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF3F4F9), Color(0xFFE8EAED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }
    return techBackground(isDark: true);
  }

  /// FinDash Floating Content Card (White with Soft Shadow)
  static BoxDecoration finDashContentCard({bool isDark = true}) {
    if (!isDark) {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 40,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }
    return BoxDecoration(
      color: const Color(0xFF1E1E2C).withOpacity(0.5),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
    );
  }

  /// FinDash Active Menu Item (White Pop-out Card)
  static BoxDecoration finDashActiveItem({
    required Color accentColor,
    bool isDark = true,
  }) {
    if (!isDark) {
      return BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      );
    }
    return gradientBorderCard(
      borderColors: [accentColor, accentColor.withOpacity(0.6)],
      borderRadius: 16,
      isDark: true,
      isGlowing: true,
    );
  }

  /// FinDash Inactive Menu Item (Clean)
  static BoxDecoration finDashInactiveItem({bool isDark = true}) {
    if (!isDark) {
      return const BoxDecoration(
        color: Colors.transparent,
      );
    }
    return BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  /// FinDash System Tool Pill (Colored Background)
  static BoxDecoration finDashSystemPill({
    required Color color,
    bool isDark = true,
  }) {
    if (!isDark) {
      return BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      );
    }
    return glassPill(color: color, isDark: true);
  }



  /// Glass Prism Container for Global Sidebar
  static Widget glassPrism({
    required Widget child,
    bool isDark = true,
  }) {
    if (!isDark) {
      return Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF8F9FA),
          border: Border(right: BorderSide(color: Color(0xFFE9ECEF))),
        ),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a2e).withOpacity(0.9), // Dark base
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(4, 0), // Shadow to the right
          ),
        ],
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.05),
                  Colors.white.withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
