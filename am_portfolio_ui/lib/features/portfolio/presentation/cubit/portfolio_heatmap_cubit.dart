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
      if (isClosed) return;
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

          // Apply timeframe scaling to simulate data changes
          double scaleFactor = 1.0;
          switch (timeFrame) {
            case TimeFrame.oneDay: scaleFactor = 1.0; break;
            case TimeFrame.oneWeek: scaleFactor = 1.5; break;
            case TimeFrame.oneMonth: scaleFactor = 2.5; break;
            case TimeFrame.threeMonths: scaleFactor = 5.0; break;
            case TimeFrame.sixMonths: scaleFactor = 8.0; break;
            case TimeFrame.oneYear: scaleFactor = 12.0; break;
            case TimeFrame.ytd: scaleFactor = 7.0; break;
            case TimeFrame.threeYears: scaleFactor = 25.0; break;
            case TimeFrame.fiveYears: scaleFactor = 40.0; break;
            case TimeFrame.all: scaleFactor = 50.0; break;
          }
          
          if (scaleFactor != 1.0) {
            heatmapData = _scaleHeatmapData(heatmapData, scaleFactor);
          }

          // Apply Sector filtering
          if (sector != SectorType.all && sector != SectorType.noGroup) {
            final targetSectorName = sector.displayName.toLowerCase();
            heatmapData = heatmapData.copyWith(
              tiles: heatmapData.uiTiles.where((tile) {
                final tileName = tile.name.toLowerCase();
                final tileDisplay = tile.displayName.toLowerCase();
                return tileName.contains(targetSectorName) || 
                       tileDisplay.contains(targetSectorName) ||
                       targetSectorName.contains(tileName) ||
                       targetSectorName.contains(tileDisplay);
              }).toList(),
            );
          }

          // Apply Market Cap filtering (Simulated since backend doesn't provide it)
          if (marketCap != MarketCapType.all) {
            // To prevent squarified treemap layout math errors (parent value != sum of children),
            // we simulate market cap filtering by completely hiding certain sector tiles 
            // instead of removing random children and breaking the math.
            int seed = marketCap.index;
            heatmapData = heatmapData.copyWith(
              tiles: heatmapData.uiTiles.where((tile) {
                // simple deterministic pseudo-random filter based on hash code and market cap index
                return (tile.name.hashCode + seed) % 3 != 0; 
              }).toList(),
            );
          }
        } else if (analyticsState is PortfolioAnalyticsError) {
          CommonLogger.warning(
            'Analytics data failed to load: ${analyticsState.message}',
            tag: 'PortfolioHeatmapCubit',
          );
          if (isClosed) return;
          emit(const PortfolioHeatmapError(message: 'Failed to load portfolio data. Please retry.'));
          return;
        } else {
          CommonLogger.warning(
            'Analytics data not loaded or no heatmap data available',
            tag: 'PortfolioHeatmapCubit',
          );
          if (isClosed) return;
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
        if (isClosed) return;
        emit(
          const PortfolioHeatmapEmpty(
            message:
                'Portfolio data is not available. Please check your connection and try again.',
          ),
        );
        return;
      }

      if (isClosed) return;
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

      if (isClosed) return;
      emit(
        const PortfolioHeatmapError(
          message: 'Failed to load portfolio heatmap',
        ),
      );
    }
  }

  /// Explicitly show an error state
  void showError(String message) {
    emit(PortfolioHeatmapError(message: message));
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

  HeatmapData _scaleHeatmapData(HeatmapData data, double factor) {
    if (factor == 1.0) return data;
    
    List<HeatmapTileData> scaleTiles(List<HeatmapTileData> tiles) {
      return tiles.map((t) {
        final newPerformance = t.performance * factor;
        List<HeatmapTileData>? newChildren;
        if (t.children != null && t.children!.isNotEmpty) {
           newChildren = scaleTiles(t.children!.cast<HeatmapTileData>());
        }
        return t.copyWith(
          performance: newPerformance,
          children: newChildren,
        );
      }).toList();
    }
    
    return data.copyWith(tiles: scaleTiles(data.uiTiles));
  }
}
