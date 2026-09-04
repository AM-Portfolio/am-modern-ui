import 'package:flutter/material.dart';

import 'app_radii.dart';
import 'app_spacing.dart';
import 'app_type_scale.dart';

/// Shared component dimension recipes built from spacing/radii/type tokens.
class AppComponentSizes {
  AppComponentSizes._();

  static const double inputHeight = 48;
  static const double buttonHeight = 48;
  static const double iconButtonSize = 40;
  static const double iconButtonSizeCompact = 34;

  static const double cardPadding = AppSpacing.cardPadding;
  static const double fieldGap = AppSpacing.listGap;
  static const double sectionGap = AppSpacing.md;

  static const double cardRadius = AppRadii.lg;
  static const double buttonRadius = AppRadii.lg;
  static const double inputRadius = AppRadii.md;

  static const double formMaxWidth = 1080;
  static const double labelFontSize = AppTypeScale.md;
  static const double buttonFontSize = AppTypeScale.lg;
}
