import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import '../mappers/heatmap_sector_matcher.dart';
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
            (analyticsState.heatmap != null ||
                (analyticsState.sectorAllocation?.sectorWeights.isNotEmpty ??
                    false))) {
          // Convert real analytics data to heatmap data (allocation fallback OK)
          heatmapData = SectorHeatmapConverter.convertToHeatmapData(
            heatmap: analyticsState.heatmap,
            sectorAllocation: analyticsState.sectorAllocation,
            showSubCards: true,
            subtitle: 'Sector Performance Analysis',
            accentColor: ModuleColors.portfolio,
          );

          // Apply Sector filtering using domain-aware mapping
          if (sector != SectorType.all && sector != SectorType.noGroup) {
            heatmapData = heatmapData.copyWith(
              tiles: heatmapData.uiTiles.where((tile) {
                return matchesHeatmapSector(tile.name, sector) ||
                       matchesHeatmapSector(tile.displayName, sector);
              }).toList(),
            );
          }

          // Apply Market Cap filtering — match child symbols, drop empty parents
          if (marketCap != MarketCapType.all) {
            final targetCapName = marketCap.displayName;

            final segments = analyticsState.marketCapAllocation?.segments ?? [];
            final targetSegment = segments.cast<MarketCapSegment?>().firstWhere(
              (s) => s != null && matchesStrictly(s.segmentName, targetCapName),
              orElse: () => null,
            );

            if (targetSegment != null && targetSegment.topStocks.isNotEmpty) {
              final symbols = targetSegment.topStocks
                  .map((s) => s.trim().toUpperCase())
                  .toSet();
              final List<HeatmapTileData> filteredTiles = [];
              final totalValue = heatmapData.uiTiles.fold<double>(
                0.0,
                (sum, tile) => sum + (tile.value ?? 0.0),
              );

              for (final tile in heatmapData.uiTiles) {
                if (tile.children == null || tile.children!.isEmpty) {
                  final symbol = ((tile.metadata?['symbol'] as String?) ?? tile.name)
                      .trim()
                      .toUpperCase();
                  if (symbols.contains(symbol)) {
                    filteredTiles.add(tile);
                  }
                  continue;
                }

                final filteredChildren = tile.children!.where((child) {
                  final symbol =
                      ((child.metadata?['symbol'] as String?) ?? child.name)
                          .trim()
                          .toUpperCase();
                  return symbols.contains(symbol);
                }).toList();

                if (filteredChildren.isEmpty) continue;

                final newSectorValue = filteredChildren.fold<double>(
                  0.0,
                  (sum, child) => sum + (child.value ?? 0.0),
                );
                final newWeightage = totalValue > 0
                    ? (newSectorValue / totalValue) * 100
                    : tile.weightage;

                filteredTiles.add(
                  tile.copyWith(
                    children: filteredChildren,
                    value: newSectorValue,
                    weightage: newWeightage,
                  ),
                );
              }

              heatmapData = heatmapData.copyWith(tiles: filteredTiles);
            } else {
              heatmapData = heatmapData.copyWith(tiles: []);
              ProductTelemetry.instance.emptyState('heatmap_segment_empty');
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
      // Keep Loaded (even with zero tiles) so sector/market-cap filters stay usable.
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
