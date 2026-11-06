import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final dir = Directory('assets/config/strategies');

  test('strategy templates exist and ZONE_SCALE sizePct sums to 100', () {
    expect(dir.existsSync(), isTrue);
    final zoneFile = File('${dir.path}/ZONE_SCALE.json');
    expect(zoneFile.existsSync(), isTrue);
    final map = jsonDecode(zoneFile.readAsStringSync()) as Map<String, dynamic>;
    final layers = (map['layers'] as List).cast<Map<String, dynamic>>();
    final sum = layers.fold<num>(0, (a, l) => a + (l['sizePct'] as num));
    expect(sum, 100);
    expect(map['minLayers'], lessThanOrEqualTo(layers.length));
    expect(map['maxLayers'], greaterThanOrEqualTo(layers.length));
  });

  test('supported engines LINE_LEVEL ZONE_SCALE SUPER_BRACKET are marked supported', () {
    for (final id in ['LINE_LEVEL', 'ZONE_SCALE', 'SUPER_BRACKET']) {
      final map = jsonDecode(File('${dir.path}/$id.json').readAsStringSync())
          as Map<String, dynamic>;
      expect(map['strategyId'], id);
      expect(map['supported'], isTrue);
    }
  });
}
