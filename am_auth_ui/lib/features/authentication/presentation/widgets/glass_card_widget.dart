import 'dart:ui';
import 'package:flutter/material.dart';

/// Glassmorphism card widget for login form
/// Provides a modern glass effect with backdrop blur
class GlassCardWidget extends StatelessWidget {
  final Widget child;
  final bool isCompact;
  final double? maxWidth;
  
  const GlassCardWidget({
    super.key,
    required this.child,
    this.isCompact = false,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderRadius = isCompact ? 20.0 : 24.0;
    final padding = isCompact ? 20.0 : 32.0;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? (isCompact ? double.infinity : 450),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: BoxDecoration(
              color: isDark 
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 30,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
