import '../../internal/domain/entities/trade_controller_entities.dart';
import '../../internal/domain/entities/trade_holding.dart';

/// View model for presenting trade holding data in UI
/// Flattens nested domain structure for easier template consumption
class TradeHoldingViewModel {
  const TradeHoldingViewModel({
    required this.tradeId,
    required this.portfolioId,
    required this.symbol,
    required this.companyName,
    this.sector,
    this.industry,
    this.exchange,
    this.status,
    this.tradePositionType,
    this.quantity,
    this.entryPrice,
    this.exitPrice,
    this.currentPrice,
    this.avgPrice,
    this.currentValue,
    this.profitLoss,
    this.profitLossPercentage,
    this.riskAmount,
    this.rewardAmount,
    this.riskRewardRatio,
    this.holdingDays,
    this.entryTimestamp,
    this.exitTimestamp,
    this.broker,
    this.executionCount = 0,
    // New fields from TradeDetails
    this.strategy,
    this.notes,
    this.tags,
    this.userId,
    this.returnOnEquity,
    this.maxAdverseExcursion,
    this.maxFavorableExcursion,
    this.isin,
    this.rawSymbol,
    this.marketSegment,
    this.series,
    this.indexType,
    this.description,
    this.currency,
    this.lotSize,
    this.derivativeType,
    this.strikePrice,
    this.expiryDate,
    this.optionType,
    this.underlyingSymbol,
    this.entryFees,
    this.exitFees,
    this.entryReason,
    this.exitReason,
    this.entryTotalValue,
    this.exitTotalValue,
    this.psychologyData,
    this.entryReasoning,
    this.exitReasoning,
    this.attachments,
  });

  /// Factory to create view model from domain entity
  factory TradeHoldingViewModel.fromEntity(TradeDetails entity) {
    final metrics = entity.metrics;
    final exitInfo = entity.exitInfo;
    final instrumentInfo = entity.instrumentInfo;
    final derivativeInfo = instrumentInfo.derivativeInfo;

    // Extract broker from first execution (if available)
    String? broker;
    if (entity.tradeExecutions != null && entity.tradeExecutions!.isNotEmpty) {
      try {
        broker = entity.tradeExecutions!.first.basicInfo?.brokerType?.name;
      } catch (e) {
        // Ignore broker extraction errors
        broker = null;
      }
    }

    return TradeHoldingViewModel(
      tradeId: entity.tradeId,
      portfolioId: entity.portfolioId,
      symbol: instrumentInfo.symbol ?? entity.symbol ?? 'UNKNOWN',
      companyName: instrumentInfo.description ?? 'Unknown Company',
      sector: instrumentInfo.segment?.name,
      industry: instrumentInfo.series?.name,
      exchange: instrumentInfo.exchange?.name,
      status: entity.status.name,
      tradePositionType: entity.tradePositionType.name,
      quantity: entity.entryInfo.quantity ?? exitInfo?.quantity,
      entryPrice: entity.entryInfo.price,
      exitPrice: exitInfo?.price,
      currentPrice: exitInfo?.price ?? entity.entryInfo.price,
      avgPrice: entity.entryInfo.price,
      currentValue:
          (exitInfo?.quantity ?? entity.entryInfo.quantity ?? 0) * (exitInfo?.price ?? entity.entryInfo.price ?? 0),
      profitLoss: metrics?.profitLoss,
      profitLossPercentage: metrics?.profitLossPercentage,
      riskAmount: metrics?.riskAmount,
      rewardAmount: metrics?.rewardAmount,
      riskRewardRatio: metrics?.riskRewardRatio,
      holdingDays: metrics?.holdingTimeDays,
      entryTimestamp: entity.entryInfo.timestamp,
      exitTimestamp: exitInfo?.timestamp,
      broker: broker,
      executionCount: entity.tradeExecutions?.length ?? 0,
      // New fields
      strategy: entity.strategy,
      notes: entity.notes,
      tags: entity.tags,
      userId: entity.userId,
      returnOnEquity: metrics?.returnOnEquity,
      maxAdverseExcursion: metrics?.maxAdverseExcursion,
      maxFavorableExcursion: metrics?.maxFavorableExcursion,
      isin: instrumentInfo.isin,
      rawSymbol: instrumentInfo.rawSymbol,
      marketSegment: instrumentInfo.segment?.name,
      series: instrumentInfo.series?.name,
      indexType: instrumentInfo.indexType?.name,
      description: instrumentInfo.description,
      currency: instrumentInfo.currency,
      lotSize: instrumentInfo.lotSize,
      derivativeType: derivativeInfo?.derivativeType?.name,
      strikePrice: derivativeInfo?.strikePrice,
      expiryDate: derivativeInfo?.expiryDate,
      optionType: derivativeInfo?.optionType?.name,
      underlyingSymbol: derivativeInfo?.underlyingSymbol,
      entryFees: entity.entryInfo.fees,
      exitFees: exitInfo?.fees,
      entryReason: entity.entryInfo.reason,
      exitReason: exitInfo?.reason,
      entryTotalValue: entity.entryInfo.totalValue,
      exitTotalValue: exitInfo?.totalValue,
      psychologyData: entity.psychologyData,
      entryReasoning: entity.entryReasoning,
      exitReasoning: entity.exitReasoning,
      attachments: entity.attachments,
    );
  }

