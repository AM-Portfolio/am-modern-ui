import 'package:flutter/material.dart';

/// Configuration for a module
/// Contains metadata and settings for module display and behavior
class ModuleConfig {
  const ModuleConfig({
    required this.moduleId,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.routes = const [],
    this.requiresAuth = true,
    this.isEnabled = true,
    this.showInNavigation = true,
    this.order = 0,
  });

  /// Unique module identifier
  final String moduleId;

  /// Display title (e.g., "Market Data", "Trade Analysis")
  final String title;

  /// Short description (e.g., "Real-time market insights")
  final String subtitle;

  /// Module icon
  final IconData icon;

  /// Accent color for module UI
  final Color accentColor;

  /// Module-specific routes
  final List<ModuleRoute> routes;

  /// Whether authentication is required
  final bool requiresAuth;

  /// Whether module is enabled
  final bool isEnabled;

  /// Whether to show in global navigation
  final bool showInNavigation;

  /// Display order in navigation (lower = first)
  final int order;

  /// Create a copy with modified fields
  ModuleConfig copyWith({
    String? moduleId,
    String? title,
    String? subtitle,
    IconData? icon,
    Color? accentColor,
    List<ModuleRoute>? routes,
    bool? requiresAuth,
    bool? isEnabled,
    bool? showInNavigation,
    int? order,
  }) {
    return ModuleConfig(
      moduleId: moduleId ?? this.moduleId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      routes: routes ?? this.routes,
      requiresAuth: requiresAuth ?? this.requiresAuth,
      isEnabled: isEnabled ?? this.isEnabled,
      showInNavigation: showInNavigation ?? this.showInNavigation,
      order: order ?? this.order,
    );
  }
}

/// Represents a route within a module
class ModuleRoute {
  const ModuleRoute({
    required this.path,
    required this.name,
    required this.builder,
    this.requiresAuth = true,
  });

  /// Route path (e.g., '/holdings', '/analysis')
  final String path;

  /// Display name for route
  final String name;

  /// Widget builder for this route
  final WidgetBuilder builder;

  /// Whether this route requires authentication
  final bool requiresAuth;
}

/// Predefined accent colors for modules
class ModuleColors {
  static const Color market = Color(0xFF06b6d4); // Cyan
  static const Color trade = Color(0xFF8b5cf6); // Purple
  static const Color portfolio = Color(0xFFec4899); // Pink
  static const Color dashboard = Color(0xFF3b82f6); // Blue
  static const Color analytics = Color(0xFF10b981); // Green
  static const Color reports = Color(0xFFf59e0b); // Amber
}
