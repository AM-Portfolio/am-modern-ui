import 'package:flutter_test/flutter_test.dart';
import 'package:am_common/core/feature_flags/feature_flag_config.dart';
import 'package:am_common/core/feature_flags/feature_flag_keys.dart';
import 'package:am_common/core/feature_flags/feature_flag_service.dart';

void main() {
  test('FeatureFlagConfig disabled without client key', () {
    final config = FeatureFlagConfig.fromJson({
      'enabled': true,
      'apiHost': 'https://api.growthbook.asrax.in',
      'clientKey': '',
    });
    expect(config.enabled, isFalse);
  });

  test('FeatureFlagService fails closed when disabled', () async {
    final service = FeatureFlagService(config: FeatureFlagConfig.disabled);
    await service.init();
    expect(
      service.isOn(FeatureFlagKeys.subscriptionPageEnabled),
      isFalse,
    );
    service.dispose();
  });

  test('FeatureFlagService respects defaultValue when disabled', () async {
    final service = FeatureFlagService(config: FeatureFlagConfig.disabled);
    await service.init();
    expect(
      service.isOn(FeatureFlagKeys.subscriptionPageEnabled, defaultValue: true),
      isTrue,
    );
    service.dispose();
  });
}
