import 'package:am_common/am_common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/domain/entities/portfolio_intelligence.dart';
import 'portfolio_providers.dart';

/// Fetches intelligence only when master + at least one of health/risk/xray is on.
final portfolioIntelligenceProvider = FutureProvider.autoDispose
    .family<PortfolioIntelligence?, String>((ref, portfolioId) async {
  final master = ref.watch(portfolioIntelligenceOverviewEnabledProvider);
  if (!master) return null;

  final needHealth = ref.watch(portfolioIntelHealthEnabledProvider);
  final needRisk = ref.watch(portfolioIntelRiskEnabledProvider);
  final needXray = ref.watch(portfolioIntelXrayEnabledProvider);
  if (!needHealth && !needRisk && !needXray) return null;

  if (portfolioId.isEmpty || portfolioId == 'all') return null;

  final remote = await ref.watch(portfolioRemoteDataSourceProvider.future);
  return remote.getPortfolioIntelligence(portfolioId);
});
