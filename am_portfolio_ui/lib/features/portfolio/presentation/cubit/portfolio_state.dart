import 'package:equatable/equatable.dart';
import '../../internal/domain/entities/portfolio_summary.dart';
import '../../internal/domain/entities/portfolio_holding.dart';
import '../../internal/domain/entities/portfolio_list.dart';

/// Represents different portfolio views
enum PortfolioViewType { overview, holdings, analysis, heatmap }

/// Base class for all portfolio states
abstract class PortfolioState extends Equatable {
  const PortfolioState({this.portfolioList});

  final PortfolioList? portfolioList;

  @override
  List<Object?> get props => [portfolioList];
}

/// Initial state when portfolio is not loaded
class PortfolioInitial extends PortfolioState {
  const PortfolioInitial({super.portfolioList});
}

/// Loading state when portfolio data is being fetched
class PortfolioLoading extends PortfolioState {
  const PortfolioLoading({super.portfolioList});
}

/// Loaded state with portfolio data
class PortfolioLoaded extends PortfolioState {
  const PortfolioLoaded({
    required this.portfolioId,
    required this.summary,
    required this.holdings,
    super.portfolioList,
    this.currentView = PortfolioViewType.overview,
    this.isRefreshing = false,
    this.searchQuery = '',
    this.searchResults = const [],
  });
  final String portfolioId;
  final PortfolioSummary summary;
  final List<PortfolioHolding> holdings;
  final PortfolioViewType currentView;
  final bool isRefreshing;
  final String searchQuery;
  final List<PortfolioHolding> searchResults;

  PortfolioLoaded copyWith({
    String? portfolioId,
    PortfolioSummary? summary,
    List<PortfolioHolding>? holdings,
    PortfolioList? portfolioList,
    PortfolioViewType? currentView,
    bool? isRefreshing,
    String? searchQuery,
    List<PortfolioHolding>? searchResults,
  }) => PortfolioLoaded(
    portfolioId: portfolioId ?? this.portfolioId,
    summary: summary ?? this.summary,
    holdings: holdings ?? this.holdings,
    portfolioList: portfolioList ?? this.portfolioList,
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
  const PortfolioError(this.message, {super.portfolioList});
  final String message;

  @override
  List<Object?> get props => [message, portfolioList];
}

/// Loading state when portfolio list is being fetched
class PortfolioListLoading extends PortfolioState {
  const PortfolioListLoading({super.portfolioList});
}

/// Loaded state with portfolio list data
class PortfolioListLoaded extends PortfolioState {
  const PortfolioListLoaded({
    required PortfolioList portfolioList,
    this.isRefreshing = false,
  }) : super(portfolioList: portfolioList);
  final bool isRefreshing;

  PortfolioListLoaded copyWith({
    PortfolioList? portfolioList,
    bool? isRefreshing,
  }) => PortfolioListLoaded(
    portfolioList: portfolioList ?? this.portfolioList!,
    isRefreshing: isRefreshing ?? this.isRefreshing,
  );

  @override
  List<Object?> get props => [portfolioList, isRefreshing];
}

/// Error state when portfolio list loading fails
class PortfolioListError extends PortfolioState {
  const PortfolioListError(this.message, {super.portfolioList});
  final String message;

  @override
  List<Object?> get props => [message, portfolioList];
}
