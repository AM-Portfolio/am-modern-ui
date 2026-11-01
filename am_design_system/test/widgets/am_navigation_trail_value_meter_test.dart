import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('navigation trail invokes only parent items', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AmNavigationTrail(
            items: [
              AmNavigationTrailItem(
                label: 'IPOs',
                onTap: () => tapped = true,
              ),
              const AmNavigationTrailItem(label: 'Antala Industries IPO'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('IPOs'));
    expect(tapped, isTrue);
    expect(find.text('Antala Industries IPO'), findsOneWidget);
  });

  testWidgets('value meter keeps true readout and theme accent',
      (tester) async {
    const palette = AppColorsTheme.midnightOled;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          extensions: const <ThemeExtension<dynamic>>[palette],
        ),
        home: const Scaffold(
          body: AmValueMeter(
            value: 136,
            maxValue: 100,
            label: 'Overall subscription',
            suffix: '×',
          ),
        ),
      ),
    );

    expect(find.text('Overall subscription'), findsOneWidget);
    expect(find.text('136×'), findsOneWidget);
    expect(find.text('100×'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AmValueMeter),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );

    final semantics = tester.getSemantics(find.byType(AmValueMeter));
    expect(semantics.label, contains('Overall subscription'));
    expect(semantics.value, contains('above the displayed scale'));
  });
}
