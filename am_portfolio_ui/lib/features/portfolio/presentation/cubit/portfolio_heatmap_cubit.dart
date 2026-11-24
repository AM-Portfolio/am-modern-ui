import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart'
    hide MarketCapType, MetricType, TimeFrame, SectorType;
import '../mappers/heatmap_sector_matcher.dart';
import '../mappers/sector_heatmap_converter.dart';
import '../models/heatmap_asset_filter.dart';
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
    HeatmapAssetFilter assetFilter = HeatmapAssetFilter.allAssets,
    HeatmapMfCategory mfCategory = HeatmapMfCategory.all,
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
            analyticsState.portfolioId != null &&
            analyticsState.portfolioId != portfolioId) {
          if (isClosed) return;
          emit(const PortfolioHeatmapLoading(message: 'Loading portfolio heatmap...'));
          return;
        }

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

          heatmapData = heatmapData.copyWith(
            tiles: filterHeatmapTilesByAsset(heatmapData.uiTiles, assetFilter),
          );
          if (assetFilter == HeatmapAssetFilter.mutualFunds) {
            heatmapData = _applyMfCategoryFilter(heatmapData, mfCategory);
          }

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
          assetFilter: assetFilter,
          mfCategory: mfCategory,
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

  Future<void> updateMetric(MetricType metric) async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: currentState.timeFrame,
        metric: metric,
        sector: currentState.sector ?? SectorType.all,
        marketCap: currentState.marketCap ?? MarketCapType.all,
        assetFilter: currentState.assetFilter,
        mfCategory: currentState.mfCategory,
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
        assetFilter: currentState.assetFilter,
        mfCategory: currentState.mfCategory,
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
        assetFilter: currentState.assetFilter,
        mfCategory: currentState.mfCategory,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot update market cap - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }

  Future<void> updateAssetFilter(HeatmapAssetFilter assetFilter) async {
    final currentState = state;
    if (currentState is PortfolioHeatmapLoaded) {
      final analytics = _analyticsCubit;
      if (analytics != null) {
        final rawId = currentState.portfolioId;
        final pipe = rawId.indexOf('|');
        final bookId = pipe > 0 ? rawId.substring(0, pipe) : rawId;
        final persona = pipe > 0 ? rawId.substring(pipe + 1) : null;
        await analytics.loadAnalytics(
          bookId,
          timeFrame: currentState.timeFrame,
          persona: persona,
          assetScope: assetFilter.apiAssetScope,
        );
      }
      await loadHeatmapData(
        portfolioId: currentState.portfolioId,
        timeFrame: currentState.timeFrame,
        metric: currentState.metric,
        sector: currentState.sector ?? SectorType.all,
        marketCap: currentState.marketCap ?? MarketCapType.all,
        assetFilter: assetFilter,
        mfCategory: assetFilter == HeatmapAssetFilter.mutualFunds
            ? currentState.mfCategory
            : HeatmapMfCategory.all,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot update asset filter - current state is not loaded',
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
        assetFilter: currentState.assetFilter,
        mfCategory: currentState.mfCategory,
        analyticsCubit: _analyticsCubit,
      );
    } else {
      CommonLogger.warning(
        'Cannot refresh - current state is not loaded',
        tag: 'PortfolioHeatmapCubit',
      );
    }
  }

  static HeatmapTileData _reweightMfCategoryParent(
    HeatmapTileData tile,
    List<HeatmapTileData> children,
    double portfolioTotal,
  ) {
    final newValue = children.fold<double>(
      0.0,
      (sum, child) => sum + (child.value ?? 0.0),
    );
    final weightedPerf = newValue > 0
        ? children.fold<double>(
              0.0,
              (sum, child) => sum + child.performance * (child.value ?? 0.0),
            ) /
            newValue
        : tile.performance;
    return tile.copyWith(
      children: children,
      value: newValue,
      performance: weightedPerf,
      weightage:
          portfolioTotal > 0 ? (newValue / portfolioTotal) * 100 : tile.weightage,
    );
  }

  static HeatmapData _applyMfCategoryFilter(
    HeatmapData data,
    HeatmapMfCategory category,
  ) {
    if (category == HeatmapMfCategory.all) return data;

    final label = category.displayName;
    final filtered = <HeatmapTileData>[];

    for (final tile in data.uiTiles) {
      final metaCat = tile.metadata?['mfCategory']?.toString();
      final isCategoryParent = metaCat == category.name ||
          tile.name == label ||
          tile.displayName == label;

      if (tile.children == null || tile.children!.isEmpty) {
        final leafLabel = '${tile.displayName} ${tile.name}';
        if (category.matchesLabel(leafLabel)) filtered.add(tile);
        continue;
      }

      // Fast path: keep the matching category shell as-is.
      if (isCategoryParent) {
        filtered.add(tile);
        continue;
      }

      final children = <HeatmapTileData>[];
      for (final child in tile.children!) {
        final leaf =
            child is HeatmapTileData ? child : HeatmapTileData.fromEntity(child);
        final leafLabel = '${leaf.displayName} ${leaf.name}';
        if (category.matchesLabel(leafLabel)) children.add(leaf);
      }
      if (children.isEmpty) continue;
      filtered.add(_reweightMfCategoryParent(tile, children, 0));
    }

    if (filtered.isEmpty) return data.copyWith(tiles: filtered);

    final total = filtered.fold<double>(0, (sum, t) => sum + (t.value ?? 0));
    final reweighted = filtered
        .map(
          (tile) => tile.copyWith(
            weightage: total > 0 ? ((tile.value ?? 0) / total) * 100 : tile.weightage,
          ),
        )
        .toList();
    return data.copyWith(tiles: reweighted);
  }
}
