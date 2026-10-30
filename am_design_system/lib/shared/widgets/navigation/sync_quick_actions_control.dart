import 'package:flutter/material.dart';

import 'floating_menu_action.dart';
import 'global_bottom_nav_visibility.dart';
import 'quick_actions_sheet.dart';

/// Add (+) control that opens the shared quick-actions sheet (sync / add).
///
/// Always icon-only so Dashboard / Trade / Portfolio share one top-nav
/// pattern. Mobile sheets use [showSubtitles] false by default.
class SyncQuickActionsControl extends StatelessWidget {
  const SyncQuickActionsControl({
    required this.accentColor,
    required this.actions,
    this.showSubtitles = false,
    this.iconColor,
    this.iconSize = 22,
    this.icon = Icons.add_rounded,
    super.key,
  });

  final Color accentColor;
  final List<FloatingMenuAction> actions;

  /// Passed to [showQuickActionsSheet]; false for mobile-friendly rows.
  final bool showSubtitles;

  /// Defaults to [accentColor].
  final Color? iconColor;
  final double iconSize;
  final IconData icon;

  void _open(BuildContext context) {
    GlobalBottomNavVisibility.suppressChromeTapReveal = true;
    GlobalBottomNavVisibility.requestHide();
    showQuickActionsSheet(
      context: context,
      triggerColor: accentColor,
      actions: actions,
      showSubtitles: showSubtitles,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sync portfolio',
      onPressed: () => _open(context),
      icon: Icon(
        icon,
        color: iconColor ?? accentColor,
        size: iconSize,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}
