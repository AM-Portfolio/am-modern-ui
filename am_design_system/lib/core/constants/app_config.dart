import 'package:flutter/material.dart';

/// Application configuration for branding and app-specific settings
class AppConfig {
  // Investment App Configuration
  static const String investmentAppName = 'AM Investment';
  static const IconData investmentAppIcon = Icons.account_balance_wallet_rounded;
  
  // Market Data App Configuration
  static const String marketDataAppName = 'Market Data';
  static const IconData marketDataAppIcon = Icons.show_chart_rounded;
  
  // Portfolio App Configuration
  static const String portfolioAppName = 'Portfolio';
  static const IconData portfolioAppIcon = Icons.pie_chart_rounded;
  
  // AI Bots App Configuration
  static const String aiBotsAppName = 'AI Bots';
  static const IconData aiBotsAppIcon = Icons.smart_toy_rounded;
  
  // Default configuration (can be overridden by each app)
  static String defaultAppName = investmentAppName;
  static IconData defaultAppIcon = investmentAppIcon;
  
  /// Get app name based on context or environment
  static String getAppName() {
    return defaultAppName;
  }
  
  /// Get app icon based on context or environment
  static IconData getAppIcon() {
    return defaultAppIcon;
  }
  
  /// Set default app configuration
  static void setDefaultApp({
    required String appName,
    required IconData appIcon,
  }) {
    defaultAppName = appName;
    defaultAppIcon = appIcon;
  }
}
