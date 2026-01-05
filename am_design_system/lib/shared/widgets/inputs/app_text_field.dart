import 'package:flutter/material.dart';
import 'package:am_design_system/core/config/design_system_provider.dart';
import 'package:flutter/cupertino.dart';

import '../platform_widget.dart';

/// A cross-platform text input component that adapts to the current platform.
///
/// This widget provides a consistent API while rendering the appropriate
/// native-looking text field based on the platform.
class AppTextField extends PlatformWidget<CupertinoTextField, TextField> {
  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.validator,
    this.autofocus = false,
    this.focusNode,
    this.contentPadding,
    this.prefix,
    this.suffix,
  });
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final FocusNode? focusNode;
  final EdgeInsetsGeometry? contentPadding;
  final Widget? prefix;
  final Widget? suffix;

  @override
  CupertinoTextField buildIosWidget(BuildContext context) {
    final theme = Theme.of(context);

    return CupertinoTextField(
      controller: controller,
      placeholder: hintText,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      autofocus: autofocus,
      focusNode: focusNode,
      padding: contentPadding ?? const EdgeInsets.all(12),
      prefix: prefix != null
          ? Padding(padding: const EdgeInsets.only(left: 12), child: prefix)
          : null,
      suffix: suffix != null
          ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
          : null,
      decoration: BoxDecoration(
        border: Border.all(
          color: errorText != null
              ? CupertinoColors.systemRed
              : CupertinoColors.systemGrey,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  TextField buildMaterialWidget(BuildContext context) {
    final config = DesignSystemProvider.of(context);
    
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        contentPadding: contentPadding ?? const EdgeInsets.all(16),
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.defaultRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.defaultRadius),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(config.defaultRadius),
          borderSide: BorderSide(
            color: config.primaryColor,
            width: 2,
          ),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onEditingComplete: onEditingComplete,
      autofocus: autofocus,
      focusNode: focusNode,
    );
  }

  @override
  Widget buildWebWidget(BuildContext context) {
    // For web, use consistent logic as Material but ensure web-friendly sizing if needed
    return buildMaterialWidget(context);
  }
}
