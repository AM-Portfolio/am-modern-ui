import 'package:am_design_system/am_design_system.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/domain/entities/portfolio_holding.dart';
import '../internal/domain/entities/portfolio_summary.dart';
import '../internal/domain/entities/portfolio_analytics.dart';
import '../internal/domain/entities/portfolio_analytics_request.dart';
import '../internal/domain/repositories/portfolio_repository.dart';
import '../internal/domain/repositories/portfolio_analytics_repository.dart';
import '../internal/domain/usecases/get_portfolio_holdings.dart';
import '../internal/domain/usecases/get_portfolio_summary.dart';
import '../internal/domain/usecases/get_portfolio_analytics.dart';
import '../internal/domain/usecases/get_portfolios_list.dart';

import '../internal/data/repositories/portfolio_repository_impl.dart';
import '../internal/data/repositories/portfolio_analytics_repository_impl.dart';
import '../internal/data/datasources/portfolio_remote_data_source.dart';
import '../internal/services/portfolio_service.dart';
import '../internal/services/portfolio_analytics_service.dart';
import '../internal/data/datasources/local/portfolio_local_data_source.dart';

import 'package:am_common/am_common.dart'; // Includes network_providers, logger, config

part 'portfolio_providers.g.dart';

/// Portfolio feature providers
/// These providers are specific to the portfolio feature and follow clean architecture.
/// They manage the portfolio feature's internal dependencies and use cases.

/// Data layer providers
@riverpod
Future<PortfolioRemoteDataSource> portfolioRemoteDataSource(Ref ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return PortfolioRemoteDataSourceImpl(
    apiClient: apiClient,
  );
}

final portfolioLocalDataSourceProvider = FutureProvider<PortfolioLocalDataSource>((ref) async {
  CommonLogger.debug(
    'Creating PortfolioLocalDataSource instance',
    tag: 'PortfolioProviders',
  );
  final dataSource = PortfolioLocalDataSource();
  await dataSource.init();
  return dataSource;
});

@riverpod
Future<PortfolioRepository> portfolioRepository(Ref ref) async {
  CommonLogger.debug(
    'Creating PortfolioRepository instance',
    tag: 'PortfolioProviders',
  );
  final remoteDataSource = await ref.watch(
    portfolioRemoteDataSourceProvider.future,
  );
  final localDataSource = await ref.watch(
    portfolioLocalDataSourceProvider.future,
  );
  return PortfolioRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
  );
}

/// Use case providers
@riverpod
Future<GetPortfolioHoldings> getPortfolioHoldings(Ref ref) async {
  CommonLogger.debug(
    'Creating GetPortfolioHoldings use case',
    tag: 'PortfolioProviders',
  );
  final repository = await ref.watch(portfolioRepositoryProvider.future);
  return GetPortfolioHoldings(repository);
}

@riverpod
Future<GetPortfolioSummary> getPortfolioSummary(Ref ref) async {
  CommonLogger.debug(
    'Creating GetPortfolioSummary use case',
    tag: 'PortfolioProviders',
  );
  final repository = await ref.watch(portfolioRepositoryProvider.future);
  return GetPortfolioSummary(repository);
}

@riverpod
Future<GetPortfoliosList> getPortfoliosList(Ref ref) async {
  CommonLogger.debug(
    'Creating GetPortfoliosList use case',
    tag: 'PortfolioProviders',
  );
  final repository = await ref.watch(portfolioRepositoryProvider.future);
  return GetPortfoliosList(repository);
}

/// Analytics providers
@riverpod
Future<PortfolioAnalyticsRepository> portfolioAnalyticsRepository(
  Ref ref,
) async {
  CommonLogger.debug(
    'Creating PortfolioAnalyticsRepository instance',
    tag: 'PortfolioProviders',
  );
  final remoteDataSource = await ref.watch(
    portfolioRemoteDataSourceProvider.future,
  );
  return PortfolioAnalyticsRepositoryImpl(remoteDataSource: remoteDataSource);
}

