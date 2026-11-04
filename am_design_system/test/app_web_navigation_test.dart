import 'package:am_design_system/core/navigation/app_web_navigation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('retained Ctrl and Meta do not modify a plain activation',
      (tester) async {
    for (final key in [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.metaLeft
    ]) {
      await tester.sendKeyDownEvent(key);
      try {
        expect(AppWebNavigation.shouldOpenNewTab(), isFalse);
        expect(
            AppWebNavigation.shouldOpenNewTab(
              pointerDown: const PointerDownEvent(buttons: kPrimaryMouseButton),
            ),
            isFalse);
      } finally {
        await tester.sendKeyUpEvent(key);
      }
    }
  });

  test('explicit modifiers and middle click request another tab', () {
    expect(AppWebNavigation.shouldOpenNewTab(modified: true), isTrue);
    expect(
        AppWebNavigation.shouldOpenNewTab(
          pointerDown: const PointerDownEvent(buttons: kMiddleMouseButton),
        ),
        isTrue);
  });

  for (final outcome in ['success', 'blocked', 'exception', 'same tab']) {
    test('dispatch handles $outcome exactly once', () {
      var sameTab = 0;
      var opens = 0;
      AppWebNavigation.dispatch(
        openInNewTab: outcome != 'same tab',
        path: '/app/market/dashboard',
        onSameTab: () => sameTab++,
        openNewTab: (url) {
          opens++;
          expect(url, contains('/app/market/dashboard'));
          if (outcome == 'exception') throw StateError('open failed');
          return outcome == 'success';
        },
      );
      expect(opens, outcome == 'same tab' ? 0 : 1);
      expect(sameTab, outcome == 'success' ? 0 : 1);
    });
  }

  testWidgets('cancelled gesture does not navigate; following click does',
      (tester) async {
    var navigations = 0;
    await tester.pumpWidget(MaterialApp(
        home: Center(
      child: AppNavigationGesture(
        path: '/app/trade',
        onSameTab: () => navigations++,
        child: const SizedBox(width: 100, height: 100, child: Text('Trade')),
      ),
    )));
    final target = find.byType(AppNavigationGesture);
    final gesture = await tester.startGesture(tester.getCenter(target));
    await gesture.cancel();
    await tester.pump();
    expect(navigations, 0);
    await tester.tap(target);
    expect(navigations, 1);
    final actionContext = tester.element(find
        .descendant(
          of: target,
          matching: find.byType(Listener),
        )
        .first);
    Actions.invoke(actionContext, const ActivateIntent());
    expect(navigations, 2);
  });
}
