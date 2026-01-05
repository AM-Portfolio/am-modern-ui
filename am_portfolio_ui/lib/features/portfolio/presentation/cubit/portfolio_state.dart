import 'package:equatable/equatable.dart';
import '../../internal/domain/entities/portfolio_summary.dart';
import '../../internal/domain/entities/portfolio_holding.dart';
import '../../internal/domain/entities/portfolio_list.dart';

/// Represents different portfolio views
enum PortfolioViewType { overview, holdings, analysis, heatmap }

/// Base class for all portfolio states
abstract class PortfolioState extends Equatable {
  const PortfolioState();

  @override
  List<Object?> get props => [];
}

/// Initial state when portfolio is not loaded
class PortfolioInitial extends PortfolioState {}

/// Loading state when portfolio data is being fetched
class PortfolioLoading extends PortfolioState {}

/// Loaded state with portfolio data
class PortfolioLoaded extends PortfolioState {
  const PortfolioLoaded({
    required this.summary,
    required this.holdings,
    this.currentView = PortfolioViewType.overview,
    this.isRefreshing = false,
    this.searchQuery = '',
    this.searchResults = const [],
  });
  final PortfolioSummary summary;
  final List<PortfolioHolding> holdings;
  final PortfolioViewType currentView;
  final bool isRefreshing;
  final String searchQuery;
  final List<PortfolioHolding> searchResults;

  PortfolioLoaded copyWith({
    PortfolioSummary? summary,
    List<PortfolioHolding>? holdings,
    PortfolioViewType? currentView,
    bool? isRefreshing,
    String? searchQuery,
    List<PortfolioHolding>? searchResults,
  }) => PortfolioLoaded(
    summary: summary ?? this.summary,
    holdings: holdings ?? this.holdings,
    currentView: currentView ?? this.currentView,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    searchQuery: searchQuery ?? this.searchQuery,
    searchResults: searchResults ?? this.searchResults,
  );

  @override
  List<Object?> get props => [
    summary,
    holdings,
    currentView,
    isRefreshing,
    searchQuery,
    searchResults,
  ];
}

/// Error state when portfolio loading fails
class PortfolioError extends PortfolioState {
  const PortfolioError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Loading state when portfolio list is being fetched
class PortfolioListLoading extends PortfolioState {}

/// Loaded state with portfolio list data
class PortfolioListLoaded extends PortfolioState {
  const PortfolioListLoaded({
    required this.portfolioList,
    this.isRefreshing = false,
  });
  final PortfolioList portfolioList;
  final bool isRefreshing;

  PortfolioListLoaded copyWith({
    PortfolioList? portfolioList,
    bool? isRefreshing,
  }) => PortfolioListLoaded(
    portfolioList: portfolioList ?? this.portfolioList,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => [portfolioList, isRefreshing];
}

/// Error state when portfolio list loading fails
class PortfolioListError extends PortfolioState {
  const PortfolioListError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
