import 'package:json_annotation/json_annotation.dart';

import '../../domain/enums/broker_types.dart';
import '../../domain/enums/derivative_types.dart';
import '../../domain/enums/exchange_types.dart';
import '../../domain/enums/fundamental_reasons.dart';
import '../../domain/enums/index_types.dart';
import '../../domain/enums/market_segments.dart';
import '../../domain/enums/option_types.dart';
import '../../domain/enums/order_types.dart';
import '../../domain/enums/psychology_factors.dart';
import '../../domain/enums/series_types.dart';
import '../../domain/enums/technical_reasons.dart';
import '../../domain/enums/trade_directions.dart';
import '../../domain/enums/trade_statuses.dart';
import 'metrics_filter_config_dto.dart';

part 'trade_controller_dtos.g.dart';

/// DTO for derivative information
@JsonSerializable(explicitToJson: true)
class DerivativeInfoDto {
  const DerivativeInfoDto({
    this.derivativeType,
    this.futureType,
    this.strikePrice,
    this.expiryDate,
    this.optionType,
    this.underlyingSymbol,
    this.isCashSettled,
  });

  factory DerivativeInfoDto.fromJson(Map<String, dynamic> json) => _$DerivativeInfoDtoFromJson(json);

  final DerivativeTypes? derivativeType;
  final String? futureType; // API sends this as string like "MONTHLY"
  final double? strikePrice;
  final String? expiryDate; // format: "yyyy-MM-dd"
  @OptionTypesConverter()
  final OptionTypes? optionType;
  final String? underlyingSymbol;
  final bool? isCashSettled;

  Map<String, dynamic> toJson() => _$DerivativeInfoDtoToJson(this);
}

/// DTO for instrument information
@JsonSerializable(explicitToJson: true)
class InstrumentInfoDto {
  const InstrumentInfoDto({
    this.symbol,
    this.isin,
    this.rawSymbol,
    this.baseSymbol,
    this.exchange,
    this.segment,
    this.series,
    this.indexType,
    this.derivativeInfo,
    this.description,
    this.formattedDescription,
    this.currency,
    this.lotSize,
    this.derivative,
    this.index,
  });

  factory InstrumentInfoDto.fromJson(Map<String, dynamic> json) => _$InstrumentInfoDtoFromJson(json);

  final String? symbol;
  final String? isin;
  final String? rawSymbol;
  final String? baseSymbol;
  final ExchangeTypes? exchange;
  @MarketSegmentsConverter()
  final MarketSegments? segment;
  @SeriesTypesConverter()
  final SeriesTypes? series;
  final IndexTypes? indexType;
  final DerivativeInfoDto? derivativeInfo;
  final String? description;
  final String? formattedDescription;
  final String? currency;
  final String? lotSize;
  final bool? derivative;
  final bool? index;

  Map<String, dynamic> toJson() => _$InstrumentInfoDtoToJson(this);
}

/// DTO for entry/exit information
@JsonSerializable(explicitToJson: true)
class EntryExitInfoDto {
  const EntryExitInfoDto({this.timestamp, this.price, this.quantity, this.totalValue, this.fees, this.reason});

  factory EntryExitInfoDto.fromJson(Map<String, dynamic> json) => _$EntryExitInfoDtoFromJson(json);

  final String? timestamp; // format: "yyyy-MM-dd'T'HH:mm:ss'Z'"
  final double? price;
  final int? quantity;
  final double? totalValue;
  final double? fees;
  final String? reason;

  Map<String, dynamic> toJson() => _$EntryExitInfoDtoToJson(this);
}

/// DTO for trade metrics
@JsonSerializable(explicitToJson: true)
class TradeMetricsDto {
  const TradeMetricsDto({
    this.profitLoss,
    this.profitLossPercentage,
    this.returnOnEquity,
    this.riskAmount,
    this.rewardAmount,
    this.riskRewardRatio,
    this.holdingTimeDays,
    this.holdingTimeHours,
    this.holdingTimeMinutes,
    this.maxAdverseExcursion,
    this.maxFavorableExcursion,
  });

  factory TradeMetricsDto.fromJson(Map<String, dynamic> json) => _$TradeMetricsDtoFromJson(json);

