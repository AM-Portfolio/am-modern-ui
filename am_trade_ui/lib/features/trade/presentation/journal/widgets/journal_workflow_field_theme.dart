import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Shared input chrome for structured trade workflow steps.
InputDecoration journalWorkflowDecoration(
  BuildContext context, {
  required String label,
  String? prefixText,
  String? hintText,
  bool alignLabelWithHint = false,
}) {
  final colors = context.colors;
  final theme = Theme.of(context);
  final radius = BorderRadius.circular(AppRadii.md);
  return InputDecoration(
    labelText: label,
    prefixText: prefixText,
    hintText: hintText,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: colors.cardSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: colors.textSecondary,
    ),
    floatingLabelStyle: theme.textTheme.bodyMedium?.copyWith(
      color: ModuleColors.trade,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: colors.textTertiary,
    ),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.border.withValues(alpha: 0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.border.withValues(alpha: 0.35)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: ModuleColors.trade, width: 1.5),
    ),
  );
}

String humanizeEnum(String raw) {
  return raw
      .split('_')
      .map(
        (w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
      )
      .join(' ');
}
