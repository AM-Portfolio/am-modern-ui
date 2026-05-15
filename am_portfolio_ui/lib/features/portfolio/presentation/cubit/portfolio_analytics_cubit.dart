import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import '../../internal/services/portfolio_analytics_service.dart';
import 'portfolio_analytics_state.dart';

class PortfolioAnalyticsCubit extends Cubit<PortfolioAnalyticsState> {
  PortfolioAnalyticsCubit(this._analyticsService)
    : super(PortfolioAnalyticsInitial());
  final PortfolioAnalyticsService _analyticsService;

  /// Load all analytics data for a portfolio
  Future<void> loadAnalytics(String portfolioId) async {
    CommonLogger.debug(
      '🔍 PortfolioAnalyticsCubit: loadAnalytics called with portfolioId: $portfolioId',
      tag: 'PortfolioAnalyticsCubit',
    );
    CommonLogger.methodEntry(
      'loadAnalytics',
      tag: 'PortfolioAnalyticsCubit',
      metadata: {'portfolioId': portfolioId},
    );

    emit(
      const PortfolioAnalyticsLoading(
        loadingTypes: {
          AnalyticsDataType.sectorAllocation,
          AnalyticsDataType.marketCapAllocation,
          AnalyticsDataType.heatmap,
          AnalyticsDataType.movers,
        },
      ),
    );

    try {
      CommonLogger.debug(
        '🔍 Starting to load analytics data concurrently',
        tag: 'PortfolioAnalyticsCubit',
      );

      // Load all analytics data with single API call (more efficient)
      final analytics = await _analyticsService
          .getPortfolioAnalyticsWithDefaults(portfolioId);

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
      emit(
        PortfolioAnalyticsLoaded(
          sectorAllocation: analytics.analytics.sectorAllocation,
          marketCapAllocation: analytics.analytics.marketCapAllocation,
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
      CommonLogger.error(
        'Failed to load portfolio analytics',
        tag: 'PortfolioAnalyticsCubit',
        error: error,
        stackTrace: StackTrace.current,
      );

      if (isClosed) return;
      emit(PortfolioAnalyticsError(error.toString()));
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

