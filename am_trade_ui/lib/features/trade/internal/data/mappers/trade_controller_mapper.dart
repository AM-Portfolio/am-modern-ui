import '../../domain/entities/trade_controller_entities.dart';
import '../dtos/trade_controller_dtos.dart';

/// Mapper for converting between TradeController DTOs and domain entities
class TradeControllerMapper {
  TradeControllerMapper._();

  // DerivativeInfo mappings
  static DerivativeInfo toDerivativeInfoEntity(DerivativeInfoDto dto) => DerivativeInfo(
    derivativeType: dto.derivativeType,
    strikePrice: dto.strikePrice,
    expiryDate: dto.expiryDate != null ? DateTime.tryParse(dto.expiryDate!) : null,
    optionType: dto.optionType,
    underlyingSymbol: dto.underlyingSymbol,
  );

  static DerivativeInfoDto toDerivativeInfoDto(DerivativeInfo entity) => DerivativeInfoDto(
    derivativeType: entity.derivativeType,
    strikePrice: entity.strikePrice,
    expiryDate: entity.expiryDate?.toIso8601String().split('T').first,
    optionType: entity.optionType,
    underlyingSymbol: entity.underlyingSymbol,
  );

  // InstrumentInfo mappings
  static InstrumentInfo toInstrumentInfoEntity(InstrumentInfoDto dto) => InstrumentInfo(
    symbol: dto.symbol,
    isin: dto.isin,
    rawSymbol: dto.rawSymbol,
    exchange: dto.exchange,
    segment: dto.segment,
    series: dto.series,
    indexType: dto.indexType,
    derivativeInfo: dto.derivativeInfo != null ? toDerivativeInfoEntity(dto.derivativeInfo!) : null,
    description: dto.description,
    currency: dto.currency,
    lotSize: dto.lotSize,
  );

  static InstrumentInfoDto toInstrumentInfoDto(InstrumentInfo entity) => InstrumentInfoDto(
    symbol: entity.symbol,
    isin: entity.isin,
    rawSymbol: entity.rawSymbol,
    exchange: entity.exchange,
    segment: entity.segment,
    series: entity.series,
    indexType: entity.indexType,
    derivativeInfo: entity.derivativeInfo != null ? toDerivativeInfoDto(entity.derivativeInfo!) : null,
    description: entity.description,
    currency: entity.currency,
    lotSize: entity.lotSize,
  );

  // EntryExitInfo mappings
  static EntryExitInfo toEntryExitInfoEntity(EntryExitInfoDto dto) => EntryExitInfo(
    timestamp: dto.timestamp != null ? DateTime.tryParse(dto.timestamp!) : null,
    price: dto.price,
    quantity: dto.quantity,
    totalValue: dto.totalValue,
    fees: dto.fees,
    reason: dto.reason,
  );

  static EntryExitInfoDto toEntryExitInfoDto(EntryExitInfo entity) => EntryExitInfoDto(
    timestamp: entity.timestamp?.toIso8601String(),
    price: entity.price,
    quantity: entity.quantity,
    totalValue: entity.totalValue,
    fees: entity.fees,
    reason: entity.reason,
  );

  // TradeMetrics mappings
  static TradeMetrics toTradeMetricsEntity(TradeMetricsDto dto) => TradeMetrics(
    profitLoss: dto.profitLoss,
    profitLossPercentage: dto.profitLossPercentage,
    returnOnEquity: dto.returnOnEquity,
    riskAmount: dto.riskAmount,
    rewardAmount: dto.rewardAmount,
    riskRewardRatio: dto.riskRewardRatio,
    holdingTimeDays: dto.holdingTimeDays,
    holdingTimeHours: dto.holdingTimeHours,
    holdingTimeMinutes: dto.holdingTimeMinutes,
    maxAdverseExcursion: dto.maxAdverseExcursion,
    maxFavorableExcursion: dto.maxFavorableExcursion,
  );

  static TradeMetricsDto toTradeMetricsDto(TradeMetrics entity) => TradeMetricsDto(
    profitLoss: entity.profitLoss,
    profitLossPercentage: entity.profitLossPercentage,
    returnOnEquity: entity.returnOnEquity,
    riskAmount: entity.riskAmount,
    rewardAmount: entity.rewardAmount,
    riskRewardRatio: entity.riskRewardRatio,
    holdingTimeDays: entity.holdingTimeDays,
    holdingTimeHours: entity.holdingTimeHours,
    holdingTimeMinutes: entity.holdingTimeMinutes,
    maxAdverseExcursion: entity.maxAdverseExcursion,
    maxFavorableExcursion: entity.maxFavorableExcursion,
  );

