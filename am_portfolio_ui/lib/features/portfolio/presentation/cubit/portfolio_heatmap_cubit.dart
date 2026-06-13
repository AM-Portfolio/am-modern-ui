import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/shared/models/heatmap/heatmap_ui_data.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import '../mappers/sector_heatmap_converter.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';
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



          // Apply Sector filtering
          if (sector != SectorType.all && sector != SectorType.noGroup) {
            final targetSectorName = sector.displayName.toLowerCase();
            heatmapData = heatmapData.copyWith(
              tiles: heatmapData.uiTiles.where((tile) {
                final tileName = tile.name.toLowerCase();
                final tileDisplay = tile.displayName.toLowerCase();
                return tileName.contains(targetSectorName) || 
                       tileDisplay.contains(targetSectorName);
              }).toList(),
            );
          }

          // Apply Market Cap filtering
          if (marketCap != MarketCapType.all) {
            final targetCapName = marketCap.displayName.toLowerCase();
            
            // Try to find the matching segment in marketCapAllocation
            final segments = analyticsState.marketCapAllocation?.segments ?? [];
            final targetSegment = segments.cast<MarketCapSegment?>().firstWhere(
              (s) => s!.segmentName.toLowerCase().contains(targetCapName) || 
                     targetCapName.contains(s.segmentName.toLowerCase()),
              orElse: () => null,
            );

            if (targetSegment != null && targetSegment.topStocks.isNotEmpty) {
              // Filter the children of each tile to only include stocks in the target segment
              final List<HeatmapTileData> filteredTiles = [];
              
              for (final tile in heatmapData.uiTiles) {
                if (tile.children == null || tile.children!.isEmpty) {
                  filteredTiles.add(tile);
                  continue;
                }
                
                final filteredChildren = tile.children!.where((child) {
                  return targetSegment.topStocks.contains(child.id);
                }).toList();
                
                if (filteredChildren.isNotEmpty) {
                  // Recalculate sector value based on remaining children to prevent layout errors
                  final newSectorValue = filteredChildren.fold<double>(
                    0.0, 
                    (sum, child) => sum + (child.value ?? 0.0)
                  );
                  
                  filteredTiles.add(tile.copyWith(
                    children: filteredChildren,
                    value: newSectorValue,
                  ));
                }
              }
              
              heatmapData = heatmapData.copyWith(tiles: filteredTiles);
            } else {
              // No stocks match this market cap segment — show empty state
              if (isClosed) return;
              emit(const PortfolioHeatmapEmpty(
                message: 'No holdings found for the selected market cap segment.',
              ));
              return;
            }
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

}
