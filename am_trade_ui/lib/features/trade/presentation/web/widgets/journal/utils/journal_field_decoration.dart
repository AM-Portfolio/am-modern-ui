import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Shared [InputDecoration] for journal fields — theme / DS tokens only.
abstract final class JournalFieldDecoration {
  JournalFieldDecoration._();

  static InputDecoration outlined(
    BuildContext context, {
    String? labelText,
    String? hintText,
    bool floatingLabel = false,
    bool dense = false,
    bool required = false,
    Widget? prefixIcon,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final base = theme.inputDecorationTheme;
    final radius = AppRadii.input;
    final borderColor = colors.border.withValues(alpha: 0.4);
    final focusedColor =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final labelStyle = context.text.label(compact: true).copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        );

    return InputDecoration(
      label: labelText == null
          ? null
          : (required
              ? Text.rich(
                  TextSpan(
                    style: labelStyle,
                    children: [
                      TextSpan(text: labelText),
                      TextSpan(
                        text: ' *',
                        style: labelStyle.copyWith(
                          color: colors.statusError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(labelText, style: labelStyle)),
      hintText: hintText,
      hintStyle: context.text.body(compact: true).copyWith(
            color: colors.textSecondary,
          ),
      floatingLabelBehavior:
          floatingLabel ? FloatingLabelBehavior.always : null,
      floatingLabelStyle: labelStyle,
      prefixIcon: prefixIcon,
      filled: base.filled,
      fillColor: colors.surface.withValues(alpha: 0.45),
      isDense: dense,
      contentPadding: contentPadding ??
          EdgeInsets.fromLTRB(
            AppSpacing.md,
            floatingLabel
                ? (dense ? AppSpacing.md : AppSpacing.md + AppSpacing.xs)
                : (dense ? AppSpacing.sm : AppSpacing.md),
            AppSpacing.md,
            floatingLabel
                ? (dense ? AppSpacing.sm + AppSpacing.xs : AppSpacing.md)
                : (dense ? AppSpacing.sm : AppSpacing.md),
          ),
      errorStyle: context.text.caption(compact: true).copyWith(
            color: colors.statusError,
          ),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: focusedColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colors.statusError, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colors.statusError, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(
          color: colors.border.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  /// Border label around a non-text child (checklist, notes, dropdowns).
  static InputDecoration borderLabel(
    BuildContext context, {
    required String label,
    bool required = false,
    EdgeInsetsGeometry? contentPadding,
  }) {
    final colors = context.colors;
    final borderColor = colors.border.withValues(alpha: 0.4);
    final focusedColor =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    final labelStyle = context.text.label(compact: true).copyWith(
          color: colors.textSecondary,
          fontWeight: FontWeight.w600,
        );
    return InputDecoration(
      label: required
          ? Text.rich(
              TextSpan(
                style: labelStyle,
                children: [
                  TextSpan(text: label),
                  TextSpan(
                    text: ' *',
                    style: labelStyle.copyWith(
                      color: colors.statusError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          : Text(label, style: labelStyle),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: labelStyle,
      filled: true,
      fillColor: colors.surface.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: AppRadii.input,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadii.input,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadii.input,
        borderSide: BorderSide(
          color: focusedColor.withValues(alpha: 0.7),
          width: 1.5,
        ),
      ),
      contentPadding: contentPadding ??
          const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
      isDense: true,
    );
  }
}
