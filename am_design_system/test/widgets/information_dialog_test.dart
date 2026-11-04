import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('information dialog is dismissible and renders supplied copy',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => InformationDialog.show(
              context: context,
              title: 'Date not announced yet',
              message: 'Stay tuned with AM Investments.',
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Date not announced yet'), findsOneWidget);
    expect(find.text('Stay tuned with AM Investments.'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Close'), findsNothing);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(find.text('Date not announced yet'), findsNothing);
  });
}
