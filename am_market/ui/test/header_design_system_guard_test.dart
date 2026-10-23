import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('header sources ban hardcoded chrome and fake market numbers', () {
    const files = [
      'lib/features/equity_insider/presentation/widgets/equity_insider_header_card.dart',
      'lib/features/equity_insider/presentation/widgets/equity_insider_hero.dart',
      'lib/features/f_o/presentation/widgets/fo_header_card.dart',
    ];
    const banned = [
      r'Color(0x',
      'Color.fromRGBO',
      'Color.fromARGB',
      'Colors.red',
      'Colors.green',
      'Colors.blue',
      'Colors.white',
      'Colors.black',
      'chartBlue',
      "'493.4%'",
      '"493.4%"',
      "'0.54'",
      '"0.54"',
      '?? 65',
      '_syntheticSparkline',
      'fontSize: 11',
      'fontSize: 12.5',
      'fontSize: 17',
      "colorScheme: 'info'",
      'colorScheme: "info"',
    ];

    for (final rel in files) {
      final file = File(rel);
      expect(file.existsSync(), isTrue, reason: 'missing $rel');
      final src = file.readAsStringSync();
      for (final token in banned) {
        expect(
          src.contains(token),
          isFalse,
          reason: '$rel contains banned token `$token`',
        );
      }
    }
  });
}
