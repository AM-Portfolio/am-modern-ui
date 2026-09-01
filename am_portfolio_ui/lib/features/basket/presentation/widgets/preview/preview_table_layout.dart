import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../utils/basket_responsive.dart';

/// Shared grid for preview section headers and stock rows — keeps columns aligned.
abstract final class PreviewTableLayout {
  static const int etfNameFlex = 4;
  static const int etfWeightFlex = 2;
  static const int unitsFlex = 2;
  static const int valueFlex = 3;
  static const double statusWidth = 72;
  static const double minTableWidth = 560;
  static const double hPadding = AppSpacing.md;
  static const double colGap = AppSpacing.sm;

  static int get etfPanelFlex => etfNameFlex + etfWeightFlex;
  static int get portfolioPanelFlex => unitsFlex + valueFlex;

  static EdgeInsets get rowPadding =>
      const EdgeInsets.symmetric(horizontal: hPadding, vertical: AppSpacing.sm + 2);

  static EdgeInsets get headerPadding =>
      const EdgeInsets.fromLTRB(hPadding, AppSpacing.sm, hPadding, AppSpacing.sm);

  static Widget divider(BuildContext context, {double height = 28}) {
    return Container(
      width: 1,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: colGap),
      color: context.colors.border.withValues(alpha: 0.75),
    );
  }

  /// Wraps table content — horizontal scroll on tablet / narrow embedded panes.
  static Widget scrollableTable({
    required BuildContext context,
    required Widget child,
  }) {
    if (BasketResponsive.useCompactPreview(context)) {
      return child;
    }
    if (!BasketResponsive.useScrollablePreviewTable(context)) {
      return child;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: minTableWidth),
        child: child,
      ),
    );
  }

  /// One table row — same structure for header labels and data cells.
  static Widget row({
    required BuildContext context,
    required Widget etfName,
    required Widget etfWeight,
    required Widget units,
    required Widget value,
    required Widget status,
    EdgeInsets? padding,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    final rowContent = Padding(
      padding: padding ?? rowPadding,
      child: Row(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(
            flex: etfNameFlex,
            child: Align(
              alignment: Alignment.centerLeft,
              child: etfName,
            ),
          ),
          Expanded(
            flex: etfWeightFlex,
            child: Align(
              alignment: Alignment.centerRight,
              child: etfWeight,
            ),
          ),
          divider(context),
          Expanded(
            flex: unitsFlex,
            child: Align(
              alignment: Alignment.centerLeft,
              child: units,
            ),
          ),
          Expanded(
            flex: valueFlex,
            child: Align(
              alignment: Alignment.centerRight,
              child: value,
            ),
          ),
          SizedBox(width: colGap),
          SizedBox(
            width: statusWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: status,
            ),
          ),
        ],
      ),
    );

    return scrollableTable(context: context, child: rowContent);
  }
}
