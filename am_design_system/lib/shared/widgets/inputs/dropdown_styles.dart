import 'package:flutter/material.dart';

/// Common styling constants for all dropdown components
class DropdownStyles {
  const DropdownStyles._();

  // Default dimensions
  static const double defaultHeight = 40;
  static const double defaultFontSize = 13;
  static const double defaultIconSize = 18;
  static const double defaultBorderRadius = 12;
  static const EdgeInsets defaultContentPadding = EdgeInsets.symmetric(
    horizontal: 12,
  );

  // Color opacities
  static const double backgroundOpacity = 0.05;
  static const double borderOpacity = 0.2;
  static const double iconOpacity = 0.7;
  static const double hintOpacity = 0.7;

  /// Get effective primary color from context
  static Color getPrimaryColor(BuildContext context, Color? primaryColor) =>
      primaryColor ?? Theme.of(context).primaryColor;

  /// Get effective background color
  static Color getBackgroundColor(
    BuildContext context, {
    Color? primaryColor,
    Color? backgroundColor,
    bool enabled = true,
  }) {
    if (!enabled) return Colors.grey.shade100;
    if (backgroundColor != null) return backgroundColor;
    final effectivePrimaryColor = getPrimaryColor(context, primaryColor);
    return effectivePrimaryColor.withOpacity(backgroundOpacity);
  }

  /// Get effective border color
  static Color getBorderColor(
    BuildContext context, {
    Color? primaryColor,
    Color? borderColor,
    bool enabled = true,
  }) {
    if (!enabled) return Colors.grey.shade300;
    if (borderColor != null) return borderColor;
    final effectivePrimaryColor = getPrimaryColor(context, primaryColor);
    return effectivePrimaryColor.withOpacity(borderOpacity);
  }

  /// Get effective text color
  static Color getTextColor(
    BuildContext context, {
    Color? primaryColor,
    Color? textColor,
    bool isPlaceholder = false,
    bool enabled = true,
  }) {
    if (!enabled) return Colors.grey.shade500;
    if (textColor != null) return textColor;
    final effectivePrimaryColor = getPrimaryColor(context, primaryColor);
    return isPlaceholder
        ? effectivePrimaryColor.withOpacity(hintOpacity)
        : effectivePrimaryColor;
  }

  /// Get effective icon color
  static Color getIconColor(
    BuildContext context, {
    Color? primaryColor,
    bool enabled = true,
  }) {
    if (!enabled) return Colors.grey.shade400;
    final effectivePrimaryColor = getPrimaryColor(context, primaryColor);
    return effectivePrimaryColor.withOpacity(iconOpacity);
  }

  /// Create standard dropdown decoration
  static BoxDecoration createDecoration(
    BuildContext context, {
    Color? primaryColor,
    Color? backgroundColor,
    Color? borderColor,
    double borderRadius = defaultBorderRadius,
    bool enabled = true,
  }) => BoxDecoration(
    color: getBackgroundColor(
      context,
      primaryColor: primaryColor,
      backgroundColor: backgroundColor,
      enabled: enabled,
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: getBorderColor(
        context,
        primaryColor: primaryColor,
        borderColor: borderColor,
        enabled: enabled,
      ),
    ),
  );

  /// Create standard text style
  static TextStyle createTextStyle(
    BuildContext context, {
    Color? primaryColor,
    Color? textColor,
    double fontSize = defaultFontSize,
    FontWeight fontWeight = FontWeight.w500,
    bool isPlaceholder = false,
    bool enabled = true,
  }) => TextStyle(
    color: getTextColor(
      context,
      primaryColor: primaryColor,
      textColor: textColor,
      isPlaceholder: isPlaceholder,
      enabled: enabled,
    ),
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

/// Predefined dropdown configurations for common use cases
class DropdownConfig {
  const DropdownConfig({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.borderRadius,
    required this.contentPadding,
  });

  final double height;
  final double fontSize;
  final double iconSize;
  final double borderRadius;
  final EdgeInsets contentPadding;

  /// Configuration for compact dropdown (used in selector bars)
  static const compact = DropdownConfig(
    height: 40,
    fontSize: 13,
    iconSize: 18,
    borderRadius: 12,
    contentPadding: EdgeInsets.symmetric(horizontal: 12),
  );

  /// Configuration for form dropdown (used in forms)
  static const form = DropdownConfig(
    height: 48,
    fontSize: 14,
    iconSize: 20,
    borderRadius: 8,
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );

  /// Configuration for large dropdown (used in prominent areas)
  static const large = DropdownConfig(
    height: 56,
    fontSize: 16,
    iconSize: 24,
    borderRadius: 12,
    contentPadding: EdgeInsets.symmetric(horizontal: 16),
  );
}
