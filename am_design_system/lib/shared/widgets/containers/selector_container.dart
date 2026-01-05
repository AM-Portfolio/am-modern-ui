import 'package:flutter/material.dart';

/// A flexible container widget for selector layouts that provides
/// consistent spacing, alignment, and responsive behavior
class SelectorContainer extends StatelessWidget {
  const SelectorContainer({
    required this.children,
    super.key,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.decoration,
    this.scrollable = false,
    this.shrinkWrap = true,
    this.showDividers = false,
    this.maxWidth,
    this.responsive = true,
  });

  /// Child widgets to display in the container
  final List<Widget> children;

  /// Layout direction (horizontal or vertical)
  final Axis direction;

  /// Main axis alignment for flex layouts
  final MainAxisAlignment mainAxisAlignment;

  /// Cross axis alignment for flex layouts
  final CrossAxisAlignment crossAxisAlignment;

  /// Spacing between items
  final double spacing;

  /// Spacing between runs (for wrap layouts)
  final double runSpacing;

  /// Padding around the container
  final EdgeInsetsGeometry padding;

  /// Margin around the container
  final EdgeInsetsGeometry? margin;

  /// Container decoration
  final BoxDecoration? decoration;

  /// Whether the container should be scrollable
  final bool scrollable;

  /// Whether the container should shrink wrap its contents
  final bool shrinkWrap;

  /// Whether to show dividers between items
  final bool showDividers;

  /// Maximum width before wrapping (responsive behavior)
  final double? maxWidth;

  /// Whether to enable responsive behavior
  final bool responsive;

  @override
  Widget build(BuildContext context) {
    var content = _buildContent(context);

    if (scrollable) {
      content = _wrapWithScrollView(content);
    }

    return Container(
      margin: margin,
      padding: padding,
      decoration: decoration,
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth!)
          : null,
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final shouldWrap = responsive && screenWidth < 600; // Mobile breakpoint

    if (shouldWrap && direction == Axis.horizontal) {
      return _buildWrapLayout();
    } else {
      return _buildFlexLayout();
    }
  }

  Widget _buildFlexLayout() {
    final childrenWithSpacing = _addSpacingToChildren();

    if (direction == Axis.horizontal) {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: childrenWithSpacing,
      );
    } else {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
        children: childrenWithSpacing,
      );
    }
  }

  Widget _buildWrapLayout() => Wrap(
    direction: direction,
    alignment: _getWrapAlignment(),
    crossAxisAlignment: _getWrapCrossAlignment(),
    spacing: spacing,
    runSpacing: runSpacing,
    children: children,
  );

  List<Widget> _addSpacingToChildren() {
    if (children.isEmpty) return [];

    final spacedChildren = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);

      // Add spacing between items (but not after the last item)
      if (i < children.length - 1) {
        if (showDividers) {
          spacedChildren.add(_buildDivider());
        } else {
          spacedChildren.add(_buildSpacer());
        }
      }
    }

    return spacedChildren;
  }

  Widget _buildSpacer() {
    if (direction == Axis.horizontal) {
      return SizedBox(width: spacing);
    } else {
      return SizedBox(height: spacing);
    }
  }

  Widget _buildDivider() {
    if (direction == Axis.horizontal) {
      return Container(
        width: 1,
        height: 20,
        margin: EdgeInsets.symmetric(horizontal: spacing / 2),
        color: Colors.grey.shade300,
      );
    } else {
      return Container(
        height: 1,
        margin: EdgeInsets.symmetric(vertical: spacing / 2),
        color: Colors.grey.shade300,
      );
    }
  }

  Widget _wrapWithScrollView(Widget child) {
    if (direction == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: child,
      );
    } else {
      return SingleChildScrollView(child: child);
    }
  }

  WrapAlignment _getWrapAlignment() {
    switch (mainAxisAlignment) {
      case MainAxisAlignment.start:
        return WrapAlignment.start;
      case MainAxisAlignment.end:
        return WrapAlignment.end;
      case MainAxisAlignment.center:
        return WrapAlignment.center;
      case MainAxisAlignment.spaceBetween:
        return WrapAlignment.spaceBetween;
      case MainAxisAlignment.spaceAround:
        return WrapAlignment.spaceAround;
      case MainAxisAlignment.spaceEvenly:
        return WrapAlignment.spaceEvenly;
    }
  }

  WrapCrossAlignment _getWrapCrossAlignment() {
    switch (crossAxisAlignment) {
      case CrossAxisAlignment.start:
        return WrapCrossAlignment.start;
      case CrossAxisAlignment.end:
        return WrapCrossAlignment.end;
      case CrossAxisAlignment.center:
        return WrapCrossAlignment.center;
      case CrossAxisAlignment.stretch:
        return WrapCrossAlignment.start; // Wrap doesn't support stretch
      case CrossAxisAlignment.baseline:
        return WrapCrossAlignment.start; // Wrap doesn't support baseline
    }
  }
}

/// Predefined configurations for common selector container layouts
extension SelectorContainerConfigs on SelectorContainer {
  /// Horizontal selector bar layout (common for filters)
  static SelectorContainer horizontalBar({
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    bool scrollable = true,
    bool showDividers = false,
  }) => SelectorContainer(
    padding: padding,
    scrollable: scrollable,
    showDividers: showDividers,
    spacing: 12.0,
    children: children,
  );

  /// Vertical selector stack layout
  static SelectorContainer verticalStack({
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    MainAxisAlignment alignment = MainAxisAlignment.start,
    double spacing = 12.0,
  }) => SelectorContainer(
    direction: Axis.vertical,
    padding: padding,
    mainAxisAlignment: alignment,
    spacing: spacing,
    children: children,
  );

  /// Responsive grid layout that wraps on smaller screens
  static SelectorContainer responsiveGrid({
    required List<Widget> children,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16.0),
    double spacing = 8.0,
    double runSpacing = 8.0,
  }) => SelectorContainer(
    padding: padding,
    spacing: spacing,
    runSpacing: runSpacing,
    children: children,
  );

  /// Compact layout for sidebar or drawer usage
  static SelectorContainer compact({
    required List<Widget> children,
    Axis direction = Axis.vertical,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    double spacing = 6.0,
  }) => SelectorContainer(
    direction: direction,
    padding: padding,
    spacing: spacing,
    children: children,
  );
}
