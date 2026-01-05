import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../calendar_types.dart';
import '../models/calendar_color_mode.dart';

/// Service for calculating calendar colors based on different modes and themes
class CalendarColorService {
  CalendarColorService({this.colorMode = CalendarColorMode.winLoss});

  final CalendarColorMode colorMode;

  /// Get color for a day based on the current color mode
  Color getDayColor(CalendarDayData dayData, {double opacity = 1.0}) {
    switch (colorMode) {
      case CalendarColorMode.winLoss:
        return _getWinLossColor(dayData, opacity: opacity);
      case CalendarColorMode.profitIntensity:
        return _getProfitIntensityColor(dayData, opacity: opacity);
    }
  }

  /// Get background color for a month card based on total P&L
  Color getMonthBackgroundColor(Map<String, dynamic> stats, {double opacity = 0.03}) {
    if (colorMode == CalendarColorMode.winLoss) {
      // For win/loss mode, use prominent color based on total P&L
      final totalPnL = stats['totalPnL'] as double;
      if (totalPnL > 0) {
        return Colors.green.withOpacity(0.15); // More visible green for profitable months
      } else if (totalPnL < 0) {
        return Colors.red.withOpacity(0.15); // More visible red for losing months
      }
      return Colors.grey.withOpacity(0.05); // Subtle gray for breakeven
    } else {
      // For profit intensity mode, use P&L
      final totalPnL = stats['totalPnL'] as double;
      if (totalPnL == 0) return Colors.transparent;

      final baseColor = totalPnL > 0 ? Colors.green : Colors.red;
      return baseColor.withOpacity(opacity);
    }
  }

  /// Get border color for month card
  Color getMonthBorderColor(Map<String, dynamic> stats, {double opacity = 0.1}) {
    if (colorMode == CalendarColorMode.winLoss) {
      // For win/loss mode, use prominent border based on total P&L
      final totalPnL = stats['totalPnL'] as double;
      if (totalPnL > 0) {
        return Colors.green.withOpacity(0.4); // More visible green border
      } else if (totalPnL < 0) {
        return Colors.red.withOpacity(0.4); // More visible red border
      }
      return Colors.grey.withOpacity(0.2); // Subtle gray for breakeven
    } else {
      final totalPnL = stats['totalPnL'] as double;
      if (totalPnL == 0) return Colors.grey.withOpacity(opacity);

      final baseColor = totalPnL > 0 ? Colors.green : Colors.red;
      return baseColor.withOpacity(opacity);
    }
  }

  /// Win/Loss color mode - simple green/red/gray
  Color _getWinLossColor(CalendarDayData dayData, {double opacity = 1.0}) {
    switch (dayData.status) {
      case TradeDayStatus.win:
        return Colors.green.withOpacity(opacity);
      case TradeDayStatus.loss:
        return Colors.red.withOpacity(opacity);
      case TradeDayStatus.breakeven:
        return Colors.grey.withOpacity(opacity);
      case TradeDayStatus.noTrades:
        return Colors.transparent;
    }
  }

  /// Profit intensity color mode - color darkness based on P&L amount
  Color _getProfitIntensityColor(CalendarDayData dayData, {double opacity = 1.0}) {
    if (!dayData.hasTrades || dayData.pnl == 0) {
      return Colors.grey.withOpacity(opacity * 0.3);
    }

    final pnl = dayData.pnl;
    final isProfit = pnl > 0;

    // Calculate intensity (0.0 to 1.0)
    // Using logarithmic scale for better visual distribution
    final absAmount = pnl.abs();
    final intensity = _calculateIntensity(absAmount);

    // Base colors
    final baseColor = isProfit ? Colors.green : Colors.red;

    // Create color with varying intensity
    return _adjustColorIntensity(baseColor, intensity, opacity: opacity);
  }

  /// Calculate intensity based on amount (logarithmic scale)
  double _calculateIntensity(double amount) {
    // Define thresholds for intensity levels
    const minAmount = 10.0; // Minimum amount for visible color
    const maxAmount = 1000.0; // Amount for maximum intensity

    if (amount <= minAmount) return 0.3; // Minimum visibility
    if (amount >= maxAmount) return 1.0; // Maximum intensity

    // Logarithmic scale for better distribution
    final normalizedLog = math.log(amount) / math.log(maxAmount);
    return math.min(0.3 + (normalizedLog * 0.7), 1.0);
  }

  /// Adjust color intensity
  Color _adjustColorIntensity(Color baseColor, double intensity, {double opacity = 1.0}) {
    // For higher intensity, use darker/more saturated color
    // For lower intensity, use lighter/less saturated color

    final hsl = HSLColor.fromColor(baseColor);

    // Adjust lightness: lower intensity = lighter color
    final adjustedLightness = 0.5 - (intensity * 0.2); // Range: 0.3 to 0.5

    // Adjust saturation: higher intensity = more saturated
    final adjustedSaturation = 0.4 + (intensity * 0.4); // Range: 0.4 to 0.8

    final adjustedColor = hsl.withLightness(adjustedLightness).withSaturation(adjustedSaturation).toColor();

    return adjustedColor.withOpacity(opacity);
  }

  /// Get text color that contrasts well with the day color
  Color getTextColor(CalendarDayData dayData) {
    if (!dayData.hasTrades) {
      return Colors.grey.shade600;
    }

    if (colorMode == CalendarColorMode.profitIntensity) {
      final pnl = dayData.pnl;
      final intensity = _calculateIntensity(pnl.abs());

      // Use white text for high intensity, dark text for low intensity
      return intensity > 0.6 ? Colors.white : Colors.black87;
    }

    // Win/loss mode - use color-appropriate text
    switch (dayData.status) {
      case TradeDayStatus.win:
        return Colors.green.shade900;
      case TradeDayStatus.loss:
        return Colors.red.shade900;
      case TradeDayStatus.breakeven:
        return Colors.grey.shade800;
      case TradeDayStatus.noTrades:
        return Colors.grey.shade600;
    }
  }

  /// Get border color for day cell
  Color getBorderColor(CalendarDayData dayData, {double opacity = 0.6}) {
    if (!dayData.hasTrades) {
      return Colors.grey.withOpacity(0.2);
    }

    return getDayColor(dayData, opacity: opacity);
  }
}
