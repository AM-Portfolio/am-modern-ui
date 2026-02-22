import 'package:am_design_system/am_design_system.dart';
import 'dart:async';

import '../../domain/entities/portfolio_holding.dart';
import '../../domain/entities/portfolio_summary.dart';
import '../../domain/entities/portfolio_list.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/portfolio_remote_data_source.dart';
import '../mappers/portfolio_holdings_mapper.dart';
import '../mappers/portfolio_summary_mapper.dart';
import '../mappers/portfolio_list_mapper.dart';
import '../datasources/local/portfolio_local_data_source.dart';
import 'package:am_common/am_common.dart';

/// Repository implementation for portfolio data operations
///
/// Handles portfolio data operations following clean architecture principles
/// - Coordinates between data sources (remote, local cache)
/// - Maps DTOs to domain entities
/// - Provides streams for real-time updates
/// - Implements caching and error handling
class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl({
    required PortfolioRemoteDataSource remoteDataSource,
    required PortfolioLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final PortfolioRemoteDataSource _remoteDataSource;
  final PortfolioLocalDataSource _localDataSource;

  // Stream controllers for real-time updates
  final StreamController<PortfolioHoldings> _holdingsController =
      StreamController<PortfolioHoldings>.broadcast();
  final StreamController<PortfolioSummary> _summaryController =
      StreamController<PortfolioSummary>.broadcast();

  // Cache for the latest data
  PortfolioHoldings? _cachedHoldings;
  PortfolioSummary? _cachedSummary;
  PortfolioList? _cachedPortfolioList;
  String? _lastUserId;

  @override
  Future<PortfolioHoldings> getPortfolioHoldings(String userId) async {
    CommonLogger.methodEntry(
      'getPortfolioHoldings',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId},
    );

    // 1. Try Local Cache (Instant Load)
    try {
      final cached = await _localDataSource.getLastHoldings(userId);
      if (cached != null) {
        CommonLogger.info(
          'Loaded holdings from local cache',
          tag: 'PortfolioRepository',
        );
        // Emit immediately
        _holdingsController.add(cached);
        // Update in-memory cache
        _cachedHoldings = cached;
        _lastUserId = userId;
      }
    } catch (e) {
      CommonLogger.warning(
        'Failed to read local cache',
        error: e,
        tag: 'PortfolioRepository',
      );
    }

    // 2. Fetch Fresh Data (Network)
    try {
      // Fetch data from remote source
      final holdingsDto = await _remoteDataSource.getPortfolioHoldings(userId);

      // Map DTO to domain entity using holdings mapper
      final holdings = PortfolioHoldingsMapper.fromApiModel(
        holdingsDto,
        userId,
      );

      // 3. Update Stream & Caches
      _cachedHoldings = holdings;
      _lastUserId = userId;
      _holdingsController.add(holdings);

      // 4. Persist to Local Cache
      await _localDataSource.cacheHoldings(userId, holdings);

      CommonLogger.info(
        'Portfolio holdings fetched successfully',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getPortfolioHoldings',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return holdings;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio holdings',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioHoldings',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );

      // Return cached data if available (Double fallback: In-memory or Local)
      if (_cachedHoldings != null && _lastUserId == userId) {
        return _cachedHoldings!;
      }

      // If we had local cache earlier but no in-memory, try to return that (conceptually covered by step 1 & 3 update)
      // But if standard return is expected:
      rethrow;
    }
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary(String userId) async {
    CommonLogger.methodEntry(
      'getPortfolioSummary',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId},
    );

    // 1. Try Local Cache
    try {
      final cached = await _localDataSource.getLastSummary(userId);
      if (cached != null) {
        _summaryController.add(cached);
        _cachedSummary = cached;
        _lastUserId = userId;
      }
    } catch (e) {
      CommonLogger.warning('Failed to read local summary cache', error: e, tag: 'PortfolioRepository');
    }

    try {
      // 2. Fetch Fresh Data
      final summaryDto = await _remoteDataSource.getPortfolioSummary(userId);

      // Map DTO to domain entity using summary mapper
      final summary = PortfolioSummaryMapper.fromApiModel(summaryDto, userId);

      // 3. Update Stream & Caches
      _cachedSummary = summary;
      _lastUserId = userId;
      _summaryController.add(summary);

      // 4. Persist to Local Cache
      await _localDataSource.cacheSummary(userId, summary);

      CommonLogger.info(
        'Portfolio summary fetched successfully',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return summary;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio summary',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );

      if (_cachedSummary != null && _lastUserId == userId) {
        return _cachedSummary!;
      }

      rethrow;
    }
  }

  @override
  Future<PortfolioHoldings> getPortfolioHoldingsById(
    String userId,
    String portfolioId,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioHoldingsById',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId, 'portfolioId': portfolioId},
    );

    try {
      // Fetch from remote data source using specific portfolio ID
      final holdingsDto = await _remoteDataSource.getPortfolioHoldingsById(
        userId,
        portfolioId,
      );

      // Map DTO to domain entity using holdings mapper
      final holdings = PortfolioHoldingsMapper.fromApiModel(
        holdingsDto,
        userId,
      );

      // Cache the result
      _cachedHoldings = holdings;
      _lastUserId = userId;

      // Emit to stream for real-time updates
      _holdingsController.add(holdings);

      // Persist to Local Cache (Added Fix)
      await _localDataSource.cacheHoldings(userId, holdings);

      CommonLogger.info(
        'Portfolio holdings fetched successfully by ID',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getPortfolioHoldingsById',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return holdings;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio holdings by ID',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioHoldingsById',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );

      // Return cached data if available, otherwise rethrow
      if (_cachedHoldings != null && _lastUserId == userId) {
        CommonLogger.info(
          'Returning cached portfolio holdings due to error',
          tag: 'PortfolioRepository',
        );
        return _cachedHoldings!;
      }

      rethrow;
    }
  }

  @override
  Stream<PortfolioHoldings> watchPortfolioHoldings(String userId) {
    CommonLogger.methodEntry(
      'watchPortfolioHoldings',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId},
    );

    // Return existing stream
    // In a real implementation, you might want to:
    // 1. Set up periodic refresh
    // 2. Listen to WebSocket updates
    // 3. Handle connection state changes

    // Emit cached data immediately if available
    if (_cachedHoldings != null && _lastUserId == userId) {
      Future.microtask(() => _holdingsController.add(_cachedHoldings!));
    } else {
      // Fetch initial data
      getPortfolioHoldings(userId).catchError((error) {
        CommonLogger.error(
          'Failed to fetch initial holdings for stream',
          tag: 'PortfolioRepository',
          error: error,
        );
        _holdingsController.addError(error);
        return PortfolioHoldings.empty(userId);
      });
    }

    return _holdingsController.stream;
  }

  @override
  Future<PortfolioSummary> getPortfolioSummaryById(
    String userId,
    String portfolioId,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioSummaryById',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId, 'portfolioId': portfolioId},
    );

    try {
      // Fetch from remote data source using specific portfolio ID
      final summaryDto = await _remoteDataSource.getPortfolioSummaryById(
        userId,
        portfolioId,
      );

      // Map DTO to domain entity using summary mapper
      final summary = PortfolioSummaryMapper.fromApiModel(summaryDto, userId);

      // Cache the result
      _cachedSummary = summary;
      _lastUserId = userId;

      // Emit to stream for real-time updates
      _summaryController.add(summary);

      // Persist to Local Cache (Added Fix)
      await _localDataSource.cacheSummary(userId, summary);

      CommonLogger.info(
        'Portfolio summary fetched successfully by ID',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getPortfolioSummaryById',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return summary;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio summary by ID',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioSummaryById',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );

      // Return cached data if available, otherwise rethrow
      if (_cachedSummary != null && _lastUserId == userId) {
        CommonLogger.info(
          'Returning cached portfolio summary due to error',
          tag: 'PortfolioRepository',
        );
        return _cachedSummary!;
      }

      rethrow;
    }
  }

  @override
  Stream<PortfolioSummary> watchPortfolioSummary(String userId) {
    CommonLogger.methodEntry(
      'watchPortfolioSummary',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId},
    );

    // Emit cached data immediately if available
    if (_cachedSummary != null && _lastUserId == userId) {
      Future.microtask(() => _summaryController.add(_cachedSummary!));
    } else {
      // Fetch initial data
      getPortfolioSummary(userId).catchError((error) {
        CommonLogger.error(
          'Failed to fetch initial summary for stream',
          tag: 'PortfolioRepository',
          error: error,
        );
        _summaryController.addError(error);
        return PortfolioSummary.empty(userId);
      });
    }

    return _summaryController.stream;
  }

  @override
  Future<PortfolioHolding?> getHoldingDetails(
    String userId,
    String symbol,
  ) async {
    CommonLogger.methodEntry(
      'getHoldingDetails',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId, 'symbol': symbol},
    );

    try {
      // First try to get from cached holdings
      if (_cachedHoldings != null && _lastUserId == userId) {
        final holding = _cachedHoldings!.holdings
            .where((h) => h.symbol.toLowerCase() == symbol.toLowerCase())
            .firstOrNull;

        if (holding != null) {
          CommonLogger.info('Found holding in cache', tag: 'PortfolioRepository');
          CommonLogger.methodExit(
            'getHoldingDetails',
            tag: 'PortfolioRepository',
            metadata: {'status': 'cache_hit'},
          );
          return holding;
        }
      }

      // If not in cache, fetch fresh holdings
      final holdings = await getPortfolioHoldings(userId);
      final holding = holdings.holdings
          .where((h) => h.symbol.toLowerCase() == symbol.toLowerCase())
          .firstOrNull;

      CommonLogger.methodExit(
        'getHoldingDetails',
        tag: 'PortfolioRepository',
        metadata: {'status': holding != null ? 'success' : 'not_found'},
      );

      return holding;
    } catch (e) {
      CommonLogger.error(
        'Failed to get holding details',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getHoldingDetails',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  @override
  Future<List<SectorAllocation>> getSectorAllocation(String userId) async {
    CommonLogger.methodEntry(
      'getSectorAllocation',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId},
    );

    try {
      // Get portfolio summary which contains sector allocation
      final summary = await getPortfolioSummary(userId);

      CommonLogger.info(
        'Sector allocation retrieved successfully',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getSectorAllocation',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return summary.sectorAllocation;
    } catch (e) {
      CommonLogger.error(
        'Failed to get sector allocation',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getSectorAllocation',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  @override
  Future<List<TopPerformer>> getTopPerformers(
    String userId, {
    int limit = 5,
  }) async {
    CommonLogger.methodEntry(
      'getTopPerformers',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId, 'limit': limit},
    );

    try {
      // Get portfolio summary which contains top performers
      final summary = await getPortfolioSummary(userId);

      // Return limited results
      final topPerformers = summary.topPerformers.take(limit).toList();

      CommonLogger.info(
        'Top performers retrieved successfully',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getTopPerformers',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return topPerformers;
    } catch (e) {
      CommonLogger.error(
        'Failed to get top performers',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getTopPerformers',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  @override
  Future<List<TopPerformer>> getWorstPerformers(
    String userId, {
    int limit = 5,
  }) async {
    CommonLogger.methodEntry(
      'getWorstPerformers',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId, 'limit': limit},
    );

    try {
      // Get portfolio summary which contains worst performers
      final summary = await getPortfolioSummary(userId);

      // Return limited results
      final worstPerformers = summary.worstPerformers.take(limit).toList();

      CommonLogger.info(
        'Worst performers retrieved successfully',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getWorstPerformers',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return worstPerformers;
    } catch (e) {
      CommonLogger.error(
        'Failed to get worst performers',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getWorstPerformers',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  @override
  Future<PortfolioList> getPortfoliosList(String userId) async {
    CommonLogger.methodEntry(
      'getPortfoliosList',
      tag: 'PortfolioRepository',
      metadata: {'userId': userId},
    );

    // 1. Try Local Cache
    try {
      final cached = await _localDataSource.getLastPortfolioList(userId);
      if (cached != null) {
        _cachedPortfolioList = cached;
        _lastUserId = userId;
      }
    } catch (e) {
      CommonLogger.warning('Failed to read local portfolio list cache', error: e, tag: 'PortfolioRepository');
    }

    try {
      // 2. Fetch Fresh Data
      final portfolioListDto = await _remoteDataSource.getPortfoliosList(
        userId,
      );

      // Map DTO to domain entity using portfolio list mapper
      final portfolioList = PortfolioListMapper.fromApiModel(
        portfolioListDto,
        userId,
      );

      // 3. Cache the result
      _cachedPortfolioList = portfolioList;
      _lastUserId = userId;
      
      // 4. Persist to Local Cache
      await _localDataSource.cachePortfolioList(userId, portfolioList);

      CommonLogger.info(
        'Portfolio list fetched successfully',
        tag: 'PortfolioRepository',
      );
      CommonLogger.methodExit(
        'getPortfoliosList',
        tag: 'PortfolioRepository',
        metadata: {'status': 'success'},
      );

      return portfolioList;
    } catch (e) {
      CommonLogger.error(
        'Failed to fetch portfolio list',
        tag: 'PortfolioRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfoliosList',
        tag: 'PortfolioRepository',
        metadata: {'status': 'error'},
      );

      if (_cachedPortfolioList != null && _lastUserId == userId) {
        return _cachedPortfolioList!;
      }

      // If we found local data in step 1 but fetch failed, return it if we have it in memory
       if (_cachedPortfolioList != null) {
          return _cachedPortfolioList!;
       }

      rethrow;
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    CommonLogger.methodEntry('dispose', tag: 'PortfolioRepository');

    _holdingsController.close();
    _summaryController.close();
    _cachedHoldings = null;
    _cachedSummary = null;
    _cachedPortfolioList = null;
    _lastUserId = null;

    CommonLogger.info('PortfolioRepository disposed', tag: 'PortfolioRepository');
  }
}

/// Extension to provide firstOrNull functionality
extension IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}

