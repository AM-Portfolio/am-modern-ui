import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(AppZoomPointer.reset);

  testWidgets('enter/exit tracks chart pointer depth', (tester) async {
    expect(AppZoomPointer.overChart, isFalse);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppZoomScrollGuard(
            child: SizedBox(width: 80, height: 80, child: Text('CHART')),
          ),
        ),
      ),
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: Offset.zero);
    addTearDown(gesture.removePointer);
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('CHART')));
    await tester.pump();
    expect(AppZoomPointer.overChart, isTrue);

    await gesture.moveTo(const Offset(400, 400));
    await tester.pump();
    expect(AppZoomPointer.overChart, isFalse);
  });
}
