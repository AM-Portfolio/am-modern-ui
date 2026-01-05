
import 'package:flutter/material.dart';

import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/app_glassmorphism.dart';


/// Glossy gradient button - SIMPLIFIED (no MouseRegion)
class GlossyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final List<Color>? gradientColors;
  final String? colorScheme;
  final IconData? icon;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isLoading;
  final double? width;
  final double? height;

  const GlossyButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.gradientColors,
    this.colorScheme,
    this.icon,
    this.borderRadius = 12.0,
    this.padding,
    this.isLoading = false,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine colors
    List<Color> effectiveColors;
    if (colorScheme != null) {
      effectiveColors = AppGlassmorphism.colorSchemes[colorScheme!] ?? 
                       AppGlassmorphism.colorSchemes['primary']!;
    } else {
      effectiveColors = gradientColors ?? [
        AppColors.primary,
        AppColors.primaryLight,
      ];
    }

    return Container(
      width: width,
      height: height ?? 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: effectiveColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: effectiveColors.first.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Glass button with frosted effect - SIMPLIFIED (no MouseRegion)
class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? borderColor;
  final String? colorScheme;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.icon,
    this.borderColor,
    this.colorScheme,
    this.borderRadius = 12.0,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color effectiveBorderColor;
    if (colorScheme != null) {
      effectiveBorderColor = AppGlassmorphism.colorSchemes[colorScheme!]![0];
    } else {
      effectiveBorderColor = borderColor ?? AppColors.primary;
    }

    return Container(
      decoration: AppGlassmorphism.glassCard(
        borderColor: effectiveBorderColor.withValues(alpha: 0.3),
        borderWidth: 1.5,
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon button with glow effect - SIMPLIFIED (no MouseRegion)
class GlowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;

  const GlowIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        color: effectiveColor,
        iconSize: size,
      ),
    );
  }
}
