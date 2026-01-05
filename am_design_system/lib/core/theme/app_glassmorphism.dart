import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Glass morphism and modern UI styles with V2 enhancements
class AppGlassmorphism {
  // Color schemes for V2 (like reference image)
  static const colorSchemes = {
    'primary': [Color(0xFF6C5DD3), Color(0xFF8B7EE0)], // Purple
    'accent': [Color(0xFFFF9F43), Color(0xFFFFB76B)], // Orange/Amber
    'success': [Color(0xFF00B894), Color(0xFF00D2A0)], // Green
    'info': [Color(0xFF00D2D3), Color(0xFF00E8E9)], // Cyan
    'neutral': [Color(0xFF505166), Color(0xFF6B6C7E)], // Gray-Blue
  };

  // Glass effect for cards (backward compatible)
  static BoxDecoration glassCard({
    Color? borderColor,
    double borderWidth = 1.0,
    double blur = 10.0,
    List<Color>? gradientColors,
    double borderRadius = 16.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors ?? [
          Colors.white.withOpacity(0.05),
          Colors.white.withOpacity(0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withOpacity(0.1),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: blur,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          blurRadius: blur / 2,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  // V2: Color-coded glass card with gradient border (like reference image)
  static BoxDecoration colorCodedGlassCard({
    required String colorScheme,
    double borderWidth = 2.0,
    double borderRadius = 20.0,
    bool isGlowing = true,
  }) {
    final colors = colorSchemes[colorScheme] ?? colorSchemes['primary']!;
    
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
        color: Colors.transparent,
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

  // V2: Gradient border card
  static BoxDecoration gradientBorderCard({
    required List<Color> borderColors,
    double borderWidth = 2.0,
    double borderRadius = 20.0,
    bool isGlowing = true,
  }) {
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
        if (isGlowing)
          BoxShadow(
            color: borderColors.first.withOpacity(0.4),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // Metric card style (backward compatible)
  static BoxDecoration metricCard({
    required Color accentColor,
    double elevation = 8.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF2D2D44).withOpacity(0.7),
          const Color(0xFF262636).withOpacity(0.5),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: accentColor.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.2),
          blurRadius: elevation * 2,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: elevation,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // Glossy button style (backward compatible)
  static BoxDecoration glossyButton({
    required List<Color> gradientColors,
    double borderRadius = 12.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: gradientColors.first.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, -2),
        ),
      ],
    );
  }

  // V2: Tech/futuristic background (like reference image)
  static BoxDecoration techBackground() {
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

  // V2: Premium icon container with glass effect
  static BoxDecoration iconGlassContainer({
    required Color color,
    double size = 60.0,
  }) {
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

  // V2: Badge/pill with glass effect
  static BoxDecoration glassPill({
    required Color color,
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

  // Animated gradient (backward compatible)
  static LinearGradient animatedGradient({
    List<Color>? colors,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
  }) {
    return LinearGradient(
      colors: colors ?? [
        const Color(0xFF6C5DD3),
        const Color(0xFFFF9F43),
        const Color(0xFF00D2D3),
      ],
      begin: begin ?? Alignment.topLeft,
      end: end ?? Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
    );
  }

  // Sidebar glass effect (backward compatible)
  static BoxDecoration sidebarGlass({
    double borderWidth = 1.0,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppColors.darkSurface.withOpacity(0.95),
          AppColors.darkCard.withOpacity(0.9),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      border: Border(
        right: BorderSide(
          color: Colors.white.withOpacity(0.1),
          width: borderWidth,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 20,
          offset: const Offset(4, 0),
        ),
      ],
    );
  }
  // Dropdown decoration with glass effect
  static BoxDecoration dropdownDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppColors.darkSurface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}

/// Gradient border painter for custom painting
class GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double borderWidth;
  final double borderRadius;

  GradientBorderPainter({
    required this.colors,
    this.borderWidth = 2.0,
    this.borderRadius = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final gradient = LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
