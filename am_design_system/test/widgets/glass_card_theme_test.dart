import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BoxDecoration _glassDecoration(WidgetTester tester) {
  final containers = tester.widgetList<Container>(
    find.descendant(
      of: find.byType(GlassCard),
      matching: find.byType(Container),
    ),
  );
  for (final container in containers) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      return decoration;
    }
  }
  fail('GlassCard has no gradient decoration');
}

Future<void> _pumpGlass(
  WidgetTester tester, {
  required ThemeData theme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: const Scaffold(
        body: GlassCard(child: Text('header')),
      ),
    ),
  );
}

void main() {
  testWidgets('GlassCard fill follows Imperial Gold cardSurface', (tester) async {
    const palette = AppColorsTheme.imperialGold;
    await _pumpGlass(
      tester,
      theme: ThemeData.dark().copyWith(
        extensions: const <ThemeExtension<dynamic>>[palette],
      ),
    );

    final gradient = _glassDecoration(tester).gradient! as LinearGradient;
    expect(
      gradient.colors.first,
      palette.cardSurface.withValues(alpha: GlassCard.themedFillAlphaDark[0]),
    );
    expect(
      gradient.colors.last,
      palette.surface.withValues(alpha: GlassCard.themedFillAlphaDark[1]),
    );
    expect(
      _glassDecoration(tester).border?.top.color,
      palette.border,
    );
    expect(
      gradient.colors.first,
      isNot(const Color(0xFF161922).withValues(alpha: 0.88)),
    );
  });

  testWidgets('GlassCard fill follows Sky Blue cardSurface', (tester) async {
    const palette = AppColorsTheme.skyBlue;
    await _pumpGlass(
      tester,
      theme: ThemeData.light().copyWith(
        extensions: const <ThemeExtension<dynamic>>[palette],
      ),
    );

    final gradient = _glassDecoration(tester).gradient! as LinearGradient;
    expect(
      gradient.colors.first,
      palette.cardSurface.withValues(alpha: GlassCard.themedFillAlphaLight[0]),
    );
    expect(
      gradient.colors.last,
      palette.surface.withValues(alpha: GlassCard.themedFillAlphaLight[1]),
    );
    expect(gradient.colors.first, isNot(Colors.white.withValues(alpha: 0.92)));
  });

  testWidgets('GlassCard fill follows Midnight OLED cardSurface', (tester) async {
    const palette = AppColorsTheme.midnightOled;
    await _pumpGlass(
      tester,
      theme: ThemeData.dark().copyWith(
        extensions: const <ThemeExtension<dynamic>>[palette],
      ),
    );

    final gradient = _glassDecoration(tester).gradient! as LinearGradient;
    expect(
      gradient.colors.first,
      palette.cardSurface.withValues(alpha: GlassCard.themedFillAlphaDark[0]),
    );
  });
}
