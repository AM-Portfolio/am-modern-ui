import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/shared/models/heatmap/heatmap_ui_data.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import '../mappers/sector_heatmap_converter.dart';
import 'portfolio_analytics_cubit.dart';
import 'portfolio_analytics_state.dart';
import 'portfolio_heatmap_state.dart';

/// Portfolio Heatmap Cubit
class PortfolioHeatmapCubit extends Cubit<PortfolioHeatmapState> {
  PortfolioHeatmapCubit([this._analyticsCubit])
    : super(PortfolioHeatmapInitial()) {
    CommonLogger.info(
      'PortfolioHeatmapCubit initialized',
      tag: 'PortfolioHeatmapCubit',
    );
  }
  final PortfolioAnalyticsCubit? _analyticsCubit;

  /// Load heatmap data for portfolio
  Future<void> loadHeatmapData({
    required String portfolioId,
    TimeFrame timeFrame = TimeFrame.oneDay,
    MetricType metric = MetricType.marketValue,
    SectorType sector = SectorType.all,
    MarketCapType marketCap = MarketCapType.all,
    PortfolioAnalyticsCubit? analyticsCubit,
  }) async {
    CommonLogger.info(
      'Loading heatmap data for portfolio: $portfolioId',
      tag: 'PortfolioHeatmapCubit',
    );

    try {
      emit(
        const PortfolioHeatmapLoading(message: 'Loading portfolio heatmap...'),
      );

      // Get analytics data from the analytics cubit or passed parameter
      final usedAnalyticsCubit = analyticsCubit ?? _analyticsCubit;

      HeatmapData heatmapData;

      if (usedAnalyticsCubit != null) {
        final analyticsState = usedAnalyticsCubit.state;

        if (analyticsState is PortfolioAnalyticsLoaded &&
            analyticsState.heatmap != null) {
          // Convert real analytics data to heatmap data
          heatmapData = SectorHeatmapConverter.convertToHeatmapData(
            heatmap: analyticsState.heatmap,
            showSubCards: true,
            subtitle: 'Sector Performance Analysis',
          );
        } else {
          CommonLogger.warning(
            'Analytics data not loaded or no heatmap data available',
            tag: 'PortfolioHeatmapCubit',
          );
          emit(
            const PortfolioHeatmapEmpty(
              message:
                  'No portfolio data available yet. Please add investments to see your heatmap.',
            ),
          );
          return;
        }
      } else {
        CommonLogger.warning(
          'No analytics cubit available',
          tag: 'PortfolioHeatmapCubit',
        );
        emit(
          const PortfolioHeatmapEmpty(
            message:
                'Portfolio data is not available. Please check your connection and try again.',
          ),
        );
        return;
      }

      emit(
        PortfolioHeatmapLoaded(
          heatmapData: heatmapData,
          portfolioId: portfolioId,
          timeFrame: timeFrame,
          metric: metric,
          sector: sector,
          marketCap: marketCap,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e, stackTrace) {
      CommonLogger.error(
        'Failed to load portfolio heatmap data',
        tag: 'PortfolioHeatmapCubit',
        error: e,
        stackTrace: stackTrace,
      );

      emit(
        const PortfolioHeatmapError(
          message: 'Failed to load portfolio heatmap',
        ),
      );
    }
  }

  Future<void> updateTimeFrame(TimeFrame timeFrame) async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: timeFrame,
        metric: currentState.metric,
        sector: currentState.sector ?? SectorType.all,
        marketCap: currentState.marketCap ?? MarketCapType.all,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot update timeframe - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }

  Future<void> updateMetric(MetricType metric) async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: currentState.timeFrame,
        metric: metric,
        sector: currentState.sector ?? SectorType.all,
        marketCap: currentState.marketCap ?? MarketCapType.all,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot update metric - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }

  Future<void> updateSector(SectorType sector) async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: currentState.timeFrame,
        metric: currentState.metric,
        sector: sector,
        marketCap: currentState.marketCap ?? MarketCapType.all,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot update sector - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }

  Future<void> updateMarketCap(MarketCapType marketCap) async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: currentState.timeFrame,
        metric: currentState.metric,
        sector: currentState.sector ?? SectorType.all,
        marketCap: marketCap,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot update market cap - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }

  Future<void> refresh() async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: currentState.timeFrame,
        metric: currentState.metric,
        sector: currentState.sector ?? SectorType.all,
        marketCap: currentState.marketCap ?? MarketCapType.all,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot refresh - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }
}
