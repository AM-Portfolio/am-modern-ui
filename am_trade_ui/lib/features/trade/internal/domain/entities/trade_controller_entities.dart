import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/broker_types.dart';
import '../enums/derivative_types.dart';
import '../enums/exchange_types.dart';
import '../enums/fundamental_reasons.dart';
import '../enums/index_types.dart';
import '../enums/market_segments.dart';
import '../enums/option_types.dart';
import '../enums/order_types.dart';
import '../enums/psychology_factors.dart';
import '../enums/series_types.dart';
import '../enums/technical_reasons.dart';
import '../enums/trade_directions.dart';
import '../enums/trade_statuses.dart';

part 'trade_controller_entities.freezed.dart';

/// Domain entity for derivative information
@freezed
abstract class DerivativeInfo with _$DerivativeInfo {
  const factory DerivativeInfo({
    DerivativeTypes? derivativeType,
    double? strikePrice,
    DateTime? expiryDate,
    OptionTypes? optionType,
    String? underlyingSymbol,
  }) = _DerivativeInfo;

  factory DerivativeInfo.empty() => const DerivativeInfo();
}

/// Domain entity for instrument information
@freezed
abstract class InstrumentInfo with _$InstrumentInfo {
  const factory InstrumentInfo({
    String? symbol,
    String? isin,
    String? rawSymbol,
    ExchangeTypes? exchange,
    MarketSegments? segment,
    SeriesTypes? series,
    IndexTypes? indexType,
    DerivativeInfo? derivativeInfo,
    String? description,
    String? currency,
    String? lotSize,
  }) = _InstrumentInfo;

  factory InstrumentInfo.empty() => const InstrumentInfo();
}

/// Domain entity for entry/exit information
@freezed
abstract class EntryExitInfo with _$EntryExitInfo {
  const factory EntryExitInfo({
    DateTime? timestamp,
    double? price,
    int? quantity,
    double? totalValue,
    double? fees,
    String? reason,
  }) = _EntryExitInfo;

  factory EntryExitInfo.empty() => const EntryExitInfo();
}

/// Domain entity for trade metrics
@freezed
abstract class TradeMetrics with _$TradeMetrics {
  const factory TradeMetrics({
    double? profitLoss,
    double? profitLossPercentage,
    double? returnOnEquity,
    double? riskAmount,
    double? rewardAmount,
    double? riskRewardRatio,
    int? holdingTimeDays,
    int? holdingTimeHours,
    int? holdingTimeMinutes,
    double? maxAdverseExcursion,
    double? maxFavorableExcursion,
  }) = _TradeMetrics;

  factory TradeMetrics.empty() => const TradeMetrics();
}

/// Domain entity for file attachments
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    String? fileName,
    String? fileUrl,
    String? fileType,
    DateTime? uploadedAt,
    String? description,
  }) = _Attachment;

  factory Attachment.empty() => const Attachment();
}

/// Domain entity for trade psychology data
@freezed
abstract class TradePsychologyData with _$TradePsychologyData {
  const factory TradePsychologyData({
    List<EntryPsychologyFactors>? entryPsychologyFactors,
    List<ExitPsychologyFactors>? exitPsychologyFactors,
    List<BehaviorPatterns>? behaviorPatterns,
    Map<String, List<String>>? categorizedTags,
    String? psychologyNotes,
  }) = _TradePsychologyData;

  factory TradePsychologyData.empty() => const TradePsychologyData();
}

/// Domain entity for trade entry/exit reasoning
@freezed
abstract class TradeEntryExitReasoning with _$TradeEntryExitReasoning {
  const factory TradeEntryExitReasoning({
    List<TechnicalReasons>? technicalReasons,
    List<FundamentalReasons>? fundamentalReasons,
    String? primaryReason,
    String? reasoningSummary,
    int? confidenceLevel,
    List<String>? supportingIndicators,
    List<String>? conflictingIndicators,
    String? exitPrimaryReason,
    String? exitReasoningSummary,
    int? exitConfidenceLevel,
    List<String>? exitSupportingIndicators,
    List<String>? exitConflictingIndicators,
    int? exitQualityScore,
    String? strategy,
  }) = _TradeEntryExitReasoning;

  factory TradeEntryExitReasoning.empty() => const TradeEntryExitReasoning();
}

/// Domain entity for basic trade execution info
@freezed
abstract class BasicInfo with _$BasicInfo {
  const factory BasicInfo({
    String? tradeId,
    String? orderId,
    DateTime? tradeDate,
    DateTime? orderExecutionTime,
    BrokerTypes? brokerType,
    TradeDirections? tradeType,
  }) = _BasicInfo;