  final double? profitLoss;
  final double? profitLossPercentage;
  final double? returnOnEquity;
  final double? riskAmount;
  final double? rewardAmount;
  final double? riskRewardRatio;
  final int? holdingTimeDays;
  final int? holdingTimeHours;
  final int? holdingTimeMinutes;
  final double? maxAdverseExcursion;
  final double? maxFavorableExcursion;

  Map<String, dynamic> toJson() => _$TradeMetricsDtoToJson(this);
}

/// DTO for file attachments
@JsonSerializable()
class AttachmentDto {
  const AttachmentDto({this.fileName, this.fileUrl, this.fileType, this.uploadedAt, this.description});

  factory AttachmentDto.fromJson(Map<String, dynamic> json) => _$AttachmentDtoFromJson(json);

  final String? fileName;
  final String? fileUrl;
  final String? fileType;
  final String? uploadedAt; // format: "yyyy-MM-dd'T'HH:mm:ss'Z'"
  final String? description;

  Map<String, dynamic> toJson() => _$AttachmentDtoToJson(this);
}

/// DTO for trade psychology data
@JsonSerializable()
class TradePsychologyDataDto {
  const TradePsychologyDataDto({
    this.entryPsychologyFactors,
    this.exitPsychologyFactors,
    this.behaviorPatterns,
    this.categorizedTags,
    this.psychologyNotes,
  });

  factory TradePsychologyDataDto.fromJson(Map<String, dynamic> json) => _$TradePsychologyDataDtoFromJson(json);

  @EntryPsychologyFactorsListConverter()
  final List<EntryPsychologyFactors>? entryPsychologyFactors;
  @ExitPsychologyFactorsListConverter()
  final List<ExitPsychologyFactors>? exitPsychologyFactors;
  @BehaviorPatternsListConverter()
  final List<BehaviorPatterns>? behaviorPatterns;
  final Map<String, List<String>>? categorizedTags;
  final String? psychologyNotes;

  Map<String, dynamic> toJson() => _$TradePsychologyDataDtoToJson(this);
}

/// DTO for trade entry/exit reasoning
@JsonSerializable()
class TradeEntryExitReasoningDto {
  const TradeEntryExitReasoningDto({
    this.technicalReasons,
    this.fundamentalReasons,
    this.primaryReason,
    this.reasoningSummary,
    this.confidenceLevel,
    this.supportingIndicators,
    this.conflictingIndicators,
    this.exitPrimaryReason,
    this.exitReasoningSummary,
    this.exitConfidenceLevel,
    this.exitSupportingIndicators,
    this.exitConflictingIndicators,
    this.exitQualityScore,
    this.streategy, // Note: This is misspelled in the API schema
  });

  factory TradeEntryExitReasoningDto.fromJson(Map<String, dynamic> json) => _$TradeEntryExitReasoningDtoFromJson(json);

  @TechnicalReasonsListConverter()
  final List<TechnicalReasons>? technicalReasons;
  @FundamentalReasonsListConverter()
  final List<FundamentalReasons>? fundamentalReasons;
  final String? primaryReason;
  final String? reasoningSummary;
  final int? confidenceLevel;
  final List<String>? supportingIndicators;
  final List<String>? conflictingIndicators;
  final String? exitPrimaryReason;
  final String? exitReasoningSummary;
  final int? exitConfidenceLevel;
  final List<String>? exitSupportingIndicators;
  final List<String>? exitConflictingIndicators;
  final int? exitQualityScore;
  final String? streategy; // Keeping misspelling from API

  Map<String, dynamic> toJson() => _$TradeEntryExitReasoningDtoToJson(this);
}

/// DTO for basic trade execution info
@JsonSerializable()
class BasicInfoDto {
  const BasicInfoDto({
    this.tradeId,
    this.orderId,
    this.tradeDate,
    this.orderExecutionTime,
    this.brokerType,
    this.tradeType,
  });

  factory BasicInfoDto.fromJson(Map<String, dynamic> json) => _$BasicInfoDtoFromJson(json);

  final String? tradeId;
  final String? orderId;
  final String? tradeDate; // format: "yyyy-MM-dd"
  final String? orderExecutionTime; // format: "yyyy-MM-dd'T'HH:mm:ss'Z'"
  final BrokerTypes? brokerType;
  @TradeDirectionsConverter()
  final TradeDirections? tradeType;

