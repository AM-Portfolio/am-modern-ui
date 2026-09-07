import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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

/// Predefined accent colors for modules.
///
/// Default / system / light / dark / white keep distinct multi-color accents.
/// Brand themes sync every module accent to the theme brand via [applyBrandSync].
class ModuleColors {
  static const Color _market = Color(0xFF06b6d4); // Cyan
  static const Color _trade = Color(0xFF8b5cf6); // Purple
  static const Color _portfolio = Color(0xFFec4899); // Pink
  static const Color _dashboard = Color(0xFF3b82f6); // Blue
  static const Color _analytics = Color(0xFF10b981); // Green
  static const Color _reports = Color(0xFFf59e0b); // Amber
  static const Color _aiChat = Color(0xFF6C5DD3); // Indigo / violet

  static Color market = _market;
  static Color trade = _trade;
  static Color portfolio = _portfolio;
  static Color dashboard = _dashboard;
  static Color analytics = _analytics;
  static Color reports = _reports;
  static Color aiChat = _aiChat;

  /// True after a brand theme sync (skyBlue / imperialGold / cyberNeon).
  static bool isBrandSynced = false;

  /// When [multicolor] is true, restore distinct AM accents; otherwise sync all to [brand].
  static void applyBrandSync({
    required bool multicolor,
    required Color brand,
  }) {
    if (multicolor) {
      market = _market;
      trade = _trade;
      portfolio = _portfolio;
      dashboard = _dashboard;
      analytics = _analytics;
      reports = _reports;
      aiChat = _aiChat;
      isBrandSynced = false;
    } else {
      market = brand;
      trade = brand;
      portfolio = brand;
      dashboard = brand;
      analytics = Color.lerp(brand, Colors.white, 0.12)!;
      reports = Color.lerp(brand, Colors.black, 0.08)!;
      aiChat = brand;
      isBrandSynced = true;
    }
    AppColors.syncModuleAccents(
      market: market,
      trade: trade,
      portfolio: portfolio,
      dashboard: dashboard,
    );
  }
}
