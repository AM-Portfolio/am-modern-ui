import 'dart:async';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_library/am_library.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
import '../../internal/domain/entities/portfolio_analytics_request.dart';
import '../../internal/services/portfolio_analytics_service.dart';
import 'portfolio_analytics_state.dart';

class PortfolioAnalyticsCubit extends Cubit<PortfolioAnalyticsState> {
  PortfolioAnalyticsCubit(this._analyticsService)
    : super(PortfolioAnalyticsInitial());
  final PortfolioAnalyticsService _analyticsService;

  Future<void>? _loadingFuture;
  String? _currentPortfolioId;
  String? _loadedPersona;
  TimeFrame? _lastLoadedTimeFrame;
  TimeFrame? _inFlightTimeFrame;
  int _loadGeneration = 0;

  /// Prefer hist when it has data; otherwise keep live/fast. Empty lists must not wipe live.
  static SectorAllocation? preferNonEmptyAllocation(
    SectorAllocation? hist,
    SectorAllocation? live,
  ) {
    if (hist != null && hist.sectorWeights.isNotEmpty) return hist;
    if (live != null && live.sectorWeights.isNotEmpty) return live;
    return hist ?? live;
  }

  static Heatmap? preferNonEmptyHeatmap(Heatmap? hist, Heatmap? live) {
    return preferQualityHeatmap(hist, live);
  }

  /// Same book may keep a richer map. A different portfolio always takes [incoming],
  /// including a 1-stock or lower-value book.
  static Heatmap? heatmapForPortfolio({
    required String portfolioId,
    required String? priorPortfolioId,
    Heatmap? incoming,
    Heatmap? prior,
  }) {
    if (priorPortfolioId != portfolioId) return incoming;
    return preferQualityHeatmap(incoming, prior);
  }

  /// Accept [candidate] only when its non-zero sector mass is comparable to [prior].
  /// Thin hist (few priced sectors) must not wipe a richer live/prior map.
  /// Prefer candidate when it remounts ETFs out of stock sectors (e.g. NIFTYBEES).
  static Heatmap? preferQualityHeatmap(
    Heatmap? candidate,
    Heatmap? prior, {
    double? overviewTotal,
  }) {
    if (candidate == null || candidate.sectors.isEmpty) {
      if (prior != null && prior.sectors.isNotEmpty) return prior;
      return candidate ?? prior;
    }
    if (prior == null || prior.sectors.isEmpty) return candidate;

    if (_hasMisbucketedEtf(prior) && !_hasMisbucketedEtf(candidate)) {
      return candidate;
    }

    final candidateValue = _heatmapValueSum(candidate);
    final priorValue = _heatmapValueSum(prior);
    final candidatePriced = _pricedSectorCount(candidate);
    final priorPriced = _pricedSectorCount(prior);

    final minSectors = priorPriced <= 0
        ? 1
        : (priorPriced * 0.5).ceil().clamp(1, priorPriced);
    final thinByCount = candidatePriced < minSectors && candidatePriced < 3;
    final thinByValue =
        priorValue > 0 && candidateValue < priorValue * 0.5;
    final thinByOverview = overviewTotal != null &&
        overviewTotal > 0 &&
        candidateValue < overviewTotal * 0.5;

    if (thinByCount || thinByValue || thinByOverview) {
      return _overlayPeriodPercents(prior, candidate);
    }
    return candidate;
  }

  static bool _isEtfSectorName(String raw) {
    final u = raw.trim().toLowerCase();
    if (u.isEmpty) return false;
    if (u == 'etf' || u == 'etfs') return true;
    return u.contains('exchange traded');
  }

  static bool _looksLikeEtfSymbol(String symbol) {
    final u = symbol.trim().toUpperCase();
    if (u.isEmpty) return false;
    return u.endsWith('BEES') ||
        u.contains('ETF') ||
        u.endsWith('IETF');
  }

  /// True when a BEES/ETF leaf sits under a non-ETF sector (Financial Services, etc.).
  static bool _hasMisbucketedEtf(Heatmap heatmap) {
    for (final sector in heatmap.sectors) {
      if (_isEtfSectorName(sector.sectorName)) continue;
      for (final stock in sector.stocks) {
        if (_looksLikeEtfSymbol(stock.symbol)) return true;
      }
    }
    return false;
  }

  static double _heatmapValueSum(Heatmap heatmap) =>
      heatmap.sectors.fold(0.0, (sum, s) => sum + s.totalValue);

  static int _pricedSectorCount(Heatmap heatmap) =>
      heatmap.sectors.where((s) => s.totalValue > 0).length;

