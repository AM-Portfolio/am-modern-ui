import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

/// Shared breakpoint helpers for the basket flow (preview → dashboard).
abstract final class BasketResponsive {
  static double widthOf(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      AmBreakpoints.isMobileContext(context);

  static bool isTablet(BuildContext context) =>
      AmBreakpoints.isTabletContext(context);

  static bool isDesktop(BuildContext context) =>
      AmBreakpoints.isDesktopContext(context);

  /// Phone layout — stacked cards instead of wide table.
  static bool useCompactPreview(BuildContext context) =>
      widthOf(context) < AmBreakpoints.mobile;

  /// Tablet / narrow embedded pane — table with horizontal scroll.
  static bool useScrollablePreviewTable(BuildContext context) =>
      !useCompactPreview(context) && widthOf(context) < AmBreakpoints.tablet;

  static EdgeInsets pagePadding(BuildContext context) {
    if (useCompactPreview(context)) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.sm);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
    }
    return const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
  }
}
