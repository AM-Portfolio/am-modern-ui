import 'dart:async';

import 'package:am_common/am_common.dart'; // Fixed: use package import
import '../../domain/entities/trade_controller_entities.dart';
import '../../domain/repositories/trade_controller_repository.dart';
import '../datasources/trade_controller_remote_data_source.dart';
import '../dtos/metrics_filter_config_dto.dart';
import '../dtos/trade_controller_dtos.dart';
import '../mappers/trade_controller_mapper.dart';
import 'package:am_library/am_library.dart';
import 'dart:convert';

/// Implementation of TradeControllerRepository
/// Handles caching, data transformation, and stream management for trade data
class TradeControllerRepositoryImpl implements TradeControllerRepository {
  TradeControllerRepositoryImpl({
    required TradeControllerRemoteDataSource remoteDataSource,
    AmStompClient? stompClient,
  }) : _remoteDataSource = remoteDataSource,
       _stompClient = stompClient;

  final TradeControllerRemoteDataSource _remoteDataSource;
  final AmStompClient? _stompClient;
  StreamSubscription? _stompSubscription;

  // Cache for portfolio trades
  final Map<String, List<TradeDetails>> _portfolioTradesCache = {};

  // Stream controller for real-time trade updates
  final _tradeUpdatesController = StreamController<List<TradeDetails>>.broadcast();

