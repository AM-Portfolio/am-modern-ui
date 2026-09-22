import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../../config/config_service.dart';
import '../feature_flag_provider.dart';
import '../feature_flag_service.dart';
import 'news_feature_flag_keys.dart';
import 'news_ui_surface.dart';

/// Master News kill switch (`news-ui-enabled`).
///
/// Prod flavor defaults off when GrowthBook is down; other envs default on.
final newsUiEnabledProvider = Provider<bool>((ref) {
  final defaultValue = ConfigService.resolvedEnv != 'prod';
  try {
    ref.watch(featureFlagsReadyProvider);
    return ref.watch(featureFlagServiceProvider).isOn(
          NewsFeatureFlagKeys.enabled,
          defaultValue: defaultValue,
        );
  } catch (_) {
    return defaultValue;
  }
});

bool _surfaceFlag(Ref ref, String key) {
  try {
    ref.watch(featureFlagsReadyProvider);
    // When master is on, surfaces default on until GB turns them off.
    return ref.watch(featureFlagServiceProvider).isOn(
          key,
          defaultValue: true,
        );
  } catch (_) {
    return true;
  }
}

/// True only when master AND the page surface flag are on.
final newsUiSurfaceEnabledProvider =
    Provider.family<bool, NewsUiSurface>((ref, surface) {
  if (!ref.watch(newsUiEnabledProvider)) return false;
  return _surfaceFlag(ref, NewsFeatureFlagKeys.keyFor(surface));
});

/// Test helper: register a no-op service when GetIt is empty in unit tests.
bool get newsFeatureFlagsGetItReady =>
    GetIt.instance.isRegistered<FeatureFlagService>();
