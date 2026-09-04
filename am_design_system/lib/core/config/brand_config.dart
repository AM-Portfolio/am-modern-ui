import 'package:flutter/material.dart';

import '../constants/app_config.dart';
import '../theme/app_animations.dart';
import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import 'design_system_config.dart';
import 'design_system_provider.dart';

/// Host-injected white-label branding (name, logo, colors).
///
/// Wire via [DesignSystemProvider] at the app root. Auth and kit widgets
/// read this instead of hardcoding AM Investment values.
class BrandConfig extends DesignSystemConfig {
  BrandConfig({
    required this.appName,
    required this.primaryColor,
    required this.accentColor,
    this.appIcon = Icons.account_balance_wallet_rounded,
    this.logo,
    Color? scaffoldBackgroundColor,
    Color? surfaceColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? infoColor,
    Duration? animationDuration,
    double? defaultRadius,
    this.fontFamily = 'Inter',
    this.useGlassmorphism = true,
  })  : scaffoldBackgroundColor =
            scaffoldBackgroundColor ?? AppColors.darkBackground,
        surfaceColor = surfaceColor ?? AppColors.darkCard,
        successColor = successColor ?? AppColors.success,
        warningColor = warningColor ?? AppColors.warning,
        errorColor = errorColor ?? AppColors.error,
        infoColor = infoColor ?? AppColors.info,
        animationDuration = animationDuration ?? AppAnimations.medium,
        defaultRadius = defaultRadius ?? AppRadii.lg;

  /// Default AM Investment brand.
  factory BrandConfig.amDefault() => BrandConfig(
        appName: AppConfig.investmentAppName,
        appIcon: AppConfig.investmentAppIcon,
        primaryColor: AppColors.primary,
        accentColor: AppColors.accentBlue,
      );

  final String appName;
  final IconData appIcon;
  final Widget? logo;

  @override
  final Color primaryColor;

  @override
  final Color accentColor;

  @override
  final Color scaffoldBackgroundColor;

  @override
  final Color surfaceColor;

  @override
  final Color successColor;

  @override
  final Color warningColor;

  @override
  final Color errorColor;

  @override
  final Color infoColor;

  @override
  final Duration animationDuration;

  @override
  final double defaultRadius;

  @override
  final String fontFamily;

  @override
  final bool useGlassmorphism;
}

/// Resolve brand from [DesignSystemProvider], falling back to AM defaults.
extension BrandConfigX on BuildContext {
  BrandConfig get brand {
    final config = DesignSystemProvider.of(this);
    if (config is BrandConfig) return config;
    return BrandConfig(
      appName: AppConfig.getAppName(),
      appIcon: AppConfig.getAppIcon(),
      primaryColor: config.primaryColor,
      accentColor: config.accentColor,
      scaffoldBackgroundColor: config.scaffoldBackgroundColor,
      surfaceColor: config.surfaceColor,
      successColor: config.successColor,
      warningColor: config.warningColor,
      errorColor: config.errorColor,
      infoColor: config.infoColor,
      animationDuration: config.animationDuration,
      defaultRadius: config.defaultRadius,
      fontFamily: config.fontFamily,
      useGlassmorphism: config.useGlassmorphism,
    );
  }
}
