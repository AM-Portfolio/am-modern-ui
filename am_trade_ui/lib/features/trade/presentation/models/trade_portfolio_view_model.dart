import '../../internal/domain/entities/trade_portfolio.dart';

/// View model for trade portfolio presentation
class TradePortfolioViewModel {
  const TradePortfolioViewModel({
    required this.id,
    required this.name,
    this.ownerId,
    this.totalValue = 0.0,
    this.totalGainLoss = 0.0,
    this.totalGainLossPercentage = 0.0,
    this.holdingsCount = 0,
    this.description,
    this.lastUpdated,
    // Trade metrics
    this.totalTrades = 0,
    this.netProfitLoss,
    this.netProfitLossPercentage,
    this.winRate,
    this.winningTrades = 0,
    this.losingTrades = 0,
    this.openPositions = 0,
  });

  /// Factory from domain entity
  factory TradePortfolioViewModel.fromEntity(TradePortfolio entity) => TradePortfolioViewModel(
    id: entity.id,
    name: entity.name,
    ownerId: entity.ownerId,
    totalValue: entity.totalValue ?? 0.0,
    totalGainLoss: entity.totalGainLoss ?? 0.0,
    totalGainLossPercentage: entity.totalGainLossPercentage ?? 0.0,
    holdingsCount: entity.holdingsCount,
    description: entity.description,
    lastUpdated: entity.lastUpdated,
    // Trade metrics
    totalTrades: entity.totalTrades,
    netProfitLoss: entity.netProfitLoss,
    netProfitLossPercentage: entity.netProfitLossPercentage,
    winRate: entity.winRate,
    winningTrades: entity.winningTrades,
    losingTrades: entity.losingTrades,
    openPositions: entity.openPositions,
  );

  final String id;
  final String name;
  final String? ownerId;
  final double totalValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final int holdingsCount;
  final String? description;
  final DateTime? lastUpdated;

  // Trade metrics
  final int totalTrades;
  final double? netProfitLoss;
  final double? netProfitLossPercentage;
  final double? winRate;
  final int winningTrades;
  final int losingTrades;
  final int openPositions;

  /// Computed properties for UI
  String get displayName => name;
  String get displayValue => '\$${totalValue.toStringAsFixed(2)}';
  String get displayGainLoss => '\$${totalGainLoss.toStringAsFixed(2)}';
  String get displayGainLossPercentage => '${totalGainLossPercentage.toStringAsFixed(2)}%';
  String get displayHoldingsCount => '$holdingsCount holdings';
  bool get isProfit => totalGainLoss >= 0;

  // Trade metrics computed properties
  String get displayTotalTrades => '$totalTrades';
  String get displayNetProfitLoss => '\$${(netProfitLoss ?? 0.0).toStringAsFixed(2)}';
  String get displayNetProfitLossPercentage => '${(netProfitLossPercentage ?? 0.0).toStringAsFixed(2)}%';
  String get displayWinRate => '${(winRate ?? 0.0).toStringAsFixed(1)}%';
  String get displayOpenPositions => '$openPositions';
  String get displayWinLossRecord => '$winningTrades W / $losingTrades L';
  bool get isTradeProfit => (netProfitLoss ?? 0.0) >= 0;

  static List<TradePortfolioViewModel> fromEntityList(List<TradePortfolio> entities) =>
      entities.map(TradePortfolioViewModel.fromEntity).toList();
}

/// View model for portfolio list
class TradePortfolioListViewModel {
  const TradePortfolioListViewModel({required this.userId, required this.portfolios, this.totalCount = 0});

  /// Factory from domain entity
  factory TradePortfolioListViewModel.fromEntity(TradePortfolioList entity) => TradePortfolioListViewModel(
    userId: entity.userId,
    portfolios: TradePortfolioViewModel.fromEntityList(entity.portfolios),
    totalCount: entity.totalCount,
  );

  factory TradePortfolioListViewModel.empty(String userId) =>
      TradePortfolioListViewModel(userId: userId, portfolios: []);

  final String userId;
  final List<TradePortfolioViewModel> portfolios;
  final int totalCount;

  /// Computed properties
  int get displayCount => portfolios.length;
  String get displayTotal => '$totalCount portfolios';
}
