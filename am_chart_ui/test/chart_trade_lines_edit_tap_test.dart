import 'package:am_chart_ui/am_chart_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('edit chip onPressed fires above translucent GestureDetector',
      (tester) async {
    String? editedId;
    final line = ChartTradeLine(
      id: 'tl1',
      side: ChartTradeLineSide.buy,
      price: 100,
      orderType: 'LIMIT',
      symbol: 'RELIANCE',
      quantity: '1',
      anchorXNorm: 0.2,
    );
    const candle = Rect.fromLTWH(40, 20, 400, 300);
    final layout = ChartPriceLayout(
      plot: candle,
      candlePlot: candle,
      volumePlot: const Rect.fromLTWH(40, 320, 400, 40),
      minPrice: 90,
      maxPrice: 110,
      startIndex: 0,
      visibleCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 480,
            height: 360,
            child: Stack(
              children: [
                ChartTradeLinesLayer(
                  lines: [line],
                  layout: layout,
                  enabled: true,
                  onEditLine: (id) => editedId = id,
                  onRemoved: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final y = layout.yFor(line.price);
    final x = candle.left + candle.width * line.effectiveAnchorXNorm;
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset(x, y));
    addTearDown(gesture.removePointer);
    await gesture.moveTo(Offset(x, y));
    await tester.pump();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();
    expect(editedId, 'tl1');
  });
}
