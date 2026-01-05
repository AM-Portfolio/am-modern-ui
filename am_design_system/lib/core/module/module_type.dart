import 'package:flutter/material.dart';
import 'module_config.dart';

/// Centralized registry of all application modules
enum ModuleType {
  dashboard,
  market,
  trade,
  portfolio,
  news,
  admin,
  other
}

/// Extension to get semantic configuration for each module type
extension ModuleTypeExtension on ModuleType {
  
  String get title {
    switch (this) {
      case ModuleType.dashboard: return 'Dashboard';
      case ModuleType.market: return 'Market Data';
      case ModuleType.trade: return 'Trade Analysis';
      case ModuleType.portfolio: return 'Portfolio';
      case ModuleType.news: return 'News';
      case ModuleType.admin: return 'Admin';
      case ModuleType.other: return '';
    }
  }

  String get subtitle {
    switch (this) {
      case ModuleType.dashboard: return 'Overview';
      case ModuleType.market: return 'Real-time market insights';
      case ModuleType.trade: return 'Trade execution & analysis';
      case ModuleType.portfolio: return 'Asset management';
      case ModuleType.news: return 'Latest updates';
      case ModuleType.admin: return 'System administration';
      case ModuleType.other: return '';
    }
  }

  IconData get icon {
    switch (this) {
      case ModuleType.dashboard: return Icons.dashboard_rounded;
      case ModuleType.market: return Icons.trending_up_rounded;
      case ModuleType.trade: return Icons.analytics_rounded;
      case ModuleType.portfolio: return Icons.pie_chart_rounded;
      case ModuleType.news: return Icons.newspaper_rounded;
      case ModuleType.admin: return Icons.admin_panel_settings_rounded;
      case ModuleType.other: return Icons.grid_view_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case ModuleType.dashboard: return ModuleColors.dashboard;
      case ModuleType.market: return ModuleColors.market;
      case ModuleType.trade: return ModuleColors.trade;
      case ModuleType.portfolio: return ModuleColors.portfolio;
      case ModuleType.news: return ModuleColors.reports; // Reuse Amber
      case ModuleType.admin: return const Color(0xFFFF6B6B);
      case ModuleType.other: return Colors.blueGrey;
    }
  }
}
