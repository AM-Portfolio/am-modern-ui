import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_common/core/network/api_client.dart';
import 'internal/data/datasources/trade_controller_remote_data_source.dart';
import 'internal/data/dtos/metrics_filter_config_dto.dart';
import 'internal/data/repositories/trade_controller_repository_impl.dart';
import 'internal/domain/entities/trade_controller_entities.dart';
import 'internal/domain/repositories/trade_controller_repository.dart';
import 'package:am_common/core/di/network_providers.dart';

// ============================================================================
// Infrastructure Providers (Private - for dependency injection)
// ============================================================================

/// Provider for TradeControllerRemoteDataSource
final _tradeControllerRemoteDataSourceProvider = FutureProvider<TradeControllerRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);

  return TradeControllerRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for TradeControllerRepository
final _tradeControllerRepositoryProvider = FutureProvider<TradeControllerRepository>((ref) async {
  final remoteDataSource = await ref.watch(_tradeControllerRemoteDataSourceProvider.future);

  return TradeControllerRepositoryImpl(remoteDataSource: remoteDataSource);
});

// ============================================================================
// Public Providers (For UI consumption)
// ============================================================================

/// Provider to get trade details by portfolio ID and optional symbols
/// Returns a FutureProvider with the list of trade details
final tradeDetailsByPortfolioProvider =
    FutureProvider.family<List<TradeDetails>, ({String portfolioId, List<String>? symbols})>((ref, params) async {
      final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
      return repository.getTradeDetailsByPortfolioAndSymbols(portfolioId: params.portfolioId, symbols: params.symbols);
    });

/// Provider to watch trade details for a portfolio with real-time updates
/// Returns a StreamProvider with trade details that update automatically
final watchTradesByPortfolioProvider = StreamProvider.family<List<TradeDetails>, String>((ref, portfolioId) async* {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  yield* repository.watchTradeDetailsByPortfolio(portfolioId);
});

/// Provider to get trades by various filter criteria with pagination
/// Returns a FutureProvider with paginated trade response
final tradesByFiltersProvider =
    FutureProvider.family<
      PaginatedTradeResponse,
      ({
        List<String>? portfolioIds,
        List<String>? symbols,
        List<String>? statuses,
        DateTime? startDate,
        DateTime? endDate,
        List<String>? strategies,
        int page,
        int size,
        String? sort,
      })
    >((ref, params) async {
      final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
      return repository.getTradesByFilters(
        portfolioIds: params.portfolioIds,
        symbols: params.symbols,
        statuses: params.statuses,
        startDate: params.startDate,
        endDate: params.endDate,
        strategies: params.strategies,
        page: params.page,
        size: params.size,
        sort: params.sort,
      );
    });

/// Provider to get trade details by trade IDs
/// Returns a FutureProvider with the list of trade details
final tradeDetailsByIdsProvider = FutureProvider.family<List<TradeDetails>, List<String>>((ref, tradeIds) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return repository.getTradeDetailsByTradeIds(tradeIds);
});

/// Provider to filter trade details using favorite filter or metrics config
/// Returns a FutureProvider with filtered trade details response
final filterTradeDetailsProvider =
    FutureProvider.family<
      FilterTradeDetailsResponse,
      ({
        String userId,
        String? favoriteFilterId,
        MetricsFilterConfigDto? metricsConfig,
        int page,
        int size,
        String? sort,
      })
    >((ref, params) async {
      final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
      return repository.filterTradeDetails(
        userId: params.userId,
        favoriteFilterId: params.favoriteFilterId,
        metricsConfig: params.metricsConfig,
        page: params.page,
        size: params.size,
        sort: params.sort,
      );
    });

// ============================================================================
// Action Providers (For mutation operations)
// ============================================================================

/// Provider to add a new trade
/// Usage: ref.read(addTradeProvider)(tradeDetails)
final addTradeProvider = FutureProvider<Future<TradeDetails> Function(TradeDetails)>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return (tradeDetails) async {
    final result = await repository.addTrade(tradeDetails);
    // Invalidate related providers to trigger refresh
    ref.invalidate(tradeDetailsByPortfolioProvider);
    ref.invalidate(watchTradesByPortfolioProvider);
    return result;
  };
});

/// Provider to update an existing trade
/// Usage: ref.read(updateTradeProvider)((tradeId: '...', tradeDetails: ...))
final updateTradeProvider = FutureProvider<Future<TradeDetails> Function(({String tradeId, TradeDetails tradeDetails}))>((
  ref,
) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return (params) async {
    final result = await repository.updateTrade(tradeId: params.tradeId, tradeDetails: params.tradeDetails);
    // Invalidate related providers to trigger refresh
    ref.invalidate(tradeDetailsByPortfolioProvider);
    ref.invalidate(watchTradesByPortfolioProvider);
    return result;
  };
});

/// Provider to add or update multiple trades in batch
/// Usage: ref.read(batchUpdateTradesProvider)(tradesList)
final batchUpdateTradesProvider = FutureProvider<Future<List<TradeDetails>> Function(List<TradeDetails>)>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return (trades) async {
    final result = await repository.addOrUpdateTrades(trades);
    // Invalidate related providers to trigger refresh
    ref.invalidate(tradeDetailsByPortfolioProvider);
    ref.invalidate(watchTradesByPortfolioProvider);
    return result;
  };
});

/// Provider to clear repository cache
/// Usage: await ref.read(clearTradeCacheProvider)()
final clearTradeCacheProvider = FutureProvider<Future<void> Function()>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return () async {
    await repository.clearCache();
    // Invalidate all providers to trigger refresh
    ref.invalidate(tradeDetailsByPortfolioProvider);
    ref.invalidate(watchTradesByPortfolioProvider);
    ref.invalidate(tradesByFiltersProvider);
    ref.invalidate(tradeDetailsByIdsProvider);
    ref.invalidate(filterTradeDetailsProvider);
  };
});

/// Provider to refresh trades for a specific portfolio
/// Usage: await ref.read(refreshPortfolioTradesProvider)(portfolioId)
final refreshPortfolioTradesProvider = FutureProvider<Future<void> Function(String)>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return (portfolioId) async {
    await repository.refreshPortfolioTrades(portfolioId);
    // Invalidate related providers for this portfolio
    ref.invalidate(tradeDetailsByPortfolioProvider);
    ref.invalidate(watchTradesByPortfolioProvider);
  };
});
