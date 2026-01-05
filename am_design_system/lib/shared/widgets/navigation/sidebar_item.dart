import 'package:flutter/material.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final String route;
  final String? externalAppUrl;  // NEW: For cross-module navigation

  const SidebarItem({
    required this.title,
    required this.icon,
    this.route = '',
    this.externalAppUrl,  // Optional URL for external apps
  });
}
