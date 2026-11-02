import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Label with a persistent required asterisk (stays visible when the field has a value).
Widget journalRequiredLabel(
  BuildContext context,
  String text, {
  TextStyle? style,
  bool compact = false,
}) {
  final colors = context.colors;
  final base = style ??
      (compact
          ? context.text.label(compact: true).copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              )
          : Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ));
  return Text.rich(
    TextSpan(
      style: base,
      children: [
        TextSpan(text: text),
        TextSpan(
          text: ' *',
          style: base?.copyWith(
            color: colors.statusError,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Shared input chrome for structured trade workflow steps.
///
/// Prefer [hintText] as the only title (no floating label). Pass [label] only
/// when a floating label is intentionally needed. Set [required] to show a
/// persistent `*` on the floating label.
InputDecoration journalWorkflowDecoration(
  BuildContext context, {
  String? label,
  String? prefixText,
  String? hintText,
  bool alignLabelWithHint = false,
  bool required = false,
}) {
  final colors = context.colors;
  final theme = Theme.of(context);
  final radius = BorderRadius.circular(AppRadii.md);
  final hasFloatingLabel = label != null && label.trim().isNotEmpty;
  final labelStyle = theme.textTheme.bodyMedium?.copyWith(
    color: colors.textSecondary,
  );
  final floatingStyle = theme.textTheme.bodyMedium?.copyWith(
    color: ModuleColors.trade,
    fontWeight: FontWeight.w600,
  );
  return InputDecoration(
    label: hasFloatingLabel
        ? (required
            ? journalRequiredLabel(context, label!, style: labelStyle)
            : Text(label, style: labelStyle))
        : null,
    prefixText: prefixText,
    hintText: hintText,
    alignLabelWithHint: alignLabelWithHint,
    floatingLabelBehavior: hasFloatingLabel
        ? FloatingLabelBehavior.auto
        : FloatingLabelBehavior.never,
    filled: true,
    fillColor: colors.cardSurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: labelStyle,
    floatingLabelStyle: floatingStyle,
    hintStyle: theme.textTheme.bodyMedium?.copyWith(
      color: colors.textTertiary,
    ),
    errorStyle: theme.textTheme.bodySmall?.copyWith(
      color: colors.statusError,
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
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.statusError, width: 1.2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colors.statusError, width: 1.5),
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
