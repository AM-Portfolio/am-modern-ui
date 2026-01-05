import 'package:equatable/equatable.dart';
import '../../../../shared/models/heatmap/heatmap_ui_data.dart';
import 'package:am_design_system/am_design_system.dart';

/// Base state for PortfolioHeatmapCubit
abstract class PortfolioHeatmapState extends Equatable {
  const PortfolioHeatmapState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class PortfolioHeatmapInitial extends PortfolioHeatmapState {
  const PortfolioHeatmapInitial();
}

/// Loading state
class PortfolioHeatmapLoading extends PortfolioHeatmapState {
  const PortfolioHeatmapLoading({this.message = 'Loading...'});
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Loaded state with data
class PortfolioHeatmapLoaded extends PortfolioHeatmapState {
  const PortfolioHeatmapLoaded({
    required this.data,
    required this.portfolioId,
    required this.timeFrame,
    required this.metric,
    required this.sector,
    required this.marketCap,
  });
  final HeatmapData data;
  final String portfolioId;
  final TimeFrame timeFrame;
  final MetricType metric;
  final SectorType sector;
  final MarketCapType marketCap;

  @override
  List<Object?> get props => [
    data,
    portfolioId,
    timeFrame,
    metric,
    sector,
    marketCap,
  ];
}

/// Error state
class PortfolioHeatmapError extends PortfolioHeatmapState {
  const PortfolioHeatmapError({
    required this.message,
    this.error,
    this.stackTrace,
  });
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, error, stackTrace];
}

/// Empty state
class PortfolioHeatmapEmpty extends PortfolioHeatmapState {
  const PortfolioHeatmapEmpty({this.message = 'No data available'});
  final String message;

  @override
  List<Object?> get props => [message];
}
