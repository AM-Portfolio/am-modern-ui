import 'package:am_common/am_common.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fling = 900.0;
  const drag = 140.0;
  const minDrag = 48.0;

  bool? decide({
    required double dragDx,
    required double velocityDx,
  }) {
    return horizontalSectionNavDecision(
      dragDx: dragDx,
      velocityDx: velocityDx,
      flingVelocity: fling,
      dragDistance: drag,
      minDragForAnyNav: minDrag,
    );
  }

  group('horizontalSectionNavDecision', () {
    test('rejects micro-jitter even with high velocity', () {
      expect(decide(dragDx: 20, velocityDx: -2000), isNull);
      expect(decide(dragDx: -30, velocityDx: 1500), isNull);
    });

    test('rejects short drag without fling', () {
      expect(decide(dragDx: 80, velocityDx: 0), isNull);
      expect(decide(dragDx: -100, velocityDx: 200), isNull);
    });

    test('accepts long deliberate drag', () {
      expect(decide(dragDx: -140, velocityDx: 0), isTrue); // next
      expect(decide(dragDx: 140, velocityDx: 0), isFalse); // previous
    });

    test('accepts fling after min drag', () {
      expect(decide(dragDx: -50, velocityDx: -900), isTrue);
      expect(decide(dragDx: 50, velocityDx: 900), isFalse);
    });
  });
}