  static Heatmap _overlayPeriodPercents(Heatmap structure, Heatmap period) {
    final byName = {
      for (final s in period.sectors)
        s.sectorName.trim().toLowerCase(): s.changePercent,
    };
    final merged = structure.sectors.map((s) {
      final key = s.sectorName.trim().toLowerCase();
      final pct = byName[key];
      if (pct == null) return s;
      return Sector(
        sectorName: s.sectorName,
        performanceRank: s.performanceRank,
        performance: pct,
        changePercent: pct,
        weightage: s.weightage,
        color: s.color,
        stockCount: s.stockCount,
        totalValue: s.totalValue,
        totalReturnAmount: s.totalReturnAmount,
        stocks: s.stocks,
      );
    }).toList();
    return Heatmap(sectors: merged);
  }

  /// Load all analytics data for a portfolio
  String? _loadedAssetScope;

  /// ALL / blank / null are the same mosaic cache key (client filters Equity/ETF/MF).
  static String? _normalizeAssetScopeKey(String? assetScope) {
    if (assetScope == null || assetScope.trim().isEmpty) return 'ALL';
    final u = assetScope.trim().toUpperCase();
    return u == 'ALL' ? 'ALL' : u;
  }

  Future<void> loadAnalytics(
    String portfolioId, {
    TimeFrame? timeFrame,
    FeatureToggles? featureToggles,
    String? persona,
    String? assetScope,
    bool forceRefresh = false,
    bool heatmapFirst = true,
  }) async {
    // Coalesce only when the same portfolio AND timeframe are already loading.
    final scopeKey = _normalizeAssetScopeKey(assetScope);

    if (!forceRefresh &&
        _loadingFuture != null &&
        _currentPortfolioId == portfolioId &&
        _loadedPersona == persona &&
        _normalizeAssetScopeKey(_loadedAssetScope) == scopeKey &&
        _inFlightTimeFrame == timeFrame) {
      CommonLogger.debug(
        '🔍 PortfolioAnalyticsCubit: loadAnalytics already in progress for portfolioId: $portfolioId tf: ${timeFrame?.name}',
        tag: 'PortfolioAnalyticsCubit',
      );
      return _loadingFuture;
    }

    if (!forceRefresh &&
        state is PortfolioAnalyticsLoaded &&
        _currentPortfolioId == portfolioId &&
        _loadedPersona == persona &&
        _normalizeAssetScopeKey(_loadedAssetScope) == scopeKey &&
        _lastLoadedTimeFrame == timeFrame) {
      final loaded = state as PortfolioAnalyticsLoaded;
      final hasHeatmap =
          loaded.heatmap != null && loaded.heatmap!.sectors.isNotEmpty;
      if (hasHeatmap) {
        CommonLogger.debug(
          '🔍 PortfolioAnalyticsCubit: Data already loaded for $portfolioId and timeFrame: ${timeFrame?.name}',
          tag: 'PortfolioAnalyticsCubit',
        );
        return;
      }
    }

    _currentPortfolioId = portfolioId;
    _loadedPersona = persona;
    _loadedAssetScope = scopeKey;
    _inFlightTimeFrame = timeFrame;
    final gen = ++_loadGeneration;
    _loadingFuture = _doLoadAnalytics(
      portfolioId,
      timeFrame: timeFrame,
      featureToggles: featureToggles,
      persona: persona,
      assetScope: assetScope,
      heatmapFirst: heatmapFirst,
      gen: gen,
    );

    try {
      await _loadingFuture;
    } finally {
      if (gen == _loadGeneration) {
        _loadingFuture = null;
        _inFlightTimeFrame = null;
      }
    }
  }

