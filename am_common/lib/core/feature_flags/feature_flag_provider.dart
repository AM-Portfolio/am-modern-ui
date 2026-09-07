import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../config/config_service.dart';
import 'feature_flag_keys.dart';
import 'feature_flag_service.dart';

final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  if (!GetIt.instance.isRegistered<FeatureFlagService>()) {
    throw StateError('FeatureFlagService is not registered');
  }
  return GetIt.instance<FeatureFlagService>();
});

final featureFlagsReadyProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(featureFlagServiceProvider);
  yield service.isReady;
  yield* service.changes.map((_) => service.isReady);
});

final featureFlagProvider =
    Provider.family<bool, String>((ref, key) {
  ref.watch(featureFlagsReadyProvider);
  return ref.watch(featureFlagServiceProvider).isOn(key);
});

final subscriptionPageEnabledProvider = Provider<bool>((ref) {
  return ref.watch(
    featureFlagProvider(FeatureFlagKeys.subscriptionPageEnabled),
  );
});

final newsUiEnabledProvider = Provider<bool>((ref) {
  final defaultValue = ConfigService.resolvedEnv != 'prod';
  try {
    ref.watch(featureFlagsReadyProvider);
    return ref.watch(featureFlagServiceProvider).isOn(
          FeatureFlagKeys.newsUiEnabled,
          defaultValue: defaultValue,
        );
  } catch (_) {
    return defaultValue;
  }
});

final offlineReadsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagProvider(FeatureFlagKeys.offlineReadsV1));
});

final offlineWritesEnabledProvider = Provider<bool>((ref) {
  final reads = ref.watch(offlineReadsEnabledProvider);
  if (!reads) return false;
  return ref.watch(featureFlagProvider(FeatureFlagKeys.offlineWritesV1));
});
