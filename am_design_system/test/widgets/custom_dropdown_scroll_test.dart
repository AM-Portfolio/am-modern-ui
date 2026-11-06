import 'package:am_design_system/shared/widgets/inputs/custom_dropdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CustomDropdown closes on PointerScrollEvent and passes scroll to listener',
      (tester) async {
    String selected = '1Y';
    bool receivedScrollEvent = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                receivedScrollEvent = true;
              }
            },
            child: Center(
              child: CustomDropdown<String>(
                value: selected,
                items: const [
                  DropdownMenuItem(value: '1D', child: Text('1D')),
                  DropdownMenuItem(value: '1M', child: Text('1M')),
                  DropdownMenuItem(value: '1Y', child: Text('1Y')),
                  DropdownMenuItem(value: '5Y', child: Text('5Y')),
                ],
                onChanged: (val) {
                  if (val != null) selected = val;
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state: dropdown menu options are not visible in overlay
    expect(find.text('5Y'), findsNothing);

    // Tap to open dropdown
    await tester.tap(find.text('1Y'));
    await tester.pumpAndSettle();

    // Verify dropdown is open and options are visible
    expect(find.text('5Y'), findsOneWidget);

    // First scroll signal: dismisses the dropdown
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.addPointer(location: const Offset(20, 20)));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 50)));
    await tester.pumpAndSettle();

    // Dropdown is dismissed automatically
    expect(find.text('5Y'), findsNothing);

    // Subsequent scroll reaches the underlying page unblocked
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 50)));
    await tester.pumpAndSettle();
    expect(receivedScrollEvent, isTrue);
  });
}
