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
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
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
  // Compact type for narrow 3-col cards — keeps labels/hints on one line.
  final compactStyle = theme.textTheme.bodySmall?.copyWith(
    fontSize: 12.5,
    height: 1.2,
    color: colors.textSecondary,
  );
  final labelStyle = compactStyle;
  final floatingStyle = compactStyle?.copyWith(
    color: ModuleColors.trade,
    fontWeight: FontWeight.w600,
  );
  // Inner hint when empty/focused (border label alone leaves the box blank).
  final effectiveHint =
      hintText ?? (hasFloatingLabel ? label : null);
  return InputDecoration(
    label: hasFloatingLabel
        ? (required
            ? journalRequiredLabel(context, label!, style: labelStyle)
            : Text(
                label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ))
        : null,
    prefixText: prefixText,
    hintText: effectiveHint,
    hintMaxLines: 1,
    alignLabelWithHint: alignLabelWithHint,
    floatingLabelBehavior: hasFloatingLabel
        ? FloatingLabelBehavior.auto
        : FloatingLabelBehavior.never,
    filled: true,
    // Match JournalFieldDecoration.borderLabel fill so all journal fields look alike.
    fillColor: colors.surface.withValues(alpha: 0.45),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    isDense: true,
    labelStyle: labelStyle,
    floatingLabelStyle: floatingStyle,
    hintStyle: compactStyle?.copyWith(
      color: colors.textTertiary,
      overflow: TextOverflow.ellipsis,
    ),
    errorStyle: theme.textTheme.bodySmall?.copyWith(
      color: colors.statusError,
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
