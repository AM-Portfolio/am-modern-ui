import 'package:flutter/material.dart';

/// A customizable reset button widget that provides consistent styling
/// across different layouts and components
class ResetButton extends StatelessWidget {
  const ResetButton({
    required this.onPressed,
    super.key,
    this.style = ResetButtonStyle.icon,
    this.label = 'Reset Filters',
    this.icon = Icons.refresh,
    this.primaryColor,
    this.size = ResetButtonSize.medium,
    this.tooltip = 'Reset Filters',
    this.enabled = true,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Style of the reset button
  final ResetButtonStyle style;

  /// Label text for button styles that show text
  final String label;

  /// Icon to display
  final IconData icon;

  /// Primary color for styling
  final Color? primaryColor;

  /// Size of the button
  final ResetButtonSize size;

  /// Tooltip text
  final String tooltip;

  /// Whether the button is enabled
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectivePrimaryColor =
        primaryColor ?? Theme.of(context).primaryColor;
    final effectiveOnPressed = enabled ? onPressed : null;

    switch (style) {
      case ResetButtonStyle.icon:
        return _buildIconButton(
          context,
          effectivePrimaryColor,
          effectiveOnPressed,
        );
      case ResetButtonStyle.outlined:
        return _buildOutlinedButton(
          context,
          effectivePrimaryColor,
          effectiveOnPressed,
        );
      case ResetButtonStyle.filled:
        return _buildFilledButton(
          context,
          effectivePrimaryColor,
          effectiveOnPressed,
        );
      case ResetButtonStyle.compact:
        return _buildCompactButton(
          context,
          effectivePrimaryColor,
          effectiveOnPressed,
        );
    }
  }

  Widget _buildIconButton(
    BuildContext context,
    Color color,
    VoidCallback? onPressed,
  ) {
    final iconSize = _getIconSize();

    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: iconSize,
      style: IconButton.styleFrom(
        foregroundColor: enabled ? color : Colors.grey.shade400,
      ),
    );
  }

  Widget _buildOutlinedButton(
    BuildContext context,
    Color color,
    VoidCallback? onPressed,
  ) {
    final iconSize = _getIconSize() - 2;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? color : Colors.grey.shade400,
        side: BorderSide(
          color: enabled ? color.withOpacity(0.5) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildFilledButton(
    BuildContext context,
    Color color,
    VoidCallback? onPressed,
  ) {
    final iconSize = _getIconSize() - 2;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildCompactButton(
    BuildContext context,
    Color color,
    VoidCallback? onPressed,
  ) {
    final containerSize = _getContainerSize();
    final iconSize = _getIconSize();

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? color.withOpacity(0.7) : Colors.grey.shade400,
          size: iconSize,
        ),
      ),
    );
  }

  double _getIconSize() {
    switch (size) {
      case ResetButtonSize.small:
        return 16.0;
      case ResetButtonSize.medium:
        return 18.0;
      case ResetButtonSize.large:
        return 20.0;
    }
  }

  double _getContainerSize() {
    switch (size) {
      case ResetButtonSize.small:
        return 32.0;
      case ResetButtonSize.medium:
        return 40.0;
      case ResetButtonSize.large:
        return 48.0;
    }
  }
}

/// Different styles for the reset button
enum ResetButtonStyle {
  /// Icon-only button
  icon,

  /// Outlined button with icon and text
  outlined,

  /// Filled button with icon and text
  filled,

  /// Compact button with border (used in selector bars)
  compact,
}

/// Different sizes for the reset button
enum ResetButtonSize { small, medium, large }
