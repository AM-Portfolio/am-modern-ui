import 'package:flutter_test/flutter_test.dart';
import 'package:am_auth_ui/features/authentication/presentation/cubit/feature_flag_cubit.dart';
import 'package:am_design_system/core/config/feature_flags.dart';

void main() {
  group('FeatureFlagCubit', () {
    late FeatureFlagCubit cubit;

    setUp(() {
      FeatureFlags().resetToDefaults();
      cubit = FeatureFlagCubit();
    });

    tearDown(() {
      cubit.close();
      FeatureFlags().resetToDefaults();
    });

    test('initial state has enableSecurityAlertBanner false', () {
      expect(cubit.state.flags.enableSecurityAlertBanner, isFalse);
    });

    test('updateBoolFlag toggles enableSecurityAlertBanner', () {
      cubit.updateBoolFlag('enableSecurityAlertBanner', true);
      expect(cubit.state.flags.enableSecurityAlertBanner, isTrue);

      cubit.updateBoolFlag('enableSecurityAlertBanner', false);
      expect(cubit.state.flags.enableSecurityAlertBanner, isFalse);
    });

    test('resetToDefaults resets enableSecurityAlertBanner', () {
      cubit.updateBoolFlag('enableSecurityAlertBanner', true);
      expect(cubit.state.flags.enableSecurityAlertBanner, isTrue);

      cubit.resetToDefaults();
      expect(cubit.state.flags.enableSecurityAlertBanner, isFalse);
    });
  });
}
