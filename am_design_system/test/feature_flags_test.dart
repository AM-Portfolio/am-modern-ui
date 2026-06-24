import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/core/config/feature_flags.dart';

void main() {
  // FeatureFlags is a singleton - always call resetToDefaults() after mutation
  // to avoid state leakage between tests.

  tearDown(() {
    FeatureFlags().resetToDefaults();
  });

  group('FeatureFlags', () {
    group('singleton', () {
      test('always returns the same instance', () {
        final a = FeatureFlags();
        final b = FeatureFlags();
        expect(identical(a, b), isTrue);
      });
    });

    group('resetToDefaults', () {
      test('sets useRealBackendAPI to true', () {
        final flags = FeatureFlags();
        // Mutate then reset
        flags.useRealBackendAPI = false;
        flags.resetToDefaults();

        expect(flags.useRealBackendAPI, isTrue);
      });

      test('sets useRealGoogleAuth to false', () {
        final flags = FeatureFlags();
        flags.useRealGoogleAuth = true;
        flags.resetToDefaults();

        expect(flags.useRealGoogleAuth, isFalse);
      });

      test('sets useRealEmailService to false', () {
        final flags = FeatureFlags();
        flags.useRealEmailService = true;
        flags.resetToDefaults();

        expect(flags.useRealEmailService, isFalse);
      });

      test('sets enableMockDelays to true', () {
        final flags = FeatureFlags();
        flags.enableMockDelays = false;
        flags.resetToDefaults();

        expect(flags.enableMockDelays, isTrue);
      });

      test('sets enableErrorSimulation to false', () {
        final flags = FeatureFlags();
        flags.enableErrorSimulation = true;
        flags.resetToDefaults();

        expect(flags.enableErrorSimulation, isFalse);
      });

      test('resets mockApiDelayMs to 1500', () {
        final flags = FeatureFlags();
        flags.mockApiDelayMs = 0;
        flags.resetToDefaults();

        expect(flags.mockApiDelayMs, equals(1500));
      });

      test('resets all error rates to 0.0', () {
        final flags = FeatureFlags();
        flags.networkErrorRate = 0.5;
        flags.serverErrorRate = 0.3;
        flags.authErrorRate = 0.9;
        flags.resetToDefaults();

        expect(flags.networkErrorRate, equals(0.0));
        expect(flags.serverErrorRate, equals(0.0));
        expect(flags.authErrorRate, equals(0.0));
      });

      test('resets session and token intervals', () {
        final flags = FeatureFlags();
        flags.sessionTimeoutMin = 999;
        flags.tokenRefreshIntervalMin = 99;
        flags.resetToDefaults();

        expect(flags.sessionTimeoutMin, equals(30));
        expect(flags.tokenRefreshIntervalMin, equals(5));
      });
    });

    group('initial state', () {
      test('useRealBackendAPI defaults to true', () {
        // After a reset the flag should be true per the PR change
        FeatureFlags().resetToDefaults();
        expect(FeatureFlags().useRealBackendAPI, isTrue);
      });

      test('useRealGoogleAuth defaults to false', () {
        FeatureFlags().resetToDefaults();
        expect(FeatureFlags().useRealGoogleAuth, isFalse);
      });
    });

    group('mutation', () {
      test('flag changes persist until reset', () {
        final flags = FeatureFlags();
        flags.useRealBackendAPI = false;
        expect(FeatureFlags().useRealBackendAPI, isFalse);

        flags.resetToDefaults();
        expect(FeatureFlags().useRealBackendAPI, isTrue);
      });
    });
  });
}