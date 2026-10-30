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

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: context.text.body(compact: true).copyWith(
            color: colors.textSecondary,
          ),
      floatingLabelBehavior:
          floatingLabel ? FloatingLabelBehavior.always : null,
      floatingLabelStyle: context.text.label(compact: true).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
      prefixIcon: prefixIcon,
      filled: base.filled,
      fillColor: colors.surface.withValues(alpha: 0.45),
      isDense: dense,
      contentPadding: contentPadding ??
          EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: dense ? AppSpacing.sm : AppSpacing.md,
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
    EdgeInsetsGeometry? contentPadding,
  }) {
    final colors = context.colors;
    final borderColor = colors.border.withValues(alpha: 0.4);
    final focusedColor =
        ModuleColorProvider.maybeOf(context) ?? ModuleColors.trade;
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      floatingLabelStyle: context.text.label(compact: true).copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
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
            AppSpacing.sm + AppSpacing.xs,
            AppSpacing.sm + AppSpacing.xs,
            AppSpacing.sm + AppSpacing.xs,
            AppSpacing.sm,
          ),
      isDense: true,
    );
  }
}
