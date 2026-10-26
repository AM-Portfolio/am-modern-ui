import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

/// Shared input chrome for structured trade workflow steps.
InputDecoration journalWorkflowDecoration(
  BuildContext context, {
  required String label,
  String? prefixText,
  bool alignLabelWithHint = false,
}) {
  final colors = context.colors;
  final radius = BorderRadius.circular(10);
  return InputDecoration(
    labelText: label,
    prefixText: prefixText,
    alignLabelWithHint: alignLabelWithHint,
    filled: true,
    fillColor: colors.cardSurface.withValues(alpha: 0.55),
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
