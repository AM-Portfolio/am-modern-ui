import 'dart:async';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_library/am_library.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
import '../../internal/services/portfolio_analytics_service.dart';
import 'portfolio_analytics_state.dart';

class PortfolioAnalyticsCubit extends Cubit<PortfolioAnalyticsState> {
  PortfolioAnalyticsCubit(this._analyticsService)
    : super(PortfolioAnalyticsInitial());
  final PortfolioAnalyticsService _analyticsService;

  Future<void>? _loadingFuture;
  String? _currentPortfolioId;
  TimeFrame? _lastLoadedTimeFrame;

  /// Load all analytics data for a portfolio
  Future<void> loadAnalytics(String portfolioId, {TimeFrame? timeFrame}) async {
    if (_loadingFuture != null && _currentPortfolioId == portfolioId) {
      CommonLogger.debug(
        '🔍 PortfolioAnalyticsCubit: loadAnalytics already in progress for portfolioId: $portfolioId',
        tag: 'PortfolioAnalyticsCubit',
      );
      return _loadingFuture;
    }

    if (state is PortfolioAnalyticsLoaded &&
        _currentPortfolioId == portfolioId &&
        _lastLoadedTimeFrame == timeFrame) {
      CommonLogger.debug(
        '🔍 PortfolioAnalyticsCubit: Data already loaded for $portfolioId and timeFrame: ${timeFrame?.name}',
        tag: 'PortfolioAnalyticsCubit',
      );
      return;
    }

    _currentPortfolioId = portfolioId;
    _loadingFuture = _doLoadAnalytics(portfolioId, timeFrame: timeFrame);

    try {
      await _loadingFuture;
    } finally {
      _loadingFuture = null;
    }
  }

  Future<void> _doLoadAnalytics(String portfolioId, {TimeFrame? timeFrame}) async {
    CommonLogger.debug(
      '🔍 PortfolioAnalyticsCubit: loadAnalytics called with portfolioId: $portfolioId, timeFrame: ${timeFrame?.name}',
      tag: 'PortfolioAnalyticsCubit',
    );
    CommonLogger.methodEntry(
      'loadAnalytics',
      tag: 'PortfolioAnalyticsCubit',
      metadata: {'portfolioId': portfolioId, 'timeFrame': timeFrame?.name},
    );

    final loadingTypes = const {
      AnalyticsDataType.sectorAllocation,
      AnalyticsDataType.marketCapAllocation,
      AnalyticsDataType.heatmap,
      AnalyticsDataType.movers,
    };

    if (state is PortfolioAnalyticsLoaded) {
      emit((state as PortfolioAnalyticsLoaded).copyWith(loadingTypes: loadingTypes));
    } else {
      emit(PortfolioAnalyticsLoading(loadingTypes: loadingTypes));
    }

    SectorAllocation? fastSectorAllocation;
    MarketCapAllocation? fastMarketCapAllocation;
    final sw = Stopwatch()..start();

    // Start full analytics fetch (takes ~58s due to live market data for Movers/Heatmap)
    final fullAnalyticsFuture = _analyticsService.getPortfolioAnalyticsWithDefaults(
      portfolioId, 
      timeFrame: timeFrame,
    );

    // Fast fetch for allocations (uses MongoDB / fast current market data, ~100ms)
    try {
      final allocations = await _analyticsService.getPortfolioAllocations(portfolioId);
      fastSectorAllocation = allocations.sectorAllocation;
      fastMarketCapAllocation = allocations.marketCapAllocation;
      
      if (!isClosed) {
        CommonLogger.debug(
          '🔍 Fast allocations loaded, emitting partial state',
          tag: 'PortfolioAnalyticsCubit',
        );
        if (state is PortfolioAnalyticsLoaded) {
          emit((state as PortfolioAnalyticsLoaded).copyWith(
            sectorAllocation: fastSectorAllocation,
            marketCapAllocation: fastMarketCapAllocation,
            loadingTypes: const {
              AnalyticsDataType.heatmap, 
              AnalyticsDataType.movers,
            },
          ));
        } else {
          emit(
            PortfolioAnalyticsLoaded(
              sectorAllocation: fastSectorAllocation,
              marketCapAllocation: fastMarketCapAllocation,
              loadingTypes: const {
                AnalyticsDataType.heatmap, 
                AnalyticsDataType.movers,
              },
            ),
          );
        }
      }
    } catch (e) {
      CommonLogger.warning(
        'Fast allocation fetch failed, waiting for full analytics: $e',
        tag: 'PortfolioAnalyticsCubit',
      );
    }

    // Wait for the slow features to complete
    try {
      CommonLogger.debug(
        '🔍 Starting to await full analytics data',
        tag: 'PortfolioAnalyticsCubit',
      );

      final analytics = await fullAnalyticsFuture.timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('Full analytics timed out after 90s'),
      );

      CommonLogger.debug(
        '🔍 Analytics service call completed, processing results',
        tag: 'PortfolioAnalyticsCubit',
      );

      CommonLogger.debug(
        '🔍 Data received: '
        'sectorAllocation=${analytics.analytics.sectorAllocation != null ? 'available' : 'null'}, '
        'marketCapAllocation=${analytics.analytics.marketCapAllocation != null ? 'available' : 'null'}, '
        'heatmap=${analytics.analytics.heatmap != null ? 'available' : 'null'}, '
        'movers=${analytics.analytics.movers != null ? 'available' : 'null'}',
        tag: 'PortfolioAnalyticsCubit',
      );

      if (isClosed) return;

      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'portfolio_analytics',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch',
        technicalArea: 'portfolio',
      );
      final sectorEmpty =
          (analytics.analytics.sectorAllocation ?? fastSectorAllocation)
              ?.sectorWeights
              .isEmpty ??
          true;
      final moversEmpty = analytics.analytics.movers == null ||
          (analytics.analytics.movers!.topGainers.isEmpty &&
              analytics.analytics.movers!.topLosers.isEmpty);
      if (sectorEmpty) {
        ProductTelemetry.instance.emptyState('allocation_empty');
      }
      if (moversEmpty) {
        ProductTelemetry.instance.emptyState('portfolio_movers_empty');
      }
      if (analytics.analytics.heatmap == null) {
        ProductTelemetry.instance.emptyState('heatmap_empty');
      }
      
