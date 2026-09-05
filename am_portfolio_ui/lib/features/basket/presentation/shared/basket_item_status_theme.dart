import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../domain/models/basket_opportunity.dart';

/// Semantic colors and labels for basket line status — single source of truth.
abstract final class BasketItemStatusTheme {
  BasketItemStatusTheme._();

  static Color colorFor(BuildContext context, ItemStatus? status,
      {bool isExcluded = false}) {
    if (isExcluded) return context.textTertiary;
    return switch (status) {
      ItemStatus.held => context.statusSuccess,
      ItemStatus.substitute => ModuleColors.portfolio,
      ItemStatus.missing => context.statusError,
      ItemStatus.excluded => context.textTertiary,
      null => context.textTertiary,
    };
  }

  static String labelFor(ItemStatus? status, {bool isExcluded = false}) {
    if (isExcluded) return 'Excluded';
    return switch (status) {
      ItemStatus.held => 'Held',
      ItemStatus.substitute => 'Subst.',
      ItemStatus.missing => 'Missing',
      ItemStatus.excluded => 'Excluded',
      null => '',
    };
  }

  static Color heldGroupColor(BuildContext context) => context.statusSuccess;

  static Color substituteGroupColor(BuildContext context) =>
      ModuleColors.portfolio;

  static Color missingGroupColor(BuildContext context) => context.statusError;

  static Color excludedGroupColor(BuildContext context) => context.textTertiary;
}