  final String tradeId;
  final String portfolioId;
  final String symbol;
  final String companyName;
  final String? sector;
  final String? industry;
  final String? exchange;
  final String? status;
  final String? tradePositionType;
  final int? quantity;
  final double? entryPrice;
  final double? exitPrice;
  final double? currentPrice;
  final double? avgPrice;
  final double? currentValue;
  final double? profitLoss;
  final double? profitLossPercentage;
  final double? riskAmount;
  final double? rewardAmount;
  final double? riskRewardRatio;
  final int? holdingDays;
  final DateTime? entryTimestamp;
  final DateTime? exitTimestamp;
  final String? broker;
  final int executionCount;

  // New fields from TradeDetails
  final String? strategy;
  final String? notes;
  final List<String>? tags;
  final String? userId;
  final double? returnOnEquity;
  final double? maxAdverseExcursion;
  final double? maxFavorableExcursion;
  final String? isin;
  final String? rawSymbol;
  final String? marketSegment;
  final String? series;
  final String? indexType;
  final String? description;
  final String? currency;
  final String? lotSize;
  final String? derivativeType;
  final double? strikePrice;
  final DateTime? expiryDate;
  final String? optionType;
  final String? underlyingSymbol;
  final double? entryFees;
  final double? exitFees;
  final String? entryReason;
  final String? exitReason;
  final double? entryTotalValue;
  final double? exitTotalValue;
  final TradePsychologyData? psychologyData;
  final TradeEntryExitReasoning? entryReasoning;
  final TradeEntryExitReasoning? exitReasoning;
  final List<Attachment>? attachments;

  /// Computed properties for UI display
  String get displaySymbol => symbol;
  String get displayCompanyName => companyName;
  String get displaySector => sector ?? 'Unknown';
  String get displayIndustry => industry ?? 'Unknown';
  String get displayExchange => exchange ?? 'Unknown';
  String get displayStatus => status ?? 'Unknown';

  String get displayQuantity => quantity != null ? quantity!.toStringAsFixed(0) : '0';
  String get displayEntryPrice => entryPrice != null ? '\$${entryPrice!.toStringAsFixed(2)}' : 'N/A';
  String get displayExitPrice => exitPrice != null ? '\$${exitPrice!.toStringAsFixed(2)}' : 'N/A';
  String get displayCurrentPrice => currentPrice != null ? '\$${currentPrice!.toStringAsFixed(2)}' : 'N/A';
  String get displayAvgPrice => avgPrice != null ? '\$${avgPrice!.toStringAsFixed(2)}' : 'N/A';
  String get displayCurrentValue => currentValue != null ? '\$${currentValue!.toStringAsFixed(2)}' : 'N/A';

  // Computed values
  double get totalGainLoss => profitLoss ?? 0.0;
  double get totalGainLossPercentage => profitLossPercentage ?? 0.0;
  double get todayChange => 0.0; // Not available in new structure
  double get todayChangePercentage => 0.0; // Not available in new structure

  String get displayProfitLoss => profitLoss != null ? '\$${profitLoss!.toStringAsFixed(2)}' : r'$0.00';
  String get displayProfitLossPercentage =>
      profitLossPercentage != null ? '${profitLossPercentage!.toStringAsFixed(2)}%' : '0.00%';

  String get displayRiskAmount => riskAmount != null ? '\$${riskAmount!.toStringAsFixed(2)}' : 'N/A';
  String get displayRewardAmount => rewardAmount != null ? '\$${rewardAmount!.toStringAsFixed(2)}' : 'N/A';
  String get displayRiskRewardRatio => riskRewardRatio != null ? '${riskRewardRatio!.toStringAsFixed(2)}:1' : 'N/A';