      _lastLoadedTimeFrame = timeFrame;
      emit(
        PortfolioAnalyticsLoaded(
          sectorAllocation: analytics.analytics.sectorAllocation ?? fastSectorAllocation,
          marketCapAllocation: analytics.analytics.marketCapAllocation ?? fastMarketCapAllocation,
          heatmap: analytics.analytics.heatmap,
          movers: analytics.analytics.movers,
        ),
      );
      CommonLogger.info(
        'Portfolio analytics loaded successfully',
        tag: 'PortfolioAnalyticsCubit',
      );

      CommonLogger.methodExit('loadAnalytics', tag: 'PortfolioAnalyticsCubit');
    } catch (error) {
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'portfolio_analytics',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch_error',
        technicalArea: 'portfolio',
      );
      ProductTelemetry.instance.clientError(errorType: 'portfolio_analytics');
      CommonLogger.error(
        'Failed to load portfolio analytics',
        tag: 'PortfolioAnalyticsCubit',
        error: error,
        stackTrace: StackTrace.current,
      );

      if (isClosed) return;

      if (fastSectorAllocation != null || fastMarketCapAllocation != null) {
        _lastLoadedTimeFrame = timeFrame;
        emit(
          PortfolioAnalyticsLoaded(
            sectorAllocation: fastSectorAllocation,
            marketCapAllocation: fastMarketCapAllocation,
            errors: {
              AnalyticsDataType.heatmap: error.toString(),
              AnalyticsDataType.movers: error.toString(),
            },
          ),
        );
      } else {
        emit(PortfolioAnalyticsError(error.toString()));
      }

      CommonLogger.methodExit(
        'loadAnalytics',
        tag: 'PortfolioAnalyticsCubit',
        metadata: {'status': 'error'},
      );
    }
  }

  /// Load specific analytics data type
  Future<void> loadSpecificAnalytics(
    String portfolioId,
    AnalyticsDataType type,
  ) async {
    final currentState = state;
    if (currentState is PortfolioAnalyticsLoaded) {
      final newLoadingTypes = Set<AnalyticsDataType>.from(
        currentState.loadingTypes,
      )..add(type);

      emit(currentState.copyWith(loadingTypes: newLoadingTypes));

      try {
        switch (type) {
          case AnalyticsDataType.sectorAllocation:
          case AnalyticsDataType.marketCapAllocation:
            final allocations = await _analyticsService.getPortfolioAllocations(
              portfolioId,
            );
            final updatedLoadingTypes =
                Set<AnalyticsDataType>.from(currentState.loadingTypes)
                  ..remove(AnalyticsDataType.sectorAllocation)
                  ..remove(AnalyticsDataType.marketCapAllocation);

            if (isClosed) return;
            emit(
              currentState.copyWith(
                sectorAllocation: allocations.sectorAllocation,
                marketCapAllocation: allocations.marketCapAllocation,
                loadingTypes: updatedLoadingTypes,
              ),
            );
            break;

          case AnalyticsDataType.heatmap:
            final heatmap = await _analyticsService.getPortfolioHeatmap(
              portfolioId,
            );
            if (isClosed) return;
            emit(
              currentState.copyWith(
                heatmap: heatmap,
                loadingTypes: Set<AnalyticsDataType>.from(
                  currentState.loadingTypes,
                )..remove(type),
              ),
            );
            break;

          case AnalyticsDataType.movers:
            final movers = await _analyticsService.getPortfolioMovers(
              portfolioId,
            );
            if (isClosed) return;
            emit(
              currentState.copyWith(
                movers: movers,
                loadingTypes: Set<AnalyticsDataType>.from(
                  currentState.loadingTypes,
                )..remove(type),
              ),
            );
            break;
        }
      } catch (error) {
        CommonLogger.error(
          'Failed to load specific analytics: $type',
          tag: 'PortfolioAnalyticsCubit',
          error: error,
        );

        final newErrors = Map<AnalyticsDataType, String>.from(
          currentState.errors,
        );
        newErrors[type] = error.toString();

        final newLoadingTypes = Set<AnalyticsDataType>.from(
          currentState.loadingTypes,
        )..remove(type);

        if (isClosed) return;
        emit(
          currentState.copyWith(
            errors: newErrors,
            loadingTypes: newLoadingTypes,
          ),
        );
      }
    } else {
      // If not in loaded state, load all analytics
      await loadAnalytics(portfolioId);
    }
  }

  /// Refresh all analytics data
  Future<void> refreshAnalytics(String portfolioId) async {
    final currentState = state;
    if (currentState is PortfolioAnalyticsLoaded) {
      CommonLogger.info(
        'Refreshing portfolio analytics',
        tag: 'PortfolioAnalyticsCubit',
      );

      emit(currentState.copyWith(isRefreshing: true));

      try {
        // Refresh all data with single API call (more efficient)
        final analytics = await _analyticsService
            .getPortfolioAnalyticsWithDefaults(portfolioId);

        if (isClosed) return;
        emit(
          currentState.copyWith(
            sectorAllocation: analytics.analytics.sectorAllocation,
            marketCapAllocation: analytics.analytics.marketCapAllocation,
            heatmap: analytics.analytics.heatmap,
            movers: analytics.analytics.movers,
            isRefreshing: false,
            errors: {}, // Clear errors on successful refresh
          ),
        );

        CommonLogger.info(
          'Portfolio analytics refreshed successfully',
          tag: 'PortfolioAnalyticsCubit',
        );
      } catch (error) {
        CommonLogger.error(
          'Failed to refresh portfolio analytics',
          tag: 'PortfolioAnalyticsCubit',
          error: error,
        );

        if (isClosed) return;
        emit(currentState.copyWith(isRefreshing: false));
      }
    } else {
      // If not in loaded state, load all analytics
      await loadAnalytics(portfolioId);
    }
  }

  /// Clear all errors for specific analytics type
  void clearError(AnalyticsDataType type) {
    final currentState = state;
    if (currentState is PortfolioAnalyticsLoaded &&
        currentState.hasErrorForType(type)) {
      final newErrors = Map<AnalyticsDataType, String>.from(
        currentState.errors,
      );
      newErrors.remove(type);

      emit(currentState.copyWith(errors: newErrors));
    }
  }

  /// Clear all errors
  void clearAllErrors() {
    final currentState = state;
    if (currentState is PortfolioAnalyticsLoaded &&
        currentState.errors.isNotEmpty) {
      emit(currentState.copyWith(errors: {}));
    }
  }
}
