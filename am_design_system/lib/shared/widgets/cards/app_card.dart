import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:am_design_system/core/config/design_system_provider.dart';


/// A platform-adaptive card widget with consistent styling
class AppCard extends StatelessWidget {
  /// Constructor
  const AppCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.action,
    this.padded = true,
    this.fullWidth = true,
    this.borderRadius,
    this.elevation,
    this.backgroundColor,
    this.margin,
    this.padding,
  });

  /// Child widget to display inside the card
  final Widget child;

  /// Optional title for the card
  final String? title;

  /// Optional subtitle for the card
  final String? subtitle;

  /// Optional action widget to display in the header
  final Widget? action;

  /// Whether to add extra padding inside the card. Ignored if [padding] is provided.
  final bool padded;

  /// Whether the card should take full width
  final bool fullWidth;

  /// Custom border radius
  final BorderRadius? borderRadius;

  /// Custom elevation
  final double? elevation;

  /// Background color of the card
  final Color? backgroundColor;

  /// Custom margin
  final EdgeInsetsGeometry? margin;

  /// Custom padding overrides [padded]
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = DesignSystemProvider.of(context);

    // Platform-specific styling
    final defaultElevation = defaultTargetPlatform == TargetPlatform.iOS
        ? 0.0
        : 1.0;
    
    // Use config radius if available, otherwise fallback
    final radiusValue = config.defaultRadius;
    final defaultBorderRadius = BorderRadius.circular(radiusValue);

    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null || subtitle != null || action != null)
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: subtitle != null ? 8 : 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(title!, style: theme.textTheme.titleMedium),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
          ),
        if (padding != null)
           Padding(padding: padding!, child: child)
        else if (padded && (title != null || subtitle != null))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: child,
          )
        else if (padded)
          Padding(padding: const EdgeInsets.all(16), child: child)
        else
          child,
      ],
    );

    final cardDecoration = BoxDecoration(
      color: backgroundColor ?? (theme.brightness == Brightness.dark 
          ? Colors.black.withValues(alpha: 0.3) 
          : Colors.white.withValues(alpha: 0.3)),
      borderRadius: borderRadius ?? defaultBorderRadius,
      border: Border.all(
        color: (backgroundColor ?? theme.dividerColor).withValues(alpha: 0.1),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return Container(
      width: fullWidth ? double.infinity : null,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: borderRadius ?? defaultBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: cardDecoration,
            child: Material(
              color: Colors.transparent,
              child: cardContent,
            ),
          ),
        ),
      ),
    );
  }
}