  // Attachment mappings
  static Attachment toAttachmentEntity(AttachmentDto dto) => Attachment(
    fileName: dto.fileName,
    fileUrl: dto.fileUrl,
    fileType: dto.fileType,
    uploadedAt: dto.uploadedAt != null ? DateTime.tryParse(dto.uploadedAt!) : null,
    description: dto.description,
  );

  static AttachmentDto toAttachmentDto(Attachment entity) => AttachmentDto(
    fileName: entity.fileName,
    fileUrl: entity.fileUrl,
    fileType: entity.fileType,
    uploadedAt: entity.uploadedAt?.toIso8601String(),
    description: entity.description,
  );

  // TradePsychologyData mappings
  static TradePsychologyData toTradePsychologyDataEntity(TradePsychologyDataDto dto) => TradePsychologyData(
    entryPsychologyFactors: dto.entryPsychologyFactors,
    exitPsychologyFactors: dto.exitPsychologyFactors,
    behaviorPatterns: dto.behaviorPatterns,
    categorizedTags: dto.categorizedTags,
    psychologyNotes: dto.psychologyNotes,
  );

  static TradePsychologyDataDto toTradePsychologyDataDto(TradePsychologyData entity) => TradePsychologyDataDto(
    entryPsychologyFactors: entity.entryPsychologyFactors,
    exitPsychologyFactors: entity.exitPsychologyFactors,
    behaviorPatterns: entity.behaviorPatterns,
    categorizedTags: entity.categorizedTags,
    psychologyNotes: entity.psychologyNotes,
  );

  // TradeEntryExitReasoning mappings
  static TradeEntryExitReasoning toTradeEntryExitReasoningEntity(TradeEntryExitReasoningDto dto) =>
      TradeEntryExitReasoning(
        technicalReasons: dto.technicalReasons,
        fundamentalReasons: dto.fundamentalReasons,
        primaryReason: dto.primaryReason,
        reasoningSummary: dto.reasoningSummary,
        confidenceLevel: dto.confidenceLevel,
        supportingIndicators: dto.supportingIndicators,
        conflictingIndicators: dto.conflictingIndicators,
        exitPrimaryReason: dto.exitPrimaryReason,
        exitReasoningSummary: dto.exitReasoningSummary,
        exitConfidenceLevel: dto.exitConfidenceLevel,
        exitSupportingIndicators: dto.exitSupportingIndicators,
        exitConflictingIndicators: dto.exitConflictingIndicators,
        exitQualityScore: dto.exitQualityScore,
        strategy: dto.streategy, // Note: mapping from misspelled 'streategy'
      );

  static TradeEntryExitReasoningDto toTradeEntryExitReasoningDto(TradeEntryExitReasoning entity) =>
      TradeEntryExitReasoningDto(
        technicalReasons: entity.technicalReasons,
        fundamentalReasons: entity.fundamentalReasons,
        primaryReason: entity.primaryReason,
        reasoningSummary: entity.reasoningSummary,
        confidenceLevel: entity.confidenceLevel,
        supportingIndicators: entity.supportingIndicators,
        conflictingIndicators: entity.conflictingIndicators,
        exitPrimaryReason: entity.exitPrimaryReason,
        exitReasoningSummary: entity.exitReasoningSummary,
        exitConfidenceLevel: entity.exitConfidenceLevel,
        exitSupportingIndicators: entity.exitSupportingIndicators,
        exitConflictingIndicators: entity.exitConflictingIndicators,
        exitQualityScore: entity.exitQualityScore,
        streategy: entity.strategy, // Note: mapping to misspelled 'streategy'
      );

  // BasicInfo mappings
  static BasicInfo toBasicInfoEntity(BasicInfoDto dto) => BasicInfo(
    tradeId: dto.tradeId,
    orderId: dto.orderId,
    tradeDate: dto.tradeDate != null ? DateTime.tryParse(dto.tradeDate!) : null,
    orderExecutionTime: dto.orderExecutionTime != null ? DateTime.tryParse(dto.orderExecutionTime!) : null,
    brokerType: dto.brokerType,
    tradeType: dto.tradeType,
  );

  static BasicInfoDto toBasicInfoDto(BasicInfo entity) => BasicInfoDto(
    tradeId: entity.tradeId,
    orderId: entity.orderId,
    tradeDate: entity.tradeDate?.toIso8601String().split('T').first,
    orderExecutionTime: entity.orderExecutionTime?.toIso8601String(),
    brokerType: entity.brokerType,
    tradeType: entity.tradeType,
  );

  // ExecutionInfo mappings
  static ExecutionInfo toExecutionInfoEntity(ExecutionInfoDto dto) =>
      ExecutionInfo(quantity: dto.quantity, price: dto.price, orderType: dto.orderType);

