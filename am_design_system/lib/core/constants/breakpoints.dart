import 'package:flutter/widgets.dart';

/// Unified responsive breakpoints for the AM Platform.
///
/// Screen width determines layout behavior:
/// - Watch       < 200px  (WearOS Android watches / tiny screens)
/// - Mobile   200–599px  (Smartphones — single scrollable column)
/// - Tablet   600–1099px (iPads / Foldables — 2-column split)
/// - Desktop  ≥ 1100px   (Laptops / Monitors — 3-column split)
/// - Wide     ≥ 1600px   (Ultra-wide monitors)
class AmBreakpoints {
  AmBreakpoints._();

  /// Watch / WearOS tier cutoff width
  static const double watch = 200.0;

  /// Mobile phone tier cutoff width
  static const double mobile = 600.0;

  /// Tablet tier cutoff width
  static const double tablet = 1100.0;

  /// Wide desktop tier cutoff width
  static const double wideDesktop = 1600.0;

  /// Check width helpers
  static bool isWatch(double width) => width < watch;
  static bool isMobile(double width) => width >= watch && width < mobile;
  static bool isTablet(double width) => width >= mobile && width < tablet;
  static bool isDesktop(double width) => width >= tablet;
  static bool isWideDesktop(double width) => width >= wideDesktop;

  /// Context-based helpers using MediaQuery.sizeOf
  static bool isWatchContext(BuildContext context) =>
      isWatch(MediaQuery.sizeOf(context).width);

  static bool isMobileContext(BuildContext context) =>
      isMobile(MediaQuery.sizeOf(context).width);

  static bool isTabletContext(BuildContext context) =>
      isTablet(MediaQuery.sizeOf(context).width);

  static bool isDesktopContext(BuildContext context) =>
      isDesktop(MediaQuery.sizeOf(context).width);

  static bool isWideDesktopContext(BuildContext context) =>
      isWideDesktop(MediaQuery.sizeOf(context).width);
}
