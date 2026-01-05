/// Card types and configurations for universal calendar display
library;

import 'package:flutter/material.dart';

/// Card display types for different data visualizations
enum CalendarCardType {
  // Trading specific cards
  pnlSummary, // P&L display with win/loss indicators
  tradeMetrics, // Trade count, win rate, avg holding time
  winLossRatio, // Win/loss ratio visualization
  riskReward, // Risk-reward ratio display
  tradeVolume, // Trading volume analysis
  // Portfolio specific cards
  portfolioValue, // Total portfolio value
  assetAllocation, // Asset distribution
  portfolioPerformance, // Performance metrics
  diversification, // Portfolio diversification metrics
  // Analytics cards
  volumeAnalysis, // Trading volume analysis
  sectorPerformance, // Sector-wise performance
  timeAnalysis, // Time-based analysis
  correlation, // Asset correlation analysis
  // General cards
  summary, // General summary card
  custom, // Custom card with user-defined content
  minimal, // Minimal info display
  detailed, // Detailed information card
  heatmap, // Heatmap visualization
}

/// Card size variants
enum CardSizeType {
  small, // Compact single metric (80x60)
  medium, // Standard card size (160x120)
  large, // Expanded card with multiple metrics (240x180)
  full, // Full width card (auto x 200)
}

/// Card layout styles
enum CardLayoutStyle {
  metric, // Single metric with label
  comparison, // Side-by-side comparison
  chart, // Chart/graph display
  list, // List of items
  grid, // Grid layout
  timeline, // Timeline view
  heatmap, // Heatmap visualization
}

/// Visual themes for cards
enum CardTheme {
  neutral, // Standard theme
  success, // Green theme for positive metrics
  warning, // Orange theme for caution
  danger, // Red theme for negative metrics
  info, // Blue theme for informational
  custom, // User-defined theme
}

/// Card configuration class
class CalendarCardConfig {
  const CalendarCardConfig({
    required this.type,
    required this.title,
    this.size = CardSizeType.medium,
    this.layout = CardLayoutStyle.metric,
    this.theme = CardTheme.neutral,
    this.showHeader = true,
    this.showFooter = false,
    this.isInteractive = true,
    this.customColors,
    this.metadata,
  });

  final CalendarCardType type;
  final String title;
  final CardSizeType size;
  final CardLayoutStyle layout;
  final CardTheme theme;
  final bool showHeader;
  final bool showFooter;
  final bool isInteractive;
  final Map<String, Color>? customColors;
  final Map<String, dynamic>? metadata;

  CalendarCardConfig copyWith({
    CalendarCardType? type,
    String? title,
    CardSizeType? size,
    CardLayoutStyle? layout,
    CardTheme? theme,
    bool? showHeader,
    bool? showFooter,
    bool? isInteractive,
    Map<String, Color>? customColors,
    Map<String, dynamic>? metadata,
  }) => CalendarCardConfig(
    type: type ?? this.type,
    title: title ?? this.title,
    size: size ?? this.size,
    layout: layout ?? this.layout,
    theme: theme ?? this.theme,
    showHeader: showHeader ?? this.showHeader,
    showFooter: showFooter ?? this.showFooter,
    isInteractive: isInteractive ?? this.isInteractive,
    customColors: customColors ?? this.customColors,
    metadata: metadata ?? this.metadata,
  );
}

/// Data model for card content
abstract class CardData {
  const CardData({required this.dateKey, this.metadata});

  final String dateKey; // Date identifier (YYYY-MM-DD)
  final Map<String, dynamic>? metadata;
}

/// Trading card data
class TradeCardData extends CardData {
  const TradeCardData({
    required super.dateKey,
    required this.pnl,
    required this.tradeCount,
    required this.winCount,
    required this.lossCount,
    this.totalVolume,
    this.avgHoldingTime,
    this.maxDrawdown,
    this.winRate,
    this.trades = const [],
    super.metadata,
  });

  final double pnl;
  final int tradeCount;
  final int winCount;
  final int lossCount;
  final double? totalVolume;
  final Duration? avgHoldingTime;
  final double? maxDrawdown;
  final double? winRate;
  final List<Map<String, dynamic>> trades;

  double get winLossRatio =>
      lossCount > 0 ? winCount / lossCount : winCount.toDouble();
  double get calculatedWinRate => tradeCount > 0 ? winCount / tradeCount : 0.0;
}

/// Portfolio card data
class PortfolioCardData extends CardData {
  const PortfolioCardData({
    required super.dateKey,
    required this.totalValue,
    required this.dailyChange,
    required this.dailyChangePercent,
    this.assetAllocation,
    this.topPerformers,
    this.worstPerformers,
    super.metadata,
  });

  final double totalValue;
  final double dailyChange;
  final double dailyChangePercent;
  final Map<String, double>? assetAllocation;
  final List<Map<String, dynamic>>? topPerformers;
  final List<Map<String, dynamic>>? worstPerformers;

  bool get isPositive => dailyChange >= 0;
}

/// Custom card data for user-defined content
class CustomCardData extends CardData {
  const CustomCardData({
    required super.dateKey,
    required this.title,
    required this.value,
    this.subtitle,
    this.description,
    this.icon,
    this.color,
    this.customFields,
    super.metadata,
  });

  final String title;
  final String value;
  final String? subtitle;
  final String? description;
  final String? icon;
  final Color? color;
  final Map<String, dynamic>? customFields;
}

/// Calendar card theme enumeration for backward compatibility
enum CalendarCardTheme {
  primary,
  secondary,
  success,
  warning,
  error,
  info,
  neutral,
}