  Future<void> _doLoadAnalytics(
    String portfolioId, {
    TimeFrame? timeFrame,
    FeatureToggles? featureToggles,
    String? persona,
    String? assetScope,
    bool heatmapFirst = true,
    required int gen,
  }) async {
    final requestId = portfolioId == 'all' && persona != null && persona.isNotEmpty
        ? 'all|$persona'
        : portfolioId;
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

    final priorLoaded = state is PortfolioAnalyticsLoaded
        ? state as PortfolioAnalyticsLoaded
        : null;
    final sameBook = priorLoaded?.portfolioId == portfolioId;
    if (sameBook) {
      emit(priorLoaded!.copyWith(loadingTypes: loadingTypes));
    } else {
      emit(PortfolioAnalyticsLoading(loadingTypes: loadingTypes));
    }

    SectorAllocation? fastSectorAllocation;
    MarketCapAllocation? fastMarketCapAllocation;
    final sw = Stopwatch()..start();

    final useHeatmapFirst = heatmapFirst && featureToggles == null;
    final primaryToggles = useHeatmapFirst
        ? PortfolioAnalyticsService.heatmapOnlyToggles
        : featureToggles;

    // Heatmap-first: await mosaic first; allocations run parallel and must not gate paint.
    final fullAnalyticsFuture = _analyticsService.getPortfolioAnalyticsWithDefaults(
      requestId,
      timeFrame: timeFrame,
      featureToggles: primaryToggles,
      assetScope: assetScope,
    );

    final allocationsFuture = useHeatmapFirst
        ? _analyticsService.getPortfolioAllocations(requestId)
        : null;

    try {
      CommonLogger.debug(
        '🔍 Starting to await heatmap-first analytics',
        tag: 'PortfolioAnalyticsCubit',
      );

      final analytics = await fullAnalyticsFuture.timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw TimeoutException('Full analytics timed out after 90s'),
      );

      if (allocationsFuture != null) {
        unawaited(allocationsFuture.then((allocations) {
          if (isClosed || gen != _loadGeneration) return;
          fastSectorAllocation = allocations.sectorAllocation;
          fastMarketCapAllocation = allocations.marketCapAllocation;
          final current = state;
          if (current is PortfolioAnalyticsLoaded &&
              current.portfolioId == portfolioId) {
            emit(
              current.copyWith(
                sectorAllocation: preferNonEmptyAllocation(
                  allocations.sectorAllocation,
                  current.sectorAllocation,
                ),
                marketCapAllocation: allocations.marketCapAllocation ??
                    current.marketCapAllocation,
              ),
            );
          }
        }).catchError((Object e) {
          CommonLogger.warning(
            'Fast allocation fetch failed after heatmap: $e',
            tag: 'PortfolioAnalyticsCubit',
          );
        }));
      }

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

      if (isClosed || gen != _loadGeneration) return;

      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'portfolio_analytics',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch',
        technicalArea: 'portfolio',
      );
      final sectorEmpty =
          preferNonEmptyAllocation(
                analytics.analytics.sectorAllocation,
                fastSectorAllocation,
              )
              ?.sectorWeights
              .isEmpty ??
          true;
      final moversEmpty = analytics.analytics.movers == null ||
          (analytics.analytics.movers!.topGainers.isEmpty &&
              analytics.analytics.movers!.topLosers.isEmpty);
      if (sectorEmpty) {
        ProductTelemetry.instance.emptyState('allocation_empty');
      }
      var resolvedMovers = analytics.analytics.movers;
      // Heatmap-first defers movers — do not await movers before mosaic emit.
      if (moversEmpty && !useHeatmapFirst) {
        ProductTelemetry.instance.emptyState('portfolio_movers_empty');
        try {
          final retryMovers = await _analyticsService.getPortfolioMovers(
            portfolioId,
          );
          if (retryMovers != null &&
              (retryMovers.topGainers.isNotEmpty ||
                  retryMovers.topLosers.isNotEmpty) &&
              !isClosed &&
              gen == _loadGeneration) {
            resolvedMovers = retryMovers;
            CommonLogger.info(
              'Portfolio movers recovered via dedicated movers endpoint',
              tag: 'PortfolioAnalyticsCubit',
            );
          }
        } catch (e) {
          CommonLogger.warning(
            'Movers fallback fetch failed: $e',
            tag: 'PortfolioAnalyticsCubit',
          );
        }
      } else if (moversEmpty) {
        ProductTelemetry.instance.emptyState('portfolio_movers_empty');
      }
      final priorHeatmap = sameBook ? priorLoaded?.heatmap : null;
      // Live / 1D: always take fresh mosaic so quiet refresh cannot keep stale tile %.
      final liveOneDay = timeFrame == null || timeFrame == TimeFrame.oneDay;
      final incomingHeatmap = analytics.analytics.heatmap;
      final mergedHeatmap = liveOneDay &&
              incomingHeatmap != null &&
              incomingHeatmap.sectors.isNotEmpty
          ? incomingHeatmap
          : heatmapForPortfolio(
              portfolioId: portfolioId,
              priorPortfolioId: sameBook ? portfolioId : null,
              incoming: incomingHeatmap,
              prior: priorHeatmap,
            );
      if (mergedHeatmap == null || mergedHeatmap.sectors.isEmpty) {
        ProductTelemetry.instance.emptyState('heatmap_empty');
      }

