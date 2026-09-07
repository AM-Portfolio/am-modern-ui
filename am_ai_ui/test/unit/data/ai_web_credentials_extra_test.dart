import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors the web credentials helper's map-copy rule so VM tests catch
/// unmodifiable `extra` crashes without importing `dio/browser.dart`.
Map<String, dynamic> copyExtraWithCredentials(Map<String, dynamic> extra) {
  return Map<String, dynamic>.from(extra)..['withCredentials'] = true;
}

void main() {
  test('copies const/unmodifiable extra before withCredentials write', () {
    final frozen = Map<String, dynamic>.unmodifiable(
      const {'withCredentials': false},
    );
    expect(
      () => frozen['withCredentials'] = true,
      throwsUnsupportedError,
    );

    final mutable = copyExtraWithCredentials(frozen);
    expect(mutable['withCredentials'], isTrue);
    expect(() => mutable['retry'] = 1, returnsNormally);
  });

  test('BaseOptions const extra must be replaced before mutate', () {
    final dio = Dio(
      BaseOptions(
        extra: const {'withCredentials': true},
      ),
    );
    expect(
      () => dio.options.extra['withCredentials'] = true,
      throwsUnsupportedError,
    );

    dio.options.extra = copyExtraWithCredentials(dio.options.extra);
    expect(dio.options.extra['withCredentials'], isTrue);
  });
}
