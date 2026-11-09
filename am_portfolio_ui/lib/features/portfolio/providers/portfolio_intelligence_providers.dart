import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/domain/entities/portfolio_intelligence.dart';
import 'portfolio_providers.dart';

/// Portfolio ids that already got one cold-confidence refresh this session.
/// Prevents a 3s invalidate loop when the server stays below 0.9.
final _coldRefreshAttempted = <String>{};

/// Shared Health / X-Ray / Risk fetch for one portfolio id (`all`, `all|persona`, or book id).
///
/// Industry pattern:
/// - one in-flight POST per id (widgets only watch)
/// - keepAlive briefly so portfolio switch does not cancel mid-request
/// - at most one deferred refresh when confidence is still cold
final portfolioIntelligenceProvider = FutureProvider.autoDispose
    .family<PortfolioIntelligence?, String>((ref, portfolioId) async {
  final master = ref.watch(portfolioIntelligenceOverviewEnabledProvider);
  if (!master) return null;

  final needHealth = ref.watch(portfolioIntelHealthEnabledProvider);
  final needRisk = ref.watch(portfolioIntelRiskEnabledProvider);
  final needXray = ref.watch(portfolioIntelXrayEnabledProvider);
  if (!needHealth && !needRisk && !needXray) return null;

  if (portfolioId.isEmpty) return null;

  // Survive brief unmount/remount when Overview swaps ValueKeys on switch.
  final link = ref.keepAlive();
  Timer? disposeTimer;
  Timer? coldRefreshTimer;
  ref.onCancel(() {
    disposeTimer?.cancel();
    disposeTimer = Timer(const Duration(seconds: 45), link.close);
  });
  ref.onResume(() {
    disposeTimer?.cancel();
  });
  ref.onDispose(() {
    disposeTimer?.cancel();
    coldRefreshTimer?.cancel();
  });

  final remote = await ref.watch(portfolioRemoteDataSourceProvider.future);
  final first = await remote.getPortfolioIntelligence(portfolioId);

  // One deferred refresh only — owned here, never from widget post-frame invalidates
  // (those raced with portfolio switch and closed ProviderSubscriptions mid-build).
  final confidence = first.confidence ?? 0;
  if (confidence >= 0.9) {
    _coldRefreshAttempted.remove(portfolioId);
  } else if (_coldRefreshAttempted.add(portfolioId)) {
    coldRefreshTimer = Timer(const Duration(seconds: 3), () {
      if (!ref.mounted) return;
      ref.invalidateSelf();
    });
  }

  return first;
});