      _lastLoadedTimeFrame = timeFrame;
      emit(
        PortfolioAnalyticsLoaded(
          portfolioId: portfolioId,
          sectorAllocation: preferNonEmptyAllocation(
            analytics.analytics.sectorAllocation,
            fastSectorAllocation,
          ),
          marketCapAllocation: analytics.analytics.marketCapAllocation ??
              fastMarketCapAllocation,
          heatmap: mergedHeatmap,
          movers: resolvedMovers,
          loadingTypes: useHeatmapFirst
              ? const {AnalyticsDataType.movers}
              : const {},
        ),
      );
      CommonLogger.info(
        'Portfolio analytics loaded successfully',
        tag: 'PortfolioAnalyticsCubit',
      );

      if (useHeatmapFirst && !isClosed && gen == _loadGeneration) {
        unawaited(_deferMoversAndEnrichments(
          portfolioId: portfolioId,
          requestId: requestId,
          timeFrame: timeFrame,
          assetScope: assetScope,
          gen: gen,
        ));
      }

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

      if (isClosed || gen != _loadGeneration) return;

      if (fastSectorAllocation != null || fastMarketCapAllocation != null) {
        _lastLoadedTimeFrame = timeFrame;
        emit(
          PortfolioAnalyticsLoaded(
            portfolioId: portfolioId,
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

  /// After mosaic paints, fill movers without blocking heatmap UI.
  Future<void> _deferMoversAndEnrichments({
    required String portfolioId,
    required String requestId,
    TimeFrame? timeFrame,
    String? assetScope,
    required int gen,
  }) async {
    try {
      Movers? movers = await _analyticsService.getPortfolioMovers(requestId);
      if (movers == null ||
          (movers.topGainers.isEmpty && movers.topLosers.isEmpty)) {
        final enriched = await _analyticsService
            .getPortfolioAnalyticsWithDefaults(
          requestId,
          timeFrame: timeFrame,
          featureToggles: const FeatureToggles(
            includeHeatmap: false,
            includeMovers: true,
            includeSectorAllocation: true,
            includeMarketCapAllocation: true,
          ),
          assetScope: assetScope,
        );
        movers = enriched.analytics.movers ?? movers;
        if (isClosed || gen != _loadGeneration) return;
        final current = state;
        if (current is! PortfolioAnalyticsLoaded) return;
        emit(
          current.copyWith(
            movers: movers,
            sectorAllocation: preferNonEmptyAllocation(
              enriched.analytics.sectorAllocation,
              current.sectorAllocation,
            ),
            marketCapAllocation: enriched.analytics.marketCapAllocation ??
                current.marketCapAllocation,
            loadingTypes: const {},
          ),
        );
        return;
      }
      if (isClosed || gen != _loadGeneration) return;
      final current = state;
      if (current is! PortfolioAnalyticsLoaded) return;
      emit(current.copyWith(movers: movers, loadingTypes: const {}));
    } catch (e) {
      CommonLogger.warning(
        'Deferred movers enrichment failed: $e',
        tag: 'PortfolioAnalyticsCubit',
      );
      if (isClosed || gen != _loadGeneration) return;
      final current = state;
      if (current is PortfolioAnalyticsLoaded) {
        emit(current.copyWith(loadingTypes: const {}));
      }
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
    if (currentState is PortfolioAnalyticsLoaded &&
        currentState.portfolioId == portfolioId) {
      CommonLogger.info(
        'Refreshing portfolio analytics',
        tag: 'PortfolioAnalyticsCubit',
      );

      emit(currentState.copyWith(isRefreshing: true, portfolioId: portfolioId));

      try {
        final analytics = await _analyticsService
            .getPortfolioAnalyticsWithDefaults(
          portfolioId,
          timeFrame: _lastLoadedTimeFrame,
        );

        if (isClosed) return;
        emit(
          currentState.copyWith(
            sectorAllocation: preferNonEmptyAllocation(
              analytics.analytics.sectorAllocation,
              currentState.sectorAllocation,
            ),
            marketCapAllocation: analytics.analytics.marketCapAllocation ??
                currentState.marketCapAllocation,
            heatmap: preferNonEmptyHeatmap(
              analytics.analytics.heatmap,
              currentState.heatmap,
            ),
            movers: analytics.analytics.movers ?? currentState.movers,
            isRefreshing: false,
            errors: {},
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

  /// Drop cached analytics (e.g. switching to All Portfolios).
  void reset() {
    _loadGeneration++;
    _currentPortfolioId = null;
    _lastLoadedTimeFrame = null;
    _loadingFuture = null;
    emit(PortfolioAnalyticsInitial());
  }
}
