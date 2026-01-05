import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../platform_widget.dart';
import '../../../core/config/design_system_provider.dart';
import '../../../core/utils/common_logger.dart';


/// Button types for different visual styles
enum AppButtonType { primary, secondary, text }

/// A cross-platform button component that adapts to the current platform.
///
/// This widget provides a consistent API while rendering the appropriate
/// native-looking button based on the platform.
class AppButton extends PlatformWidget<Widget, Widget> {
  const AppButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.icon,
    this.padding,
    this.minWidth,
    this.height,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.isOutlined = false,
  });
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;
  final double? height;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final bool isOutlined;

  AppButtonType get _effectiveType {
    if (isOutlined) return AppButtonType.secondary;
    return type;
  }

  @override
  Widget buildIosWidget(BuildContext context) {
    // Get Design Config
    final config = DesignSystemProvider.of(context);
    final effectiveType = _effectiveType;

    // Determine button color based on type or override
    Color? buttonColor;
    if (backgroundColor != null) {
      buttonColor = backgroundColor;
    } else {
      switch (effectiveType) {
        case AppButtonType.primary:
          buttonColor = config.primaryColor;
          break;
        case AppButtonType.secondary:
          buttonColor = Colors.transparent;
          break;
        case AppButtonType.text:
          buttonColor = Colors.transparent;
          break;
      }
    }

    // For text buttons on iOS, use a simple CupertinoButton with no background
    if (effectiveType == AppButtonType.text && backgroundColor == null) {
      return SizedBox(
        width: width,
        child: CupertinoButton(
          padding:
              padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context, textColor ?? CupertinoColors.activeBlue),
        ),
      );
    }

    return SizedBox(
      height: height ?? 48,
      width: width ?? minWidth,
      child: CupertinoButton(
        padding: padding ?? EdgeInsets.zero,
        color: buttonColor,
        disabledColor: CupertinoColors.inactiveGray,
        borderRadius: BorderRadius.all(
          Radius.circular(
            config.defaultRadius / 2,
          ),
        ), // iOS usually has smaller radius
        onPressed: isLoading ? null : onPressed,
        child: _buildChild(
          context,
          textColor ??
              (effectiveType == AppButtonType.primary
                  ? CupertinoColors.white
                  : config.primaryColor),
        ),
      ),
    );
  }

  @override
  Widget buildMaterialWidget(BuildContext context) {
    final config = DesignSystemProvider.of(context);
    final effectiveType = _effectiveType;
    final txtColor =
        textColor ??
        (effectiveType == AppButtonType.primary
            ? Colors.white
            : config.primaryColor);

    // Build the appropriate button based on type
    switch (effectiveType) {
      case AppButtonType.primary:
        return SizedBox(
          height: height ?? 48,
          width: width ?? minWidth,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor ?? config.primaryColor,
              foregroundColor: txtColor,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(config.defaultRadius),
              ),
            ),
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(context, txtColor),
          ),
        );

      case AppButtonType.secondary:
        return SizedBox(
          height: height ?? 48,
          width: width ?? minWidth,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: txtColor,
              side: BorderSide(color: txtColor),
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(config.defaultRadius),
              ),
            ),
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(context, txtColor),
          ),
        );

      case AppButtonType.text:
        return SizedBox(
          width: width, // Apply width constraint to text button too if needed
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: txtColor,
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            ),
            onPressed: isLoading ? null : onPressed,
            child: _buildChild(context, txtColor),
          ),
        );
    }
  }

  @override
  Widget buildWebWidget(BuildContext context) {
    // For web, use Material impl but ensure consistent web styling
    return buildMaterialWidget(context);
  }

  Widget _buildChild(BuildContext context, Color color) {
    final displayColor = textColor ?? color;

    if (isLoading) {
      return _buildLoadingIndicator(context, displayColor);
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: displayColor, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: displayColor,
              fontFamily: DesignSystemProvider.of(context).fontFamily,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        color: displayColor,
        fontFamily: DesignSystemProvider.of(context).fontFamily,
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, Color color) {
    // Use platform-specific loading indicators
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      return const CupertinoActivityIndicator();
    }

    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
