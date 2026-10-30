import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('surfaces and dives a child inside a reserved slot', (tester) async {
    var visible = true;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) => MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AmSubmarineReveal(
                  visible: visible,
                  height: 36,
                  accentColor: Theme.of(context).colorScheme.primary,
                  child: const Text('expiry control'),
                ),
                TextButton(
                  onPressed: () => setState(() => visible = !visible),
                  child: const Text('toggle'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('expiry control'), findsOneWidget);
    await tester.tap(find.text('toggle'));
    await tester.pumpAndSettle();
    expect(find.byType(AmSubmarineReveal), findsOneWidget);
  });
}