  String get displayHoldingPeriod => holdingDays != null ? '$holdingDays days' : 'N/A';

  bool get isProfit => (profitLoss ?? 0) >= 0;
  bool get isLoss => (profitLoss ?? 0) < 0;

  // Display properties for new fields
  String get displayStrategy => strategy ?? 'No strategy defined';
  String get displayNotes => notes ?? 'No notes';
  bool get hasTags => tags != null && tags!.isNotEmpty;
  String get displayTags => tags?.join(', ') ?? 'No tags';

  String get displayReturnOnEquity => returnOnEquity != null ? '${returnOnEquity!.toStringAsFixed(2)}%' : 'N/A';
  String get displayMaxAdverseExcursion =>
      maxAdverseExcursion != null ? '\$${maxAdverseExcursion!.toStringAsFixed(2)}' : 'N/A';
  String get displayMaxFavorableExcursion =>
      maxFavorableExcursion != null ? '\$${maxFavorableExcursion!.toStringAsFixed(2)}' : 'N/A';

  String get displayCurrency => currency ?? 'USD';
  String get displayLotSize => lotSize ?? 'N/A';

  bool get isDerivative => derivativeType != null;
  String get displayDerivativeType => derivativeType ?? 'N/A';
  String get displayStrikePrice => strikePrice != null ? '\$${strikePrice!.toStringAsFixed(2)}' : 'N/A';
  String get displayExpiryDate =>
      expiryDate != null ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}' : 'N/A';
  String get displayOptionType => optionType ?? 'N/A';
  String get displayUnderlyingSymbol => underlyingSymbol ?? 'N/A';

  String get displayEntryFees => entryFees != null ? '\$${entryFees!.toStringAsFixed(2)}' : 'N/A';
  String get displayExitFees => exitFees != null ? '\$${exitFees!.toStringAsFixed(2)}' : 'N/A';
  String get displayTotalFees =>
      (entryFees != null || exitFees != null) ? '\$${((entryFees ?? 0) + (exitFees ?? 0)).toStringAsFixed(2)}' : 'N/A';

  String get displayEntryReason => entryReason ?? 'Not specified';
  String get displayExitReason => exitReason ?? 'Not specified';

  bool get hasPsychologyData => psychologyData != null;
  bool get hasEntryReasoning => entryReasoning != null;
  bool get hasExitReasoning => exitReasoning != null;
  bool get hasAttachments => attachments != null && attachments!.isNotEmpty;
  int get attachmentCount => attachments?.length ?? 0;

  /// Convert list of entities to view models
  /// Gracefully handles conversion errors to prevent one bad trade from breaking the entire list
  static List<TradeHoldingViewModel> fromEntityList(List<TradeDetails> entities) {
    final viewModels = <TradeHoldingViewModel>[];

    for (final entity in entities) {
      try {
        viewModels.add(TradeHoldingViewModel.fromEntity(entity));
      } catch (e) {
        // Log error but continue processing other trades
        // AppLogger.error('Error converting trade to view model', error: e);
        // Skip this trade and continue with others
      }
    }

    return viewModels;
  }
}

/// View model for holdings collection
class TradeHoldingsViewModel {
  const TradeHoldingsViewModel({
    required this.userId,
    required this.portfolioId,
    required this.holdings,
    required this.totalElements,
    this.totalPages = 0,
    this.currentPage = 0,
    this.hasMore = false,
  });

  /// Factory from domain entity
  factory TradeHoldingsViewModel.fromEntity(TradeHoldings entity) => TradeHoldingsViewModel(
    userId: entity.userId,
    portfolioId: entity.portfolioId,
    holdings: TradeHoldingViewModel.fromEntityList(entity.content),
    totalElements: entity.totalElements,
    totalPages: entity.totalPages,
    currentPage: entity.number,
    hasMore: !entity.last,
  );

  /// Empty state
  factory TradeHoldingsViewModel.empty(String userId, String portfolioId) =>
      TradeHoldingsViewModel(userId: userId, portfolioId: portfolioId, holdings: [], totalElements: 0);

  final String userId;
  final String portfolioId;
  final List<TradeHoldingViewModel> holdings;
  final int totalElements;
  final int totalPages;
  final int currentPage;
  final bool hasMore;

  /// Computed properties
  int get displayCount => holdings.length;
  String get displayTotal => '$totalElements total trades';
}
