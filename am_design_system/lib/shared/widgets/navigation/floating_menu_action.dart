import 'package:flutter/material.dart';

/// Data model for a single action in [SidebarFloatingActionMenu].
/// Color must come from ModuleColors or AppColorsTheme — never hardcoded.
class FloatingMenuAction {
  const FloatingMenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
}
