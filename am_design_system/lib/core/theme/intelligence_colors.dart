import 'package:flutter/material.dart';

import 'app_colors_theme.dart';

/// Central palette for Portfolio Intelligence Overview (Health / Risk / X-Ray).
///
/// Prefer [ThemeColorExtensions] for P&L and status (`marketPositive`,
/// `statusWarning`, etc.). Use these tokens only for feature-specific chart
/// and radar accents that are not part of the base theme.
abstract final class IntelligenceColors {
  static const List<Color> chartPalette = <Color>[
    Color(0xFFD4AF37),
    Color(0xFFFBBF24),
    Color(0xFFF472B6),
    Color(0xFF34D399),
    Color(0xFFA78BFA),
    Color(0xFFFB923C),
    Color(0xFF60A5FA),
    Color(0xFF2DD4BF),
  ];

  static Color chartColor(int index) =>
      chartPalette[index % chartPalette.length];

  static const Color riskRadarGold = Color(0xFFF5C542);
  static const Color riskRadarConcentration = Color(0xFFE91E8C);
  static const Color riskRadarSector = Color(0xFF00D4FF);
  static const Color riskRadarDiversification = Color(0xFF3DDC97);
  static const Color riskRadarLiquidity = Color(0xFFF5C542);

  static const Color healthBandStrong = Color(0xFF00D2C6);
  static const Color healthBandHealthy = Color(0xFF55EFC4);

  static const Color factorDiversification = Color(0xFF00D2C6);
  static const Color factorConcentration = Color(0xFFFF6B9D);
  static const Color factorLiquidity = Color(0xFF4DA3FF);
  static const Color factorAllocation = Color(0xFFA78BFA);
  static const Color factorRiskResilience = Color(0xFFFF9F43);

  static const Color surfaceDeep = Color(0xFF0D1B2A);
  static const Color mist = Color(0xFFF5F7FF);

  /// Maps health band labels to theme status colors where possible.
  static Color healthBand(String? band, AppColorsTheme theme) {
    switch ((band ?? '').trim().toLowerCase()) {
      case 'strong':
        return healthBandStrong;
      case 'healthy':
        return healthBandHealthy;
      case 'critical':
        return theme.statusError;
      case 'watch':
        return theme.statusWarning;
      default:
        return theme.statusNeutral;
    }
  }

  static Color factorAccent(String? id) {
    switch ((id ?? '').trim().toLowerCase()) {
      case 'diversification':
        return factorDiversification;
      case 'concentration':
        return factorConcentration;
      case 'liquidity':
        return factorLiquidity;
      case 'allocation':
        return factorAllocation;
      case 'risk':
      case 'risk_resilience':
      case 'resilience':
        return factorRiskResilience;
      default:
        return factorAllocation;
    }
  }

  static Color severity(String? level, AppColorsTheme theme) {
    switch ((level ?? '').trim().toLowerCase()) {
      case 'high':
      case 'critical':
        return theme.statusError;
      case 'medium':
      case 'warn':
      case 'warning':
        return theme.statusWarning;
      case 'low':
      case 'ok':
      case 'info':
        return theme.marketPositiveIndicator;
      default:
        return theme.statusNeutral;
    }
  }
}