  @override
  Future<List<TradeDetails>> getTradeDetailsByPortfolioAndSymbols({
    required String portfolioId,
    List<String>? symbols,
  }) async {
    AppLogger.methodEntry(
      'getTradeDetailsByPortfolioAndSymbols',
      tag: 'TradeControllerRepository',
      params: {'portfolioId': portfolioId, 'symbols': symbols},
    );

    try {
      final dtos = await _remoteDataSource.getTradeDetailsByPortfolioAndSymbols(
        portfolioId: portfolioId,
        symbols: symbols,
      );

      final trades = dtos.map(TradeControllerMapper.toTradeDetailsEntity).toList().cast<TradeDetails>();

      // Update cache
      final cacheKey = symbols != null && symbols.isNotEmpty ? '$portfolioId-${symbols.join('_')}' : portfolioId;
      _portfolioTradesCache[cacheKey] = trades;

      // Notify stream listeners
      _tradeUpdatesController.add(trades);

      AppLogger.methodExit('getTradeDetailsByPortfolioAndSymbols', tag: 'TradeControllerRepository');
      return trades;
    } catch (e) {
      AppLogger.error(
        'Failed to get trade details by portfolio',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Stream<List<TradeDetails>> watchTradeDetailsByPortfolio(String portfolioId) {
    AppLogger.methodEntry(
      'watchTradeDetailsByPortfolio',
      tag: 'TradeControllerRepository',
      params: {'portfolioId': portfolioId},
    );

    // We don't have userId here easily, but usually it's better to subscribe by userId
    // However, if we're in the context of a portfolio, we might want to filter
    // For now, let's assume we use the global userId from AuthCubit (handled in providers)
    // Or we can implement a generic subscription.
    
    // Create a stream controller for this specific portfolio
    final controller = StreamController<List<TradeDetails>>();

    // Add existing cache if available
    if (_portfolioTradesCache.containsKey(portfolioId)) {
      controller.add(_portfolioTradesCache[portfolioId]!);
    } else {
      // Fetch initial data
      getTradeDetailsByPortfolioAndSymbols(portfolioId: portfolioId).then((trades) {
        if (!controller.isClosed) {
          controller.add(trades);
        }
      });
    }

    // Listen to updates and forward them
    final subscription = _tradeUpdatesController.stream.listen((trades) {
      if (!controller.isClosed) {
        controller.add(trades);
      }
    });

    // Clean up when stream is cancelled
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<TradeDetails> addTrade(TradeDetails tradeDetails) async {
    AppLogger.methodEntry('addTrade', tag: 'TradeControllerRepository');

    try {
      final dto = TradeControllerMapper.toTradeDetailsDto(tradeDetails);
      final responseDto = await _remoteDataSource.addTrade(dto);
      final trade = TradeControllerMapper.toTradeDetailsEntity(responseDto);

      // Refresh cache for the portfolio
      await refreshPortfolioTrades(trade.portfolioId);

      AppLogger.methodExit('addTrade', tag: 'TradeControllerRepository');
      return trade;
    } catch (e) {
      AppLogger.error(
        'Failed to add trade',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<TradeDetails> updateTrade({required String tradeId, required TradeDetails tradeDetails}) async {
    AppLogger.methodEntry('updateTrade', tag: 'TradeControllerRepository', params: {'tradeId': tradeId});

    try {
      final dto = TradeControllerMapper.toTradeDetailsDto(tradeDetails);
      final responseDto = await _remoteDataSource.updateTrade(tradeId: tradeId, tradeDetails: dto);
      final trade = TradeControllerMapper.toTradeDetailsEntity(responseDto);

      // Refresh cache for the portfolio
      await refreshPortfolioTrades(trade.portfolioId);

      AppLogger.methodExit('updateTrade', tag: 'TradeControllerRepository');
      return trade;
    } catch (e) {
      AppLogger.error(
        'Failed to update trade',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteTrade(String tradeId) async {
    AppLogger.methodEntry('deleteTrade', tag: 'TradeControllerRepository', params: {'tradeId': tradeId});

    try {
      await _remoteDataSource.deleteTrade(tradeId);

      // Clear cache to force refresh
      await clearCache();

      AppLogger.methodExit('deleteTrade', tag: 'TradeControllerRepository');
    } catch (e) {
      AppLogger.error(
        'Failed to delete trade',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<PaginatedTradeResponse> getTradesByFilters({
    List<String>? portfolioIds,
    List<String>? symbols,
    List<String>? statuses,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? strategies,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    AppLogger.methodEntry('getTradesByFilters', tag: 'TradeControllerRepository');

    try {
      final responseDto = await _remoteDataSource.getTradesByFilters(
        portfolioIds: portfolioIds,
        symbols: symbols,
        statuses: statuses,
        startDate: startDate?.toIso8601String().split('T').first,
        endDate: endDate?.toIso8601String().split('T').first,
        strategies: strategies,
        page: page,
        size: size,
        sort: sort,
      );

      final response = TradeControllerMapper.toPaginatedTradeResponseEntity(responseDto);

      AppLogger.methodExit('getTradesByFilters', tag: 'TradeControllerRepository');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to get trades by filters',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeDetails>> addOrUpdateTrades(List<TradeDetails> trades) async {
    AppLogger.methodEntry('addOrUpdateTrades', tag: 'TradeControllerRepository', params: {'count': trades.length});

    try {
      final dtos = trades.map(TradeControllerMapper.toTradeDetailsDto).toList().cast<TradeDetailsDto>();
      final responseDtos = await _remoteDataSource.addOrUpdateTrades(dtos);
      final updatedTrades = responseDtos.map(TradeControllerMapper.toTradeDetailsEntity).toList().cast<TradeDetails>();

      // Refresh cache for affected portfolios
      final portfolioIds = updatedTrades.map((t) => t.portfolioId).toSet();
      for (final portfolioId in portfolioIds) {
        await refreshPortfolioTrades(portfolioId);
      }

      AppLogger.methodExit('addOrUpdateTrades', tag: 'TradeControllerRepository');
      return updatedTrades;
    } catch (e) {
      AppLogger.error(
        'Failed to add or update trades',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<List<TradeDetails>> getTradeDetailsByTradeIds(List<String> tradeIds) async {
    AppLogger.methodEntry(
      'getTradeDetailsByTradeIds',
      tag: 'TradeControllerRepository',
      params: {'count': tradeIds.length},
    );

    try {
      final dtos = await _remoteDataSource.getTradeDetailsByTradeIds(tradeIds);
      final trades = dtos.map(TradeControllerMapper.toTradeDetailsEntity).toList().cast<TradeDetails>();

      AppLogger.methodExit('getTradeDetailsByTradeIds', tag: 'TradeControllerRepository');
      return trades;
    } catch (e) {
      AppLogger.error(
        'Failed to get trade details by IDs',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<FilterTradeDetailsResponse> filterTradeDetails({
    required String userId,
    String? favoriteFilterId,
    MetricsFilterConfigDto? metricsConfig,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    AppLogger.methodEntry('filterTradeDetails', tag: 'TradeControllerRepository', params: {'userId': userId});

    try {
      final responseDto = await _remoteDataSource.filterTradeDetails(
        userId: userId,
        favoriteFilterId: favoriteFilterId,
        metricsConfig: metricsConfig,
        page: page,
        size: size,
        sort: sort,
      );

      final response = TradeControllerMapper.toFilterTradeDetailsResponseEntity(responseDto);

      AppLogger.methodExit('filterTradeDetails', tag: 'TradeControllerRepository');
      return response;
    } catch (e) {
      AppLogger.error(
        'Failed to filter trade details',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    AppLogger.methodEntry('clearCache', tag: 'TradeControllerRepository');

    _portfolioTradesCache.clear();

    AppLogger.methodExit('clearCache', tag: 'TradeControllerRepository');
  }

  @override
  Future<void> refreshPortfolioTrades(String portfolioId) async {
    AppLogger.methodEntry(
      'refreshPortfolioTrades',
      tag: 'TradeControllerRepository',
      params: {'portfolioId': portfolioId},
    );

    try {
      // Fetch fresh data from server
      await getTradeDetailsByPortfolioAndSymbols(portfolioId: portfolioId);

      AppLogger.methodExit('refreshPortfolioTrades', tag: 'TradeControllerRepository');
    } catch (e) {
      AppLogger.error(
        'Failed to refresh portfolio trades',
        tag: 'TradeControllerRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      rethrow;
    }
  }

  void _ensureWebSocketSubscribed(String userId) {
    if (_stompClient == null) {
      AppLogger.warning('AmStompClient is null. WebSocket features disabled.', tag: 'TradeControllerRepository');
      return;
    }

    final destination = '/user/queue/trade';

    if (_stompSubscription == null) {
      AppLogger.info('📡 Subscribing to: $destination', tag: 'TradeControllerRepository');
      _stompClient!.subscribe(destination);

      _stompSubscription = _stompClient!.messages
          .where((frame) => frame.headers['destination'] == destination)
          .listen(
        (frame) {
          if (frame.body == null) return;
          try {
            final json = jsonDecode(frame.body!);
            AppLogger.info('Received real-time trade update via WebSocket', tag: 'TradeControllerRepository');

            // Handle the trade update
            // If it's a single trade, we might need to refresh the whole list or update the cache
            final trade = TradeControllerMapper.toTradeDetailsEntity(TradeControllerMapper.toTradeDetailsDtoFromJson(json));
            
            // For now, let's just trigger a full refresh of the portfolio to be safe
            refreshPortfolioTrades(trade.portfolioId);
          } catch (e) {
            AppLogger.error('Failed to parse trade STOMP message', error: e, tag: 'TradeControllerRepository');
          }
        },
        onError: (err) => AppLogger.error('STOMP Subscription error', error: err, tag: 'TradeControllerRepository'),
      );
    }
  }

  /// Dispose resources
  void dispose() {
    _stompSubscription?.cancel();
    _stompClient?.unsubscribe('/user/queue/trade');
    _tradeUpdatesController.close();
  }
}

