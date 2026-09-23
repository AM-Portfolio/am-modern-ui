import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'feature_flag_keys.dart';
import 'feature_flag_service.dart';

/// Debug-only dogfood: `--dart-define=AM_INTEL_FORCE_ON=true`
/// Forces all portfolio intelligence flags ON. Ignored in release builds.
bool get intelFlagsForcedOn =>
    kDebugMode &&
    const bool.fromEnvironment('AM_INTEL_FORCE_ON', defaultValue: false);

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

final offlineReadsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(featureFlagProvider(FeatureFlagKeys.offlineReadsV1));
});

final offlineWritesEnabledProvider = Provider<bool>((ref) {
  final reads = ref.watch(offlineReadsEnabledProvider);
  if (!reads) return false;
  return ref.watch(featureFlagProvider(FeatureFlagKeys.offlineWritesV1));
});

/// Master intel flag stays fail-closed. Child widgets default ON once master is on.
bool _intelFlag(Ref ref, String key, {bool defaultValue = false}) {
  if (intelFlagsForcedOn) return true;
  try {
    ref.watch(featureFlagsReadyProvider);
    return ref.watch(featureFlagServiceProvider).isOn(
          key,
          defaultValue: defaultValue,
        );
  } catch (_) {
    return defaultValue;
  }
}

final portfolioIntelligenceOverviewEnabledProvider = Provider<bool>((ref) {
  return _intelFlag(ref, FeatureFlagKeys.portfolioIntelligenceOverviewV1);
});

final portfolioIntelHealthEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(portfolioIntelligenceOverviewEnabledProvider)) return false;
  return _intelFlag(
    ref,
    FeatureFlagKeys.portfolioIntelHealthV1,
    defaultValue: true,
  );
});

final portfolioIntelRiskEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(portfolioIntelligenceOverviewEnabledProvider)) return false;
  return _intelFlag(
    ref,
    FeatureFlagKeys.portfolioIntelRiskV1,
    defaultValue: true,
  );
});

final portfolioIntelXrayEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(portfolioIntelligenceOverviewEnabledProvider)) return false;
  return _intelFlag(
    ref,
    FeatureFlagKeys.portfolioIntelXrayV1,
    defaultValue: true,
  );
});

final portfolioIntelStressEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(portfolioIntelligenceOverviewEnabledProvider)) return false;
  return _intelFlag(
    ref,
    FeatureFlagKeys.portfolioIntelStressV1,
    defaultValue: true,
  );
});

final portfolioIntelWhatIfEnabledProvider = Provider<bool>((ref) {
  if (!ref.watch(portfolioIntelligenceOverviewEnabledProvider)) return false;
  return _intelFlag(
    ref,
    FeatureFlagKeys.portfolioIntelWhatIfV1,
    defaultValue: true,
  );
});
