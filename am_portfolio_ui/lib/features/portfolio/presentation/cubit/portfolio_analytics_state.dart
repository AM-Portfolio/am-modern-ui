import 'package:equatable/equatable.dart';
import '../../internal/domain/entities/portfolio_analytics.dart';

/// Represents different types of analytics data
enum AnalyticsDataType {
  sectorAllocation,
  marketCapAllocation,
  heatmap,
  movers,
}

/// Base class for all portfolio analytics states
abstract class PortfolioAnalyticsState extends Equatable {
  const PortfolioAnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when analytics are not loaded
class PortfolioAnalyticsInitial extends PortfolioAnalyticsState {}

/// Loading state when analytics data is being fetched
class PortfolioAnalyticsLoading extends PortfolioAnalyticsState {
  const PortfolioAnalyticsLoading({this.loadingTypes = const {}});
  final Set<AnalyticsDataType> loadingTypes;

  @override
  List<Object?> get props => [loadingTypes];
}

/// Loaded state with analytics data
class PortfolioAnalyticsLoaded extends PortfolioAnalyticsState {
  const PortfolioAnalyticsLoaded({
    this.sectorAllocation,
    this.marketCapAllocation,
    this.heatmap,
    this.movers,
    this.isRefreshing = false,
    this.loadingTypes = const {},
    this.errors = const {},
  });
  final SectorAllocation? sectorAllocation;
  final MarketCapAllocation? marketCapAllocation;
  final Heatmap? heatmap;
  final Movers? movers;
  final bool isRefreshing;
  final Set<AnalyticsDataType> loadingTypes;
  final Map<AnalyticsDataType, String> errors;

  PortfolioAnalyticsLoaded copyWith({
    SectorAllocation? sectorAllocation,
    MarketCapAllocation? marketCapAllocation,
    Heatmap? heatmap,
    Movers? movers,
    bool? isRefreshing,
    Set<AnalyticsDataType>? loadingTypes,
    Map<AnalyticsDataType, String>? errors,
  }) => PortfolioAnalyticsLoaded(
    sectorAllocation: sectorAllocation ?? this.sectorAllocation,
    marketCapAllocation: marketCapAllocation ?? this.marketCapAllocation,
    heatmap: heatmap ?? this.heatmap,
    movers: movers ?? this.movers,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    loadingTypes: loadingTypes ?? this.loadingTypes,
    errors: errors ?? this.errors,
  );

  /// Check if a specific analytics type is loading
  bool isLoadingType(AnalyticsDataType type) => loadingTypes.contains(type);

  /// Check if a specific analytics type has an error
  bool hasErrorForType(AnalyticsDataType type) => errors.containsKey(type);

  /// Get error message for a specific analytics type
  String? getErrorForType(AnalyticsDataType type) => errors[type];

  /// Check if all data is loaded (no loading states and no initial nulls)
  bool get isAllDataLoaded =>
      loadingTypes.isEmpty &&
      sectorAllocation != null &&
      marketCapAllocation != null &&
      heatmap != null &&
      movers != null;

  /// Check if any data is loading
  bool get isAnyDataLoading => loadingTypes.isNotEmpty || isRefreshing;

  @override
  List<Object?> get props => [
    sectorAllocation,
    marketCapAllocation,
    heatmap,
    movers,
    isRefreshing,
    loadingTypes,
    errors,
  ];
}

/// Error state when analytics loading fails completely
class PortfolioAnalyticsError extends PortfolioAnalyticsState {
  const PortfolioAnalyticsError(this.message, {this.specificErrors = const {}});
  final String message;
  final Map<AnalyticsDataType, String> specificErrors;

  @override
  List<Object?> get props => [message, specificErrors];
}