  static ExecutionInfoDto toExecutionInfoDto(ExecutionInfo entity) =>
      ExecutionInfoDto(quantity: entity.quantity, price: entity.price, orderType: entity.orderType);

  // FnOInfo mappings
  static FnOInfo toFnOInfoEntity(FnOInfoDto dto) => FnOInfo(
    expiryDate: dto.expiryDate != null ? DateTime.tryParse(dto.expiryDate!) : null,
    strikePrice: dto.strikePrice,
    optionType: dto.optionType,
  );

  static FnOInfoDto toFnOInfoDto(FnOInfo entity) => FnOInfoDto(
    expiryDate: entity.expiryDate?.toIso8601String().split('T').first,
    strikePrice: entity.strikePrice,
    optionType: entity.optionType,
  );

  // Charges mappings
  static Charges toChargesEntity(ChargesDto dto) => Charges(
    brokerage: dto.brokerage,
    stt: dto.stt,
    transactionCharges: dto.transactionCharges,
    stampDuty: dto.stampDuty,
    sebiCharges: dto.sebiCharges,
    gst: dto.gst,
    totalTaxes: dto.totalTaxes,
  );

  static ChargesDto toChargesDto(Charges entity) => ChargesDto(
    brokerage: entity.brokerage,
    stt: entity.stt,
    transactionCharges: entity.transactionCharges,
    stampDuty: entity.stampDuty,
    sebiCharges: entity.sebiCharges,
    gst: entity.gst,
    totalTaxes: entity.totalTaxes,
  );

  // Financials mappings
  static Financials toFinancialsEntity(FinancialsDto dto) =>
      Financials(turnover: dto.turnover, netAmount: dto.netAmount);

  static FinancialsDto toFinancialsDto(Financials entity) =>
      FinancialsDto(turnover: entity.turnover, netAmount: entity.netAmount);

  // TradeModel mappings
  static TradeModel toTradeModelEntity(TradeModelDto dto) => TradeModel(
    basicInfo: dto.basicInfo != null ? toBasicInfoEntity(dto.basicInfo!) : null,
    instrumentInfo: dto.instrumentInfo != null ? toInstrumentInfoEntity(dto.instrumentInfo!) : null,
    executionInfo: dto.executionInfo != null ? toExecutionInfoEntity(dto.executionInfo!) : null,
    fnoInfo: dto.fnoInfo != null ? toFnOInfoEntity(dto.fnoInfo!) : null,
    charges: dto.charges != null ? toChargesEntity(dto.charges!) : null,
    financials: dto.financials != null ? toFinancialsEntity(dto.financials!) : null,
  );

  static TradeModelDto toTradeModelDto(TradeModel entity) => TradeModelDto(
    basicInfo: entity.basicInfo != null ? toBasicInfoDto(entity.basicInfo!) : null,
    instrumentInfo: entity.instrumentInfo != null ? toInstrumentInfoDto(entity.instrumentInfo!) : null,
    executionInfo: entity.executionInfo != null ? toExecutionInfoDto(entity.executionInfo!) : null,
    fnoInfo: entity.fnoInfo != null ? toFnOInfoDto(entity.fnoInfo!) : null,
    charges: entity.charges != null ? toChargesDto(entity.charges!) : null,
    financials: entity.financials != null ? toFinancialsDto(entity.financials!) : null,
  );

  // TradeDetails mappings
  static TradeDetails toTradeDetailsEntity(TradeDetailsDto dto) => TradeDetails(
    tradeId: dto.tradeId,
    portfolioId: dto.portfolioId,
    instrumentInfo: toInstrumentInfoEntity(dto.instrumentInfo),
    symbol: dto.symbol,
    strategy: dto.strategy,
    status: dto.status,
    tradePositionType: dto.tradePositionType,
    entryInfo: toEntryExitInfoEntity(dto.entryInfo),
    exitInfo: dto.exitInfo != null ? toEntryExitInfoEntity(dto.exitInfo!) : null,
    metrics: dto.metrics != null ? toTradeMetricsEntity(dto.metrics!) : null,
    tradeExecutions: dto.tradeExecutions?.map(toTradeModelEntity).toList(),
    notes: dto.notes,
    tags: dto.tags,
    userId: dto.userId,
    attachments: dto.attachments?.map(toAttachmentEntity).toList(),
    psychologyData: dto.psychologyData != null ? toTradePsychologyDataEntity(dto.psychologyData!) : null,
    entryReasoning: dto.entryReasoning != null ? toTradeEntryExitReasoningEntity(dto.entryReasoning!) : null,
    exitReasoning: dto.exitReasoning != null ? toTradeEntryExitReasoningEntity(dto.exitReasoning!) : null,
  );

