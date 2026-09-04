import 'package:flutter/material.dart';

import 'app_type_scale.dart';

/// Named text roles. Prefer these over freehand [TextStyle] fontSize values.
///
/// Colors are not baked in — apply via [TextStyle.copyWith] and `context.colors`.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle heroTitle({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.h2 : AppTypeScale.hero,
        fontWeight: FontWeight.w800,
        height: 1.15,
        letterSpacing: -0.5,
      );

  static TextStyle pageTitle({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.h5 : AppTypeScale.h3,
        fontWeight: FontWeight.w700,
        height: 1.25,
      );

  static TextStyle sectionTitle({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.xl : AppTypeScale.h5,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle body({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.md : AppTypeScale.base,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle bodyMuted({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.sm : AppTypeScale.md,
        fontWeight: FontWeight.w400,
        height: 1.45,
      );

  static TextStyle link({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.sm : AppTypeScale.md,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  static TextStyle button({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.base : AppTypeScale.lg,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );

  static TextStyle label({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.sm : AppTypeScale.md,
        fontWeight: FontWeight.w500,
        height: 1.2,
      );

  static TextStyle caption({bool compact = false}) => TextStyle(
        fontSize: compact ? AppTypeScale.xs : AppTypeScale.sm,
        fontWeight: FontWeight.w500,
        height: 1.3,
      );
}

/// Convenience access: `context.text.pageTitle(compact: true)`.
extension AppTextStylesX on BuildContext {
  _AppTextStylesAccess get text => const _AppTextStylesAccess();
}

class _AppTextStylesAccess {
  const _AppTextStylesAccess();

  TextStyle heroTitle({bool compact = false}) =>
      AppTextStyles.heroTitle(compact: compact);

  TextStyle pageTitle({bool compact = false}) =>
      AppTextStyles.pageTitle(compact: compact);

  TextStyle sectionTitle({bool compact = false}) =>
      AppTextStyles.sectionTitle(compact: compact);

  TextStyle body({bool compact = false}) =>
      AppTextStyles.body(compact: compact);

  TextStyle bodyMuted({bool compact = false}) =>
      AppTextStyles.bodyMuted(compact: compact);

  TextStyle link({bool compact = false}) =>
      AppTextStyles.link(compact: compact);

  TextStyle button({bool compact = false}) =>
      AppTextStyles.button(compact: compact);

  TextStyle label({bool compact = false}) =>
      AppTextStyles.label(compact: compact);

  TextStyle caption({bool compact = false}) =>
      AppTextStyles.caption(compact: compact);
}
