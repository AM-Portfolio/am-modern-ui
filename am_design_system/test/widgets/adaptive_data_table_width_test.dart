import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expanded desktop table receives the available width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: AdaptiveDataTable<String>(
              data: const ['IPO'],
              expandToAvailableWidth: true,
              columns: [
                DataTableColumn<String>(
                  key: 'name',
                  title: 'IPO',
                  cellBuilder: (value) => Text(value),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final widthConstraint = tester
        .widgetList<ConstrainedBox>(
          find.descendant(
            of: find.byType(AdaptiveDataTable<String>),
            matching: find.byType(ConstrainedBox),
          ),
        )
        .firstWhere((box) => box.constraints.minWidth > 0);

    // The default test surface is 800px wide, so this verifies the table
    // follows the actual parent constraint instead of its intrinsic width.
    expect(widthConstraint.constraints.minWidth, 800);
  });

  testWidgets('third sort tap restores the natural row order', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveDataTable<String>(
            data: const ['B', 'A'],
            resetSortOnThirdTap: true,
            columns: [
              DataTableColumn<String>(
                key: 'value',
                title: 'VALUE',
                sortable: true,
                sortValue: (value) => value,
                cellBuilder: (value) => Text(value),
              ),
            ],
          ),
        ),
      ),
    );

    final header = find.text('VALUE');
    await tester.tap(header);
    await tester.pump();
    expect(tester.getTopLeft(find.text('A')).dy,
        lessThan(tester.getTopLeft(find.text('B')).dy));

    await tester.tap(header);
    await tester.pump();
    expect(tester.getTopLeft(find.text('B')).dy,
        lessThan(tester.getTopLeft(find.text('A')).dy));

    await tester.tap(header);
    await tester.pump();
    expect(tester.getTopLeft(find.text('B')).dy,
        lessThan(tester.getTopLeft(find.text('A')).dy));
  });

  testWidgets('nullable sort values remain last in both directions',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveDataTable<String>(
            data: const ['missing', 'high', 'low'],
            resetSortOnThirdTap: true,
            columns: [
              DataTableColumn<String>(
                key: 'value',
                title: 'VALUE',
                sortable: true,
                nullableSortValue: (value) => switch (value) {
                  'high' => 4.65,
                  'low' => 0.87,
                  _ => null,
                },
                cellBuilder: (value) => Text(value),
              ),
            ],
          ),
        ),
      ),
    );

    final header = find.text('VALUE');
    await tester.tap(header);
    await tester.pump();
    expect(tester.getTopLeft(find.text('low')).dy,
        lessThan(tester.getTopLeft(find.text('high')).dy));
    expect(tester.getTopLeft(find.text('high')).dy,
        lessThan(tester.getTopLeft(find.text('missing')).dy));

    await tester.tap(header);
    await tester.pump();
    expect(tester.getTopLeft(find.text('high')).dy,
        lessThan(tester.getTopLeft(find.text('low')).dy));
    expect(tester.getTopLeft(find.text('low')).dy,
        lessThan(tester.getTopLeft(find.text('missing')).dy));
  });
}
