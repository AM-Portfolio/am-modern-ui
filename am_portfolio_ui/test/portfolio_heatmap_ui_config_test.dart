import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/portfolio_heatmap_widget.dart';

void main() {
  test('mobile heatmap defaults to treemap like web', () {
    expect(
      PortfolioHeatmapUiConfig.mobile.defaultLayout,
      HeatmapLayoutType.treemap,
    );
    expect(
      PortfolioHeatmapUiConfig.web.defaultLayout,
      HeatmapLayoutType.treemap,
    );
  });

  testWidgets('mobile heatmap inset clears the floating bottom nav',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = FakeViewPadding(bottom: 34);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetPadding();
    });

    late double inset;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            inset = PortfolioHeatmapUiConfig.mobileBottomInset(
              context,
              navFactor: 1,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // chrome 70 + safe inset 34 + 8 pad
    expect(inset, 112);
    expect(inset, greaterThan(PlatformConstants.mobileBottomNavHeight));
  });
}
