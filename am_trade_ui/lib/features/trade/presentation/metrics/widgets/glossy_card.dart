import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class GlossyCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  const GlossyCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.cardColor;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
        width: width,
        height: height,
        margin: margin,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.circular(20),
                  border: border ?? Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                    width: 1,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardColor.withOpacity(isDark ? 0.7 : 0.9),
                      cardColor.withOpacity(isDark ? 0.4 : 0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
    );
  }
}
