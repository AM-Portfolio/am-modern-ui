import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';

void main() {
  test('AmBreakpoints checks breakpoint limits correctly', () {
    expect(AmBreakpoints.isWatch(150), true);
    expect(AmBreakpoints.isMobile(400), true);
    expect(AmBreakpoints.isTablet(800), true);
    expect(AmBreakpoints.isDesktop(1200), true);
  });
}
