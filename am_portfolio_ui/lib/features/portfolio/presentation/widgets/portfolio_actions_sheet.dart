import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Legacy alias — prefer [showQuickActionsSheet].
void showPortfolioActionsSheet({
  required BuildContext context,
  required Color triggerColor,
  required List<FloatingMenuAction> actions,
  bool showSubtitles = true,
}) {
  showQuickActionsSheet(
    context: context,
    triggerColor: triggerColor,
    actions: actions,
    showSubtitles: showSubtitles,
  );
}
