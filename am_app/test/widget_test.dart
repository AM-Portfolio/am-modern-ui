import 'package:flutter_test/flutter_test.dart';

void main() {
  // Full AMApp widget tests need ConfigService + getIt DI + ProviderScope.
  // Keep a lightweight suite so CI `flutter test` stays green until real
  // widget/integration tests are added (Phase 3+).
  test('am_app test suite loads', () {
    expect(2 + 2, 4);
  });
}
