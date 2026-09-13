import 'dart:math' as math;

import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_xray_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('xrayActiveIndex', () {
    test('prefers hover over sticky select', () {
      expect(
        xrayActiveIndex(
          hoveredIndex: 2,
          selectedName: 'A',
          weightNames: const ['A', 'B', 'C'],
        ),
        2,
      );
    });

    test('falls back to selected name index', () {
      expect(
        xrayActiveIndex(
          hoveredIndex: null,
          selectedName: 'B',
          weightNames: const ['A', 'B', 'C'],
        ),
        1,
      );
    });

    test('returns null when nothing active', () {
      expect(
        xrayActiveIndex(
          hoveredIndex: null,
          selectedName: null,
          weightNames: const ['A', 'B'],
        ),
        isNull,
      );
    });
  });

  group('xrayRowTintSelected', () {
    test('while hovering only hovered row is tinted', () {
      expect(
        xrayRowTintSelected(
          index: 0,
          hoveredIndex: 1,
          selectedName: 'A',
          weightName: 'A',
        ),
        isFalse,
      );
      expect(
        xrayRowTintSelected(
          index: 1,
          hoveredIndex: 1,
          selectedName: 'A',
          weightName: 'B',
        ),
        isTrue,
      );
    });

    test('without hover tints sticky selected name', () {
      expect(
        xrayRowTintSelected(
          index: 0,
          hoveredIndex: null,
          selectedName: 'A',
          weightName: 'A',
        ),
        isTrue,
      );
      expect(
        xrayRowTintSelected(
          index: 1,
          hoveredIndex: null,
          selectedName: 'A',
          weightName: 'B',
        ),
        isFalse,
      );
    });
  });

  group('xrayDonutTapKind / xrayHitSliceIndex', () {
    const side = 168.0;
    final equalThirds = const [
      XrayWeight(name: 'A', weightPct: 100 / 3),
      XrayWeight(name: 'B', weightPct: 100 / 3),
      XrayWeight(name: 'C', weightPct: 100 / 3),
    ];

    Offset ringPoint(double angleFromTopCw) {
      final center = const Offset(side / 2, side / 2);
      final baseRadius = (side / 2) - 12;
      // Painter starts at -pi/2; hit uses same after atan2 remap.
      final paintAngle = -math.pi / 2 + angleFromTopCw;
      return Offset(
        center.dx + baseRadius * math.cos(paintAngle),
        center.dy + baseRadius * math.sin(paintAngle),
      );
    }

    test('hole is center; miss is far corner', () {
      expect(
        xrayDonutTapKind(
          local: const Offset(side / 2, side / 2),
          side: side,
          weights: equalThirds,
        ),
        XrayDonutTapKind.hole,
      );
      expect(
        xrayDonutTapKind(
          local: const Offset(2, 2),
          side: side,
          weights: equalThirds,
        ),
        XrayDonutTapKind.miss,
      );
    });

    test('equal thirds map to slice indices by angle', () {
      // Mid of first third (0 .. 2pi/3).
      final a = ringPoint(math.pi / 3);
      expect(
        xrayDonutTapKind(local: a, side: side, weights: equalThirds),
        XrayDonutTapKind.slice,
      );
      expect(
        xrayHitSliceIndex(local: a, side: side, weights: equalThirds),
        0,
      );

      final b = ringPoint(math.pi);
      expect(
        xrayHitSliceIndex(local: b, side: side, weights: equalThirds),
        1,
      );

      final c = ringPoint(5 * math.pi / 3);
      expect(
        xrayHitSliceIndex(local: c, side: side, weights: equalThirds),
        2,
      );
    });

    test('re-select path: different angles yield different indices', () {
      final first = xrayHitSliceIndex(
        local: ringPoint(math.pi / 6),
        side: side,
        weights: equalThirds,
      );
      final second = xrayHitSliceIndex(
        local: ringPoint(math.pi),
        side: side,
        weights: equalThirds,
      );
      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, isNot(second));
    });
  });
}
