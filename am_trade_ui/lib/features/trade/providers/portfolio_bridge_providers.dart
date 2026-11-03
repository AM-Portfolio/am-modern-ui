import 'package:am_common/core/di/network_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/data/datasources/portfolio_overview_data_source.dart';

/// Shared am-portfolio bridge used by Trade cards + holdings 1D overlay.
final portfolioOverviewDataSourceProvider =
    FutureProvider<PortfolioOverviewDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final appConfig = await ref.watch(appConfigProvider.future);

  return PortfolioOverviewDataSourceImpl(
    apiClient: apiClient,
    portfolioConfig: appConfig.api.portfolio,
  );
});