  Map<String, dynamic> toJson() => _$BasicInfoDtoToJson(this);
}

/// DTO for execution details
@JsonSerializable()
class ExecutionInfoDto {
  const ExecutionInfoDto({this.quantity, this.price, this.orderType});

  factory ExecutionInfoDto.fromJson(Map<String, dynamic> json) => _$ExecutionInfoDtoFromJson(json);

  final int? quantity;
  final double? price;
  final OrderTypes? orderType;

  Map<String, dynamic> toJson() => _$ExecutionInfoDtoToJson(this);
}

/// DTO for F&O specific info
@JsonSerializable()
class FnOInfoDto {
  const FnOInfoDto({
    this.instrumentType,
    this.expiryDate,
    this.strikePrice,
    this.optionType,
    this.lotSize,
    this.premiumValue,
  });

  factory FnOInfoDto.fromJson(Map<String, dynamic> json) => _$FnOInfoDtoFromJson(json);

  final String? instrumentType;
  final String? expiryDate; // format: "yyyy-MM-dd"
  final double? strikePrice;
  @OptionTypesConverter()
  final OptionTypes? optionType;
  final String? lotSize;
  final double? premiumValue;

  Map<String, dynamic> toJson() => _$FnOInfoDtoToJson(this);
}

/// DTO for trading charges
@JsonSerializable()
class ChargesDto {
  const ChargesDto({
    this.brokerage,
    this.stt,
    this.transactionCharges,
    this.stampDuty,
    this.sebiCharges,
    this.gst,
    this.totalTaxes,
  });

  factory ChargesDto.fromJson(Map<String, dynamic> json) => _$ChargesDtoFromJson(json);

  final double? brokerage;
  final double? stt;
  final double? transactionCharges;
  final double? stampDuty;
  final double? sebiCharges;
  final double? gst;
  final double? totalTaxes;

  Map<String, dynamic> toJson() => _$ChargesDtoToJson(this);
}

/// DTO for financial summary
@JsonSerializable()
class FinancialsDto {
  const FinancialsDto({this.turnover, this.netAmount});

  factory FinancialsDto.fromJson(Map<String, dynamic> json) => _$FinancialsDtoFromJson(json);

  final double? turnover;
  final double? netAmount;

  Map<String, dynamic> toJson() => _$FinancialsDtoToJson(this);
}

/// DTO for trade model (execution based on broker trade book)
@JsonSerializable(explicitToJson: true)
class TradeModelDto {
  const TradeModelDto({
    this.basicInfo,
    this.instrumentInfo,
    this.executionInfo,
    this.fnoInfo,
    this.charges,
    this.financials,
  });

  factory TradeModelDto.fromJson(Map<String, dynamic> json) => _$TradeModelDtoFromJson(json);

  final BasicInfoDto? basicInfo;
  final InstrumentInfoDto? instrumentInfo;
  final ExecutionInfoDto? executionInfo;
  final FnOInfoDto? fnoInfo;
  final ChargesDto? charges;
  final FinancialsDto? financials;

  Map<String, dynamic> toJson() => _$TradeModelDtoToJson(this);
}

/// DTO for complete trade details
@JsonSerializable(explicitToJson: true)
class TradeDetailsDto {
  const TradeDetailsDto({
    required this.tradeId,
    required this.portfolioId,
    required this.instrumentInfo,
    required this.status,
    required this.tradePositionType,
    required this.entryInfo,
    this.symbol,
    this.strategy,
    this.exitInfo,
    this.metrics,
    this.tradeExecutions,
    this.notes,
    this.tags,
    this.userId,
    this.attachments,
    this.psychologyData,
    this.entryReasoning,
    this.exitReasoning,
    this.tradeDate,
    this.tradeEndDate,
  });

  factory TradeDetailsDto.fromJson(Map<String, dynamic> json) => _$TradeDetailsDtoFromJson(json);

