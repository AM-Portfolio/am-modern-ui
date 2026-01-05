import 'package:equatable/equatable.dart';
import 'package:am_design_system/shared/models/heatmap/heatmap_ui_data.dart';
import 'package:am_design_system/am_design_system.dart';

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
  });
  final HeatmapData heatmapData;
  final TimeFrame timeFrame;
  final MetricType metric;
  final SectorType? sector;
  final MarketCapType? marketCap;
  final String portfolioId;
  final DateTime lastUpdated;

  @override
  List<Object?> get props => [
    heatmapData,
    timeFrame,
    metric,
    sector,
    marketCap,
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
    String? portfolioId,
    DateTime? lastUpdated,
  }) => PortfolioHeatmapLoaded(
    heatmapData: heatmapData ?? this.heatmapData,
    timeFrame: timeFrame ?? this.timeFrame,
    metric: metric ?? this.metric,
    sector: sector ?? this.sector,
    marketCap: marketCap ?? this.marketCap,
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
  });
  final String message;
  final String? details;
  final TimeFrame? timeFrame;
  final MetricType? metric;
  final SectorType? sector;
  final MarketCapType? marketCap;

  @override
  List<Object?> get props => [
    message,
    details,
    timeFrame,
    metric,
    sector,
    marketCap,
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
