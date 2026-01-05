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

    if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) {
      return Container(
        width: fullWidth ? double.infinity : null,
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? CupertinoColors.systemBackground,
          borderRadius: borderRadius ?? defaultBorderRadius,
          border: Border.all(color: CupertinoColors.systemGrey5),
        ),
        child: cardContent,
      );
    } else {
      return Card(
        margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
        elevation: elevation ?? defaultElevation,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? defaultBorderRadius,
        ),
        color: backgroundColor,
        child: SizedBox(
          width: fullWidth ? double.infinity : null,
          child: cardContent,
        ),
      );
    }
  }
}
