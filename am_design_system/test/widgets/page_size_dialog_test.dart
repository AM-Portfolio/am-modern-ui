import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('returns a valid page size from the themed dialog',
      (tester) async {
    int? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              selected = await PageSizeDialog.show(
                context: context,
                currentValue: 10,
                minValue: 1,
                maxValue: 193,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '50');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(selected, 50);
    expect(find.text('Items per page'), findsNothing);
  });

  testWidgets('keeps the dialog open for an invalid page size',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PageSizeDialog.show(
              context: context,
              currentValue: 10,
              minValue: 1,
              maxValue: 20,
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a whole number from 1 to 20.'), findsOneWidget);
    expect(find.text('Items per page'), findsOneWidget);
  });
}
