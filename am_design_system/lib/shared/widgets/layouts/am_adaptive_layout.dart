import 'package:flutter/material.dart';
import '../../../core/constants/breakpoints.dart';

/// Responsive layout engine for the AM Platform.
///
/// Arranges named content slots based on available screen width.
/// All slots are ALWAYS rendered — content is never hidden, only rearranged.
///
/// Layout Tiers:
///   Watch   < 200px  → [watch] slot only (WearOS Android, fallback to [primary])
///   Mobile  < 600px  → All slots stacked vertically in one scrollable column
///   Tablet  < 1100px → [primary]+[detail] left, [secondary] right — 2 scrollable columns
///   Desktop ≥ 1100px → All 3 columns side by side, each independently scrollable
///
/// Usage:
/// ```dart
/// AmAdaptiveLayout(
///   primary:   SummaryPanel(),   // shown everywhere
///   secondary: ChartsPanel(),    // tablet + desktop
///   detail:    ActivityPanel(),  // stacks under primary on tablet, own col on desktop
/// )
/// ```
class AmAdaptiveLayout extends StatelessWidget {
  const AmAdaptiveLayout({
    required this.primary,
    this.secondary,
    this.detail,
    this.watch,
    this.primaryFlex = 5,
    this.secondaryFlex = 5,
    this.detailFlex = 3,
    this.landscapePrimaryFlex,
    this.landscapeSecondaryFlex,
    this.padding,
    this.columnSpacing,
    this.rowSpacing,
    super.key,
  });

  /// Always shown. Mobile: full width. Tablet/Desktop: left column.
  final Widget primary;

  /// Tablet + Desktop: right column. Mobile: stacked below primary.
  final Widget? secondary;

  /// Desktop only column. Tablet: stacks under primary in left column.
  final Widget? detail;

  /// WearOS watch screens only (< 200px). Fallback: [primary].
  final Widget? watch;

  /// Flex ratios for primary column
  final int primaryFlex;

  /// Flex ratios for secondary column
  final int secondaryFlex;

  /// Flex ratios for detail column
  final int detailFlex;

  /// Optional flex ratios when tablet is in landscape orientation
  final int? landscapePrimaryFlex;
  final int? landscapeSecondaryFlex;

  /// Custom padding override. If null, calculates responsive padding based on screen width.
  final EdgeInsets? padding;

  /// Custom column spacing override.
  final double? columnSpacing;

  /// Custom row spacing override.
  final double? rowSpacing;

  EdgeInsets _getAdaptivePadding(double width) {
    if (padding != null) return padding!;
    if (width < AmBreakpoints.mobile) {
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
    }
    if (width < AmBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  }

  double _getAdaptiveSpacing(double width) {
    if (columnSpacing != null) return columnSpacing!;
    if (width < AmBreakpoints.mobile) return 12.0;
    if (width < AmBreakpoints.tablet) return 16.0;
    return 24.0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final currentPadding = _getAdaptivePadding(width);
        final spacing = _getAdaptiveSpacing(width);
        final rSpacing = rowSpacing ?? spacing;

        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;

        final resolvedPrimaryFlex =
            (isLandscape && landscapePrimaryFlex != null)
                ? landscapePrimaryFlex!
                : primaryFlex;

        final resolvedSecondaryFlex =
            (isLandscape && landscapeSecondaryFlex != null)
                ? landscapeSecondaryFlex!
                : secondaryFlex;

        // ⌚ Watch — WearOS Android (< 200px)
        if (width < AmBreakpoints.watch) {
          return watch ?? primary;
        }

        // 📱 Mobile — single scrollable column (< 600px)
        if (width < AmBreakpoints.mobile) {
          return SingleChildScrollView(
            padding: currentPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                primary,
                if (secondary != null) ...[
                  SizedBox(height: rSpacing),
                  secondary!,
                ],
                if (detail != null) ...[
                  SizedBox(height: rSpacing),
                  detail!,
                ],
              ],
            ),
          );
        }

        // 📟 Tablet — 2 scrollable columns (600px – 1099px)
        if (width < AmBreakpoints.tablet) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: resolvedPrimaryFlex,
                child: SingleChildScrollView(
                  padding: currentPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      primary,
                      if (detail != null) ...[
                        SizedBox(height: rSpacing),
                        detail!,
                      ],
                    ],
                  ),
                ),
              ),
              if (secondary != null) ...[
                SizedBox(width: spacing),
                Expanded(
                  flex: resolvedSecondaryFlex,
                  child: SingleChildScrollView(
                    padding: currentPadding,
                    child: secondary!,
                  ),
                ),
              ],
            ],
          );
        }

        // 🖥️ Desktop — 3 scrollable columns (≥ 1100px)
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: resolvedPrimaryFlex,
              child: SingleChildScrollView(
                padding: currentPadding,
                child: primary,
              ),
            ),
            if (secondary != null) ...[
              SizedBox(width: spacing),
              Expanded(
                flex: resolvedSecondaryFlex,
                child: SingleChildScrollView(
                  padding: currentPadding,
                  child: secondary!,
                ),
              ),
            ],
            if (detail != null) ...[
              SizedBox(width: spacing),
              Expanded(
                flex: detailFlex,
                child: SingleChildScrollView(
                  padding: currentPadding,
                  child: detail!,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
