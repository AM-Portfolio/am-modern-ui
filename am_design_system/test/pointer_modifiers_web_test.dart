@TestOn('browser')
library;

import 'dart:html' as html;

import 'package:am_design_system/core/navigation/pointer_modifiers_web.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(retainPointerModifiers);
  tearDown(releasePointerModifiers);

  test('browser pointer state replaces a stale modifier on every interaction',
      () {
    html.window.dispatchEvent(html.MouseEvent('pointerdown', ctrlKey: true));
    expect(pointerRequestsNewTab, isTrue);
    html.window.dispatchEvent(html.MouseEvent('pointerdown'));
    expect(pointerRequestsNewTab, isFalse);
    html.window.dispatchEvent(html.MouseEvent('pointerdown', metaKey: true));
    expect(pointerRequestsNewTab, isTrue);
    html.window.dispatchEvent(html.Event('blur'));
    expect(pointerRequestsNewTab, isFalse);
  });

  test('disposing one navigation item keeps other items listening', () {
    retainPointerModifiers();
    releasePointerModifiers();
    html.window.dispatchEvent(html.MouseEvent('pointerdown', ctrlKey: true));
    expect(pointerRequestsNewTab, isTrue);
  });
}