  final String tradeId;
  final String portfolioId;
  final InstrumentInfoDto instrumentInfo;
  final String? symbol;
  final String? strategy;
  @TradeStatusesConverter()
  final TradeStatuses status;
  @TradeDirectionsConverter()
  final TradeDirections tradePositionType;
  final EntryExitInfoDto entryInfo;
  final EntryExitInfoDto? exitInfo;
  final TradeMetricsDto? metrics;
  final List<TradeModelDto>? tradeExecutions;
  final String? notes;
  final List<String>? tags;
  final String? userId;
  final List<AttachmentDto>? attachments;
  final TradePsychologyDataDto? psychologyData;
  final TradeEntryExitReasoningDto? entryReasoning;
  final TradeEntryExitReasoningDto? exitReasoning;
  final String? tradeDate; // format: "yyyy-MM-dd"
  final String? tradeEndDate; // format: "yyyy-MM-dd"

  Map<String, dynamic> toJson() => _$TradeDetailsDtoToJson(this);
}

/// DTO for filter summary
@JsonSerializable()
class FilterSummaryDto {
  const FilterSummaryDto({
    this.portfolioIds,
    this.symbols,
    this.statuses,
    this.dateRange,
    this.strategies,
    this.profitLossRange,
    this.holdingTimeRange,
  });

  factory FilterSummaryDto.fromJson(Map<String, dynamic> json) => _$FilterSummaryDtoFromJson(json);

  final List<String>? portfolioIds;
  final List<String>? symbols;
  final List<String>? statuses;
  final String? dateRange;
  final List<String>? strategies;
  final String? profitLossRange;
  final String? holdingTimeRange;

  Map<String, dynamic> toJson() => _$FilterSummaryDtoToJson(this);
}

/// DTO for filter trade details request
@JsonSerializable(explicitToJson: true)
class FilterTradeDetailsRequestDto {
  const FilterTradeDetailsRequestDto({required this.userId, this.favoriteFilterId, this.metricsConfig});

  factory FilterTradeDetailsRequestDto.fromJson(Map<String, dynamic> json) =>
      _$FilterTradeDetailsRequestDtoFromJson(json);

  final String userId;
  final String? favoriteFilterId;
  final MetricsFilterConfigDto? metricsConfig;

  Map<String, dynamic> toJson() => _$FilterTradeDetailsRequestDtoToJson(this);
}

/// DTO for filter trade details response
@JsonSerializable(explicitToJson: true)
class FilterTradeDetailsResponseDto {
  const FilterTradeDetailsResponseDto({
    this.trades,
    this.totalCount,
    this.appliedFilterName,
    this.filterSummary,
    this.page,
    this.size,
    this.totalPages,
    this.isFirst,
    this.isLast,
  });

  factory FilterTradeDetailsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$FilterTradeDetailsResponseDtoFromJson(json);

  final List<TradeDetailsDto>? trades;
  final int? totalCount;
  final String? appliedFilterName;
  final FilterSummaryDto? filterSummary;
  final int? page;
  final int? size;
  final int? totalPages;
  final bool? isFirst;
  final bool? isLast;

  Map<String, dynamic> toJson() => _$FilterTradeDetailsResponseDtoToJson(this);
}

/// DTO for paginated trade response (GET /v1/trades/filter)
@JsonSerializable(explicitToJson: true)
class PaginatedTradeResponseDto {
  const PaginatedTradeResponseDto({this.content, this.totalElements, this.totalPages, this.size, this.number});

  factory PaginatedTradeResponseDto.fromJson(Map<String, dynamic> json) => _$PaginatedTradeResponseDtoFromJson(json);

  final List<TradeDetailsDto>? content;
  final int? totalElements;
  final int? totalPages;
  final int? size;
  final int? number;

  Map<String, dynamic> toJson() => _$PaginatedTradeResponseDtoToJson(this);
}

/// DTO for error response
@JsonSerializable()
class ErrorResponseDto {
  const ErrorResponseDto({this.timestamp, this.status, this.error, this.message, this.path, this.details});

  factory ErrorResponseDto.fromJson(Map<String, dynamic> json) => _$ErrorResponseDtoFromJson(json);

  final String? timestamp;
  final int? status;
  final String? error;
  final String? message;
  final String? path;
  final List<String>? details;

  Map<String, dynamic> toJson() => _$ErrorResponseDtoToJson(this);
}
