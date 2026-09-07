import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';
import '../../../core/theme/app_spacing.dart';

/// A responsive widget that renders a tabular layout on wide screens
/// and smoothly transforms into a structured card list on mobile screens.
class AmAdaptiveTableCardView<T> extends StatelessWidget {
  const AmAdaptiveTableCardView({
    super.key,
    required this.items,
    required this.tableBuilder,
    required this.cardBuilder,
    this.breakpoint = 768.0,
    this.spacing = AppSpacing.sm,
    this.emptyWidget,
    this.padding,
    this.cardListBuilder,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  /// The list of items to render.
  final List<T> items;

  /// Builds the desktop / tablet tabular view.
  final Widget Function(BuildContext context, List<T> items) tableBuilder;

  /// Builds a single card for an item on mobile view.
  final Widget Function(BuildContext context, T item, int index) cardBuilder;

  /// Optional custom card list builder if the caller needs full control over the mobile column/list.
  final Widget Function(BuildContext context, List<T> items)? cardListBuilder;

  /// The width threshold below which the card view is used. Defaults to 768.0.
  final double breakpoint;

  /// Vertical spacing between cards on mobile. Defaults to [AppSpacing.sm].
  final double spacing;

  /// Widget to display when [items] is empty.
  final Widget? emptyWidget;

  /// Optional padding for the mobile card list.
  final EdgeInsetsGeometry? padding;

  /// Cross-axis alignment for the mobile card column.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < breakpoint;

        if (!isMobile) {
          return tableBuilder(context, items);
        }

        if (cardListBuilder != null) {
          return cardListBuilder!(context, items);
        }

        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                cardBuilder(context, items[i], i),
              ],
            ],
          ),
        );
      },
    );
  }
}
