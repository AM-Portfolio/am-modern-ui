import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/core/config/feature_flags.dart';

void main() {
  group('FeatureFlags', () {
    late FeatureFlags flags;

    setUp(() {
      flags = FeatureFlags();
      flags.resetToDefaults();
    });

    test('enableSecurityAlertBanner defaults to false', () {
      expect(flags.enableSecurityAlertBanner, isFalse);
    });

    test('enableSecurityAlertBanner can be set and reset', () {
      flags.enableSecurityAlertBanner = true;
      expect(flags.enableSecurityAlertBanner, isTrue);

      flags.resetToDefaults();
      expect(flags.enableSecurityAlertBanner, isFalse);
    });

    test('toJson and fromJson preserve enableSecurityAlertBanner', () {
      flags.enableSecurityAlertBanner = true;
      final json = flags.toJson();
      expect(json['enableSecurityAlertBanner'], isTrue);

      flags.resetToDefaults();
      expect(flags.enableSecurityAlertBanner, isFalse);

      flags.fromJson(json);
      expect(flags.enableSecurityAlertBanner, isTrue);
    });
  });
}
