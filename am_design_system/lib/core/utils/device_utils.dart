import 'package:flutter/widgets.dart';
import '../constants/breakpoints.dart';

class DeviceUtils {
  static bool isMobile(BuildContext context) {
    return AmBreakpoints.isMobileContext(context);
  }

  static bool isTablet(BuildContext context) {
    return AmBreakpoints.isTabletContext(context);
  }

  static bool isDesktop(BuildContext context) {
    return AmBreakpoints.isDesktopContext(context);
  }
}