  factory BasicInfo.empty() => const BasicInfo();
}

/// Domain entity for execution details
@freezed
abstract class ExecutionInfo with _$ExecutionInfo {
  const factory ExecutionInfo({int? quantity, double? price, OrderTypes? orderType}) = _ExecutionInfo;

  factory ExecutionInfo.empty() => const ExecutionInfo();
}

/// Domain entity for F&O specific info
@freezed
abstract class FnOInfo with _$FnOInfo {
  const factory FnOInfo({DateTime? expiryDate, double? strikePrice, OptionTypes? optionType}) = _FnOInfo;

  factory FnOInfo.empty() => const FnOInfo();
}

/// Domain entity for trading charges
@freezed
abstract class Charges with _$Charges {
  const factory Charges({
    double? brokerage,
    double? stt,
    double? transactionCharges,
    double? stampDuty,
    double? sebiCharges,
    double? gst,
    double? totalTaxes,
  }) = _Charges;

  factory Charges.empty() => const Charges();
}

/// Domain entity for financial summary
@freezed
abstract class Financials with _$Financials {
  const factory Financials({double? turnover, double? netAmount}) = _Financials;

  factory Financials.empty() => const Financials();
}

/// Domain entity for trade model (execution based on broker trade book)
@freezed
abstract class TradeModel with _$TradeModel {
  const factory TradeModel({
    BasicInfo? basicInfo,
    InstrumentInfo? instrumentInfo,
    ExecutionInfo? executionInfo,
    FnOInfo? fnoInfo,
    Charges? charges,
    Financials? financials,
  }) = _TradeModel;

  factory TradeModel.empty() => const TradeModel();
}

/// Domain entity for complete trade details
@freezed
abstract class TradeDetails with _$TradeDetails {
  const factory TradeDetails({
    required String tradeId,
    required String portfolioId,
    required InstrumentInfo instrumentInfo,
    required TradeStatuses status,
    required TradeDirections tradePositionType,
    required EntryExitInfo entryInfo,
    String? symbol,
    String? strategy,
    EntryExitInfo? exitInfo,
    TradeMetrics? metrics,
    List<TradeModel>? tradeExecutions,
    String? notes,
    List<String>? tags,
    String? userId,
    List<Attachment>? attachments,
    TradePsychologyData? psychologyData,
    TradeEntryExitReasoning? entryReasoning,
    TradeEntryExitReasoning? exitReasoning,
  }) = _TradeDetails;

  factory TradeDetails.empty() => TradeDetails(
    tradeId: '',
    portfolioId: '',
    instrumentInfo: InstrumentInfo.empty(),
    status: TradeStatuses.open,
    tradePositionType: TradeDirections.long,
    entryInfo: EntryExitInfo.empty(),
  );
}

/// Domain entity for filter summary
@freezed
abstract class FilterSummary with _$FilterSummary {
  const factory FilterSummary({
    List<String>? portfolioIds,
    List<String>? symbols,
    List<String>? statuses,
    String? dateRange,
    List<String>? strategies,
    String? profitLossRange,
    String? holdingTimeRange,
  }) = _FilterSummary;

  factory FilterSummary.empty() => const FilterSummary();
}

/// Domain entity for filter trade details response
@freezed
abstract class FilterTradeDetailsResponse with _$FilterTradeDetailsResponse {
  const factory FilterTradeDetailsResponse({
    List<TradeDetails>? trades,
    int? totalCount,
    String? appliedFilterName,
    FilterSummary? filterSummary,
    int? page,
    int? size,
    int? totalPages,
    bool? isFirst,
    bool? isLast,
  }) = _FilterTradeDetailsResponse;

  factory FilterTradeDetailsResponse.empty() => const FilterTradeDetailsResponse();
}

/// Domain entity for paginated trade response
@freezed
abstract class PaginatedTradeResponse with _$PaginatedTradeResponse {
  const factory PaginatedTradeResponse({
    List<TradeDetails>? content,
    int? totalElements,
    int? totalPages,
    int? size,
    int? number,
  }) = _PaginatedTradeResponse;

  factory PaginatedTradeResponse.empty() => const PaginatedTradeResponse();
}

/// Domain entity for error response
@freezed
abstract class ErrorResponse with _$ErrorResponse {
  const factory ErrorResponse({
    DateTime? timestamp,
    int? status,
    String? error,
    String? message,
    String? path,
    List<String>? details,
  }) = _ErrorResponse;

  factory ErrorResponse.empty() => const ErrorResponse();
}
