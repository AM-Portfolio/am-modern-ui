import 'package:equatable/equatable.dart';
import 'package:am_design_system/shared/models/heatmap/heatmap_ui_data.dart';
import 'package:am_design_system/am_design_system.dart';

import '../models/heatmap_asset_filter.dart';

/// Base class for all portfolio heatmap states
abstract class PortfolioHeatmapState extends Equatable {
  const PortfolioHeatmapState();

  @override
  List<Object?> get props => [];
}

/// Initial state when heatmap is not loaded
class PortfolioHeatmapInitial extends PortfolioHeatmapState {}

/// Loading state when heatmap data is being fetched
class PortfolioHeatmapLoading extends PortfolioHeatmapState {
  const PortfolioHeatmapLoading({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Loaded state with heatmap data and current filters
class PortfolioHeatmapLoaded extends PortfolioHeatmapState {
  const PortfolioHeatmapLoaded({
    required this.heatmapData,
    required this.timeFrame,
    required this.metric,
    required this.portfolioId,
    required this.lastUpdated,
    this.sector,
    this.marketCap,
    this.assetFilter = HeatmapAssetFilter.allAssets,
    this.mfCategory = HeatmapMfCategory.all,
  });
  final HeatmapData heatmapData;
  final TimeFrame timeFrame;
  final MetricType metric;
  final SectorType? sector;
  final MarketCapType? marketCap;
  final HeatmapAssetFilter assetFilter;
  final HeatmapMfCategory mfCategory;
  final String portfolioId;
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [
    heatmapData,
    timeFrame,
    metric,
    sector,
    marketCap,
    assetFilter,
    mfCategory,
    portfolioId,
    lastUpdated,
  ];

  /// Create a copy with modified properties
  PortfolioHeatmapLoaded copyWith({
    HeatmapData? heatmapData,
    TimeFrame? timeFrame,
    MetricType? metric,
    SectorType? sector,
    MarketCapType? marketCap,
    HeatmapAssetFilter? assetFilter,
    HeatmapMfCategory? mfCategory,
    String? portfolioId,
    DateTime? lastUpdated,
  }) => PortfolioHeatmapLoaded(
    heatmapData: heatmapData ?? this.heatmapData,
    timeFrame: timeFrame ?? this.timeFrame,
    metric: metric ?? this.metric,
    sector: sector ?? this.sector,
    marketCap: marketCap ?? this.marketCap,
    assetFilter: assetFilter ?? this.assetFilter,
    mfCategory: mfCategory ?? this.mfCategory,
    portfolioId: portfolioId ?? this.portfolioId,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

/// Error state when heatmap data loading fails
class PortfolioHeatmapError extends PortfolioHeatmapState {
  const PortfolioHeatmapError({
    required this.message,
    this.details,
    this.timeFrame,
    this.metric,
    this.sector,
    this.marketCap,
    this.assetFilter,
  });
  final String message;
  final String? details;
  final TimeFrame? timeFrame;
  final MetricType? metric;
  final SectorType? sector;
  final MarketCapType? marketCap;
  final HeatmapAssetFilter? assetFilter;

  @override
  List<Object?> get props => [
    message,
    details,
    timeFrame,
    metric,
    sector,
    marketCap,
    assetFilter,
  ];
}

/// State when no data is available (empty portfolio)
class PortfolioHeatmapEmpty extends PortfolioHeatmapState {
  const PortfolioHeatmapEmpty({
    this.message = 'No portfolio data available',
    this.timeFrame,
    this.metric,
  });
  final String message;
  final TimeFrame? timeFrame;
  final MetricType? metric;

  @override
  List<Object?> get props => [message, timeFrame, metric];
}
