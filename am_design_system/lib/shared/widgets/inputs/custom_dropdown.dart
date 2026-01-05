import 'package:flutter/material.dart';
import 'dropdown_styles.dart';
import '../../../core/theme/app_glassmorphism.dart';


/// A customizable dropdown widget that provides consistent styling and behavior
/// across the application. Supports icons, hints, and custom styling.
class CustomDropdown<T> extends StatelessWidget {
  const CustomDropdown({
    required this.items,
    required this.onChanged,
    this.value,
    super.key,
    this.hint,
    this.label,
    this.icon,
    this.primaryColor,
    this.height = 40,
    this.isExpanded = true,
    this.fontSize = 13,
    this.iconSize = 18,
    this.borderRadius = 12,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 12),
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.enabled = true,
    this.enableGlass = false,
  });

  /// Current selected value
  final T? value;

  /// List of dropdown items
  final List<DropdownMenuItem<T>> items;

  /// Callback when value changes
  final ValueChanged<T?>? onChanged;

  /// Hint text when no value is selected
  final String? hint;

  /// Label for the dropdown
  final String? label;

  /// Icon to show at the end of dropdown
  final IconData? icon;

  /// Primary color for styling
  final Color? primaryColor;

  /// Height of the dropdown container
  final double height;

  /// Whether dropdown should expand to fill available width
  final bool isExpanded;

  /// Font size for text
  final double fontSize;

  /// Size of the dropdown icon
  final double iconSize;

  /// Border radius for the container
  final double borderRadius;

  /// Padding inside the container
  final EdgeInsets contentPadding;

  /// Background color override
  final Color? backgroundColor;

  /// Border color override
  final Color? borderColor;

  /// Text color override
  final Color? textColor;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Whether to use glassmorphic styling
  final bool enableGlass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimaryColor = primaryColor ?? theme.primaryColor;

    Widget dropdownBody = DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: isExpanded,
        hint:
            hint != null
                ? Text(
                  hint!,
                  style: DropdownStyles.createTextStyle(
                    context,
                    primaryColor: effectivePrimaryColor,
                    fontSize: fontSize,
                    isPlaceholder: true,
                    enabled: enabled,
                  ),
                )
                : null,
        icon: Icon(
          icon ?? Icons.expand_more,
          color: DropdownStyles.getIconColor(
            context,
            primaryColor: effectivePrimaryColor,
            enabled: enabled,
          ),
          size: iconSize,
        ),
        style: DropdownStyles.createTextStyle(
          context,
          primaryColor: effectivePrimaryColor,
          textColor: textColor,
          fontSize: fontSize,
          enabled: enabled,
        ),
        items: enabled ? items : [],
        onChanged: enabled ? onChanged : null,
        dropdownColor: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );

    if (enableGlass) {
      return Container(
        height: height,
        decoration: AppGlassmorphism.dropdownDecoration(context),
        padding: contentPadding,
        child: dropdownBody,
      );
    }

    return Container(
      height: height,
      padding: contentPadding,
      decoration: DropdownStyles.createDecoration(
        context,
        primaryColor: effectivePrimaryColor,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        borderRadius: borderRadius,
        enabled: enabled,
      ),
      child: dropdownBody,
    );
  }
}

/// Extension to help create dropdown items with consistent styling
extension DropdownItemHelper<T> on T {
  /// Creates a dropdown item with icon and text
  DropdownMenuItem<T> toDropdownItem({
    required String text,
    IconData? icon,
    Color? iconColor,
    double iconSize = 14,
    double fontSize = 13,
    bool expandText = true,
  }) => DropdownMenuItem<T>(
    value: this,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: iconSize, color: iconColor),
          const SizedBox(width: 8),
        ],
        if (expandText)
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: fontSize),
              overflow: TextOverflow.ellipsis,
            ),
          )
        else
          Text(text, style: TextStyle(fontSize: fontSize)),
      ],
    ),
  );

  /// Creates a simple dropdown item with just text
  DropdownMenuItem<T> toSimpleDropdownItem({
    required String text,
    double fontSize = 13,
  }) => DropdownMenuItem<T>(
    value: this,
    child: Text(text, style: TextStyle(fontSize: fontSize)),
  );
}