@riverpod
Future<GetPortfolioAnalytics> getPortfolioAnalytics(Ref ref) async {
  CommonLogger.debug(
    'Creating GetPortfolioAnalytics use case',
    tag: 'PortfolioProviders',
  );
  final repository = await ref.watch(
    portfolioAnalyticsRepositoryProvider.future,
  );
  return GetPortfolioAnalytics(repository);
}

/// Service layer providers
@riverpod
Future<PortfolioService> portfolioService(Ref ref) async {
  CommonLogger.debug(
    'Creating PortfolioService instance',
    tag: 'PortfolioProviders',
  );
  final getHoldings = await ref.watch(getPortfolioHoldingsProvider.future);
  final getSummary = await ref.watch(getPortfolioSummaryProvider.future);
  final getPortfoliosList = await ref.watch(getPortfoliosListProvider.future);

  return PortfolioService(getHoldings, getSummary, getPortfoliosList);
}

@riverpod
Future<PortfolioAnalyticsService> portfolioAnalyticsService(Ref ref) async {
  CommonLogger.debug(
    'Creating PortfolioAnalyticsService instance',
    tag: 'PortfolioProviders',
  );
  final getAnalytics = await ref.watch(getPortfolioAnalyticsProvider.future);

  return PortfolioAnalyticsService(getAnalytics);
}

/// Data providers - Auto-dispose (can be recreated when needed)
@riverpod
Future<PortfolioHoldings> portfolioHoldings(Ref ref, String userId) async {
  final useCase = await ref.watch(getPortfolioHoldingsProvider.future);
  return useCase.call(userId);
}

@riverpod
Future<PortfolioHoldings> portfolioHoldingsById(
  Ref ref,
  String userId,
  String portfolioId,
) async {
  final useCase = await ref.watch(getPortfolioHoldingsProvider.future);
  return useCase.call(userId, portfolioId);
}

@riverpod
Future<PortfolioSummary> portfolioSummary(Ref ref, String userId) async {
  final useCase = await ref.watch(getPortfolioSummaryProvider.future);
  return useCase.call(userId);
}

@riverpod
Stream<PortfolioHoldings> portfolioHoldingsStream(
  Ref ref,
  String userId,
) async* {
  final useCase = await ref.watch(getPortfolioHoldingsProvider.future);
  yield* useCase.watchHoldings(userId);
}

@riverpod
Stream<PortfolioSummary> portfolioSummaryStream(Ref ref, String userId) async* {
  final useCase = await ref.watch(getPortfolioSummaryProvider.future);
  yield* useCase.watchSummary(userId);
}

/// Analytics data providers - Auto-dispose (can be recreated when needed)
@riverpod
Future<PortfolioAnalytics> portfolioAnalytics(
  Ref ref,
  PortfolioAnalyticsRequest request,
) async {
  final useCase = await ref.watch(getPortfolioAnalyticsProvider.future);
  return useCase.call(request);
}

@riverpod
Future<PortfolioAnalytics> portfolioAnalyticsWithDefaults(
  Ref ref,
  String portfolioId,
) async {
  final service = await ref.watch(portfolioAnalyticsServiceProvider.future);
  return service.getPortfolioAnalyticsWithDefaults(portfolioId);
}

@riverpod
Future<Heatmap?> portfolioHeatmap(Ref ref, String portfolioId) async {
  final service = await ref.watch(portfolioAnalyticsServiceProvider.future);
  return service.getPortfolioHeatmap(portfolioId);
}

@riverpod
Future<Movers?> portfolioMovers(
  Ref ref,
  String portfolioId, {
  int limit = 10,
}) async {
  final service = await ref.watch(portfolioAnalyticsServiceProvider.future);
  return service.getPortfolioMovers(portfolioId, limit: limit);
}

@riverpod
Future<AllocationData> portfolioAllocations(Ref ref, String portfolioId) async {
  final service = await ref.watch(portfolioAnalyticsServiceProvider.future);
  return service.getPortfolioAllocations(portfolioId);
}
