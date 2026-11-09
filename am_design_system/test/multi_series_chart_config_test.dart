import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('streamDrawOnLoad defaults false; end pills default true', () {
    const config = MultiSeriesChartConfig();
    expect(config.streamDrawOnLoad, isFalse);
    expect(config.showEndValuePills, isTrue);
  });

  test('streamDrawOnLoad can be enabled for overlay charts', () {
    const config = MultiSeriesChartConfig(
      streamDrawOnLoad: true,
      showEndValuePills: true,
      preNormalizedPercent: true,
    );
    expect(config.streamDrawOnLoad, isTrue);
    expect(config.showEndValuePills, isTrue);
    expect(config.preNormalizedPercent, isTrue);
  });
}
