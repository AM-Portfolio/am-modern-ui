import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';

/// Helper class for responsive design across the application
class ResponsiveHelper {
  // Breakpoint constants (delegated to AmBreakpoints)
  static const double mobileBreakpoint = AmBreakpoints.mobile;
  static const double tabletBreakpoint = AmBreakpoints.tablet;

  /// Check if current screen is mobile size (< 600px)
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  /// Check if current screen is tablet size (600px - 1100px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop size (>= 1100px)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= tabletBreakpoint;
  }

  /// Get responsive value based on screen size
  static double getResponsiveValue(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.all(getResponsiveValue(
      context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 48.0,
    ));
  }

  /// Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    return getResponsiveValue(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }
}