  static TradeDetailsDto toTradeDetailsDto(TradeDetails entity) => TradeDetailsDto(
    tradeId: entity.tradeId,
    portfolioId: entity.portfolioId,
    instrumentInfo: toInstrumentInfoDto(entity.instrumentInfo),
    symbol: entity.symbol,
    strategy: entity.strategy,
    status: entity.status,
    tradePositionType: entity.tradePositionType,
    entryInfo: toEntryExitInfoDto(entity.entryInfo),
    exitInfo: entity.exitInfo != null ? toEntryExitInfoDto(entity.exitInfo!) : null,
    metrics: entity.metrics != null ? toTradeMetricsDto(entity.metrics!) : null,
    tradeExecutions: entity.tradeExecutions?.map(toTradeModelDto).toList(),
    notes: entity.notes,
    tags: entity.tags,
    userId: entity.userId,
    attachments: entity.attachments?.map(toAttachmentDto).toList(),
    psychologyData: entity.psychologyData != null ? toTradePsychologyDataDto(entity.psychologyData!) : null,
    entryReasoning: entity.entryReasoning != null ? toTradeEntryExitReasoningDto(entity.entryReasoning!) : null,
    exitReasoning: entity.exitReasoning != null ? toTradeEntryExitReasoningDto(entity.exitReasoning!) : null,
  );

  // FilterSummary mappings
  static FilterSummary toFilterSummaryEntity(FilterSummaryDto dto) => FilterSummary(
    portfolioIds: dto.portfolioIds,
    symbols: dto.symbols,
    statuses: dto.statuses,
    dateRange: dto.dateRange,
    strategies: dto.strategies,
    profitLossRange: dto.profitLossRange,
    holdingTimeRange: dto.holdingTimeRange,
  );

  static FilterSummaryDto toFilterSummaryDto(FilterSummary entity) => FilterSummaryDto(
    portfolioIds: entity.portfolioIds,
    symbols: entity.symbols,
    statuses: entity.statuses,
    dateRange: entity.dateRange,
    strategies: entity.strategies,
    profitLossRange: entity.profitLossRange,
    holdingTimeRange: entity.holdingTimeRange,
  );

  // FilterTradeDetailsResponse mappings
  static FilterTradeDetailsResponse toFilterTradeDetailsResponseEntity(FilterTradeDetailsResponseDto dto) =>
      FilterTradeDetailsResponse(
        trades: dto.trades?.map(toTradeDetailsEntity).toList(),
        totalCount: dto.totalCount,
        appliedFilterName: dto.appliedFilterName,
        filterSummary: dto.filterSummary != null ? toFilterSummaryEntity(dto.filterSummary!) : null,
        page: dto.page,
        size: dto.size,
        totalPages: dto.totalPages,
        isFirst: dto.isFirst,
        isLast: dto.isLast,
      );

  static FilterTradeDetailsResponseDto toFilterTradeDetailsResponseDto(FilterTradeDetailsResponse entity) =>
      FilterTradeDetailsResponseDto(
        trades: entity.trades?.map(toTradeDetailsDto).toList(),
        totalCount: entity.totalCount,
        appliedFilterName: entity.appliedFilterName,
        filterSummary: entity.filterSummary != null ? toFilterSummaryDto(entity.filterSummary!) : null,
        page: entity.page,
        size: entity.size,
        totalPages: entity.totalPages,
        isFirst: entity.isFirst,
        isLast: entity.isLast,
      );

  // PaginatedTradeResponse mappings
  static PaginatedTradeResponse toPaginatedTradeResponseEntity(PaginatedTradeResponseDto dto) => PaginatedTradeResponse(
    content: dto.content?.map(toTradeDetailsEntity).toList(),
    totalElements: dto.totalElements,
    totalPages: dto.totalPages,
    size: dto.size,
    number: dto.number,
  );

  static PaginatedTradeResponseDto toPaginatedTradeResponseDto(PaginatedTradeResponse entity) =>
      PaginatedTradeResponseDto(
        content: entity.content?.map(toTradeDetailsDto).toList(),
        totalElements: entity.totalElements,
        totalPages: entity.totalPages,
        size: entity.size,
        number: entity.number,
      );

  // ErrorResponse mappings
  static ErrorResponse toErrorResponseEntity(ErrorResponseDto dto) => ErrorResponse(
    timestamp: dto.timestamp != null ? DateTime.tryParse(dto.timestamp!) : null,
    status: dto.status,
    error: dto.error,
    message: dto.message,
    path: dto.path,
    details: dto.details,
  );

  static ErrorResponseDto toErrorResponseDto(ErrorResponse entity) => ErrorResponseDto(
    timestamp: entity.timestamp?.toIso8601String(),
    status: entity.status,
    error: entity.error,
    message: entity.message,
    path: entity.path,
    details: entity.details,
  );
}
