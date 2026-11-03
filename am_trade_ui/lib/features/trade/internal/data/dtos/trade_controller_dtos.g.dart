// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_controller_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DerivativeInfoDto _$DerivativeInfoDtoFromJson(Map<String, dynamic> json) =>
    DerivativeInfoDto(
      derivativeType:
          $enumDecodeNullable(_$DerivativeTypesEnumMap, json['derivativeType']),
      futureType: json['futureType'] as String?,
      strikePrice: (json['strikePrice'] as num?)?.toDouble(),
      expiryDate: json['expiryDate'] as String?,
      optionType:
          const OptionTypesConverter().fromJson(json['optionType'] as String?),
      underlyingSymbol: json['underlyingSymbol'] as String?,
      isCashSettled: json['isCashSettled'] as bool?,
    );

Map<String, dynamic> _$DerivativeInfoDtoToJson(DerivativeInfoDto instance) =>
    <String, dynamic>{
      'derivativeType': _$DerivativeTypesEnumMap[instance.derivativeType],
      'futureType': instance.futureType,
      'strikePrice': instance.strikePrice,
      'expiryDate': instance.expiryDate,
      'optionType': const OptionTypesConverter().toJson(instance.optionType),
      'underlyingSymbol': instance.underlyingSymbol,
      'isCashSettled': instance.isCashSettled,
    };

const _$DerivativeTypesEnumMap = {
  DerivativeTypes.futures: 'FUTURES',
  DerivativeTypes.options: 'OPTIONS',
};

InstrumentInfoDto _$InstrumentInfoDtoFromJson(Map<String, dynamic> json) =>
    InstrumentInfoDto(
      symbol: json['symbol'] as String?,
      isin: json['isin'] as String?,
      rawSymbol: json['rawSymbol'] as String?,
      baseSymbol: json['baseSymbol'] as String?,
      exchange:
          const ExchangeTypesConverter().fromJson(json['exchange'] as String?),
      segment:
          const MarketSegmentsConverter().fromJson(json['segment'] as String?),
      series: const SeriesTypesConverter().fromJson(json['series'] as String?),
      indexType: $enumDecodeNullable(_$IndexTypesEnumMap, json['indexType']),
      derivativeInfo: json['derivativeInfo'] == null
          ? null
          : DerivativeInfoDto.fromJson(
              json['derivativeInfo'] as Map<String, dynamic>),
      description: json['description'] as String?,
      formattedDescription: json['formattedDescription'] as String?,
      currency: json['currency'] as String?,
      lotSize: json['lotSize'] as String?,
      derivative: json['derivative'] as bool?,
      index: json['index'] as bool?,
    );

Map<String, dynamic> _$InstrumentInfoDtoToJson(InstrumentInfoDto instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'isin': instance.isin,
      'rawSymbol': instance.rawSymbol,
      'baseSymbol': instance.baseSymbol,
      'exchange': const ExchangeTypesConverter().toJson(instance.exchange),
      'segment': const MarketSegmentsConverter().toJson(instance.segment),
      'series': const SeriesTypesConverter().toJson(instance.series),
      'indexType': _$IndexTypesEnumMap[instance.indexType],
      'derivativeInfo': instance.derivativeInfo?.toJson(),
      'description': instance.description,
      'formattedDescription': instance.formattedDescription,
      'currency': instance.currency,
      'lotSize': instance.lotSize,
      'derivative': instance.derivative,
      'index': instance.index,
    };

const _$IndexTypesEnumMap = {
  IndexTypes.nifty: 'NIFTY',
  IndexTypes.banknifty: 'BANKNIFTY',
  IndexTypes.finnifty: 'FINNIFTY',
  IndexTypes.midcpnifty: 'MIDCPNIFTY',
};

EntryExitInfoDto _$EntryExitInfoDtoFromJson(Map<String, dynamic> json) =>
    EntryExitInfoDto(
      timestamp: json['timestamp'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt(),
      totalValue: (json['totalValue'] as num?)?.toDouble(),
      fees: (json['fees'] as num?)?.toDouble(),
      reason: json['reason'] as String?,
    );

Map<String, dynamic> _$EntryExitInfoDtoToJson(EntryExitInfoDto instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'price': instance.price,
      'quantity': instance.quantity,
      'totalValue': instance.totalValue,
      'fees': instance.fees,
      'reason': instance.reason,
    };

TradeMetricsDto _$TradeMetricsDtoFromJson(Map<String, dynamic> json) =>
    TradeMetricsDto(
      profitLoss: (json['profitLoss'] as num?)?.toDouble(),
      profitLossPercentage: (json['profitLossPercentage'] as num?)?.toDouble(),
      todayProfitLoss: (json['todayProfitLoss'] as num?)?.toDouble(),
      todayProfitLossPercentage:
          (json['todayProfitLossPercentage'] as num?)?.toDouble(),
      unrealizedBasis: json['unrealizedBasis'] as String?,
      returnOnEquity: (json['returnOnEquity'] as num?)?.toDouble(),
      riskAmount: (json['riskAmount'] as num?)?.toDouble(),
      rewardAmount: (json['rewardAmount'] as num?)?.toDouble(),
      riskRewardRatio: (json['riskRewardRatio'] as num?)?.toDouble(),
      holdingTimeDays: (json['holdingTimeDays'] as num?)?.toInt(),
      holdingTimeHours: (json['holdingTimeHours'] as num?)?.toInt(),
      holdingTimeMinutes: (json['holdingTimeMinutes'] as num?)?.toInt(),
      maxAdverseExcursion: (json['maxAdverseExcursion'] as num?)?.toDouble(),
      maxFavorableExcursion:
          (json['maxFavorableExcursion'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$TradeMetricsDtoToJson(TradeMetricsDto instance) =>
    <String, dynamic>{
      'profitLoss': instance.profitLoss,
      'profitLossPercentage': instance.profitLossPercentage,
      'todayProfitLoss': instance.todayProfitLoss,
      'todayProfitLossPercentage': instance.todayProfitLossPercentage,
      'unrealizedBasis': instance.unrealizedBasis,
      'returnOnEquity': instance.returnOnEquity,
      'riskAmount': instance.riskAmount,
      'rewardAmount': instance.rewardAmount,
      'riskRewardRatio': instance.riskRewardRatio,
      'holdingTimeDays': instance.holdingTimeDays,
      'holdingTimeHours': instance.holdingTimeHours,
      'holdingTimeMinutes': instance.holdingTimeMinutes,
      'maxAdverseExcursion': instance.maxAdverseExcursion,
      'maxFavorableExcursion': instance.maxFavorableExcursion,
    };

AttachmentDto _$AttachmentDtoFromJson(Map<String, dynamic> json) =>
    AttachmentDto(
      fileName: json['fileName'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileType: json['fileType'] as String?,
      uploadedAt: json['uploadedAt'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$AttachmentDtoToJson(AttachmentDto instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'fileUrl': instance.fileUrl,
      'fileType': instance.fileType,
      'uploadedAt': instance.uploadedAt,
      'description': instance.description,
    };

TradePsychologyDataDto _$TradePsychologyDataDtoFromJson(
        Map<String, dynamic> json) =>
    TradePsychologyDataDto(
      entryPsychologyFactors: const EntryPsychologyFactorsListConverter()
          .fromJson(json['entryPsychologyFactors'] as List?),
      exitPsychologyFactors: const ExitPsychologyFactorsListConverter()
          .fromJson(json['exitPsychologyFactors'] as List?),
      behaviorPatterns: const BehaviorPatternsListConverter()
          .fromJson(json['behaviorPatterns'] as List?),
      categorizedTags: (json['categorizedTags'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      psychologyNotes: json['psychologyNotes'] as String?,
    );

Map<String, dynamic> _$TradePsychologyDataDtoToJson(
        TradePsychologyDataDto instance) =>
    <String, dynamic>{
      'entryPsychologyFactors': const EntryPsychologyFactorsListConverter()
          .toJson(instance.entryPsychologyFactors),
      'exitPsychologyFactors': const ExitPsychologyFactorsListConverter()
          .toJson(instance.exitPsychologyFactors),
      'behaviorPatterns': const BehaviorPatternsListConverter()
          .toJson(instance.behaviorPatterns),
      'categorizedTags': instance.categorizedTags,
      'psychologyNotes': instance.psychologyNotes,
    };

TradeEntryExitReasoningDto _$TradeEntryExitReasoningDtoFromJson(
        Map<String, dynamic> json) =>
    TradeEntryExitReasoningDto(
      technicalReasons: const TechnicalReasonsListConverter()
          .fromJson(json['technicalReasons'] as List?),
      fundamentalReasons: const FundamentalReasonsListConverter()
          .fromJson(json['fundamentalReasons'] as List?),
      primaryReason: json['primaryReason'] as String?,
      reasoningSummary: json['reasoningSummary'] as String?,
      confidenceLevel: (json['confidenceLevel'] as num?)?.toInt(),
      supportingIndicators: (json['supportingIndicators'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      conflictingIndicators: (json['conflictingIndicators'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      exitPrimaryReason: json['exitPrimaryReason'] as String?,
      exitReasoningSummary: json['exitReasoningSummary'] as String?,
      exitConfidenceLevel: (json['exitConfidenceLevel'] as num?)?.toInt(),
      exitSupportingIndicators:
          (json['exitSupportingIndicators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      exitConflictingIndicators:
          (json['exitConflictingIndicators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
      exitQualityScore: (json['exitQualityScore'] as num?)?.toInt(),
      streategy: json['streategy'] as String?,
    );

Map<String, dynamic> _$TradeEntryExitReasoningDtoToJson(
        TradeEntryExitReasoningDto instance) =>
    <String, dynamic>{
      'technicalReasons': const TechnicalReasonsListConverter()
          .toJson(instance.technicalReasons),
      'fundamentalReasons': const FundamentalReasonsListConverter()
          .toJson(instance.fundamentalReasons),
      'primaryReason': instance.primaryReason,
      'reasoningSummary': instance.reasoningSummary,
      'confidenceLevel': instance.confidenceLevel,
      'supportingIndicators': instance.supportingIndicators,
      'conflictingIndicators': instance.conflictingIndicators,
      'exitPrimaryReason': instance.exitPrimaryReason,
      'exitReasoningSummary': instance.exitReasoningSummary,
      'exitConfidenceLevel': instance.exitConfidenceLevel,
      'exitSupportingIndicators': instance.exitSupportingIndicators,
      'exitConflictingIndicators': instance.exitConflictingIndicators,
      'exitQualityScore': instance.exitQualityScore,
      'streategy': instance.streategy,
    };

BasicInfoDto _$BasicInfoDtoFromJson(Map<String, dynamic> json) => BasicInfoDto(
      tradeId: json['tradeId'] as String?,
      orderId: json['orderId'] as String?,
      tradeDate: json['tradeDate'] as String?,
      orderExecutionTime: json['orderExecutionTime'] as String?,
      brokerType:
          const BrokerTypesConverter().fromJson(json['brokerType'] as String?),
      tradeType: _$JsonConverterFromJson<String, TradeDirections>(
          json['tradeType'], const TradeDirectionsConverter().fromJson),
    );

Map<String, dynamic> _$BasicInfoDtoToJson(BasicInfoDto instance) =>
    <String, dynamic>{
      'tradeId': instance.tradeId,
      'orderId': instance.orderId,
      'tradeDate': instance.tradeDate,
      'orderExecutionTime': instance.orderExecutionTime,
      'brokerType': const BrokerTypesConverter().toJson(instance.brokerType),
      'tradeType': _$JsonConverterToJson<String, TradeDirections>(
          instance.tradeType, const TradeDirectionsConverter().toJson),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

ExecutionInfoDto _$ExecutionInfoDtoFromJson(Map<String, dynamic> json) =>
    ExecutionInfoDto(
      quantity: (json['quantity'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toDouble(),
      orderType:
          const OrderTypesConverter().fromJson(json['orderType'] as String?),
    );

Map<String, dynamic> _$ExecutionInfoDtoToJson(ExecutionInfoDto instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'price': instance.price,
      'orderType': const OrderTypesConverter().toJson(instance.orderType),
    };

FnOInfoDto _$FnOInfoDtoFromJson(Map<String, dynamic> json) => FnOInfoDto(
      instrumentType: json['instrumentType'] as String?,
      expiryDate: json['expiryDate'] as String?,
      strikePrice: (json['strikePrice'] as num?)?.toDouble(),
      optionType:
          const OptionTypesConverter().fromJson(json['optionType'] as String?),
      lotSize: json['lotSize'] as String?,
      premiumValue: (json['premiumValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FnOInfoDtoToJson(FnOInfoDto instance) =>
    <String, dynamic>{
      'instrumentType': instance.instrumentType,
      'expiryDate': instance.expiryDate,
      'strikePrice': instance.strikePrice,
      'optionType': const OptionTypesConverter().toJson(instance.optionType),
      'lotSize': instance.lotSize,
      'premiumValue': instance.premiumValue,
    };

ChargesDto _$ChargesDtoFromJson(Map<String, dynamic> json) => ChargesDto(
      brokerage: (json['brokerage'] as num?)?.toDouble(),
      stt: (json['stt'] as num?)?.toDouble(),
      transactionCharges: (json['transactionCharges'] as num?)?.toDouble(),
      stampDuty: (json['stampDuty'] as num?)?.toDouble(),
      sebiCharges: (json['sebiCharges'] as num?)?.toDouble(),
      gst: (json['gst'] as num?)?.toDouble(),
      totalTaxes: (json['totalTaxes'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ChargesDtoToJson(ChargesDto instance) =>
    <String, dynamic>{
      'brokerage': instance.brokerage,
      'stt': instance.stt,
      'transactionCharges': instance.transactionCharges,
      'stampDuty': instance.stampDuty,
      'sebiCharges': instance.sebiCharges,
      'gst': instance.gst,
      'totalTaxes': instance.totalTaxes,
    };

FinancialsDto _$FinancialsDtoFromJson(Map<String, dynamic> json) =>
    FinancialsDto(
      turnover: (json['turnover'] as num?)?.toDouble(),
      netAmount: (json['netAmount'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FinancialsDtoToJson(FinancialsDto instance) =>
    <String, dynamic>{
      'turnover': instance.turnover,
      'netAmount': instance.netAmount,
    };

TradeModelDto _$TradeModelDtoFromJson(Map<String, dynamic> json) =>
    TradeModelDto(
      basicInfo: json['basicInfo'] == null
          ? null
          : BasicInfoDto.fromJson(json['basicInfo'] as Map<String, dynamic>),
      instrumentInfo: json['instrumentInfo'] == null
          ? null
          : InstrumentInfoDto.fromJson(
              json['instrumentInfo'] as Map<String, dynamic>),
      executionInfo: json['executionInfo'] == null
          ? null
          : ExecutionInfoDto.fromJson(
              json['executionInfo'] as Map<String, dynamic>),
      fnoInfo: json['fnoInfo'] == null
          ? null
          : FnOInfoDto.fromJson(json['fnoInfo'] as Map<String, dynamic>),
      charges: json['charges'] == null
          ? null
          : ChargesDto.fromJson(json['charges'] as Map<String, dynamic>),
      financials: json['financials'] == null
          ? null
          : FinancialsDto.fromJson(json['financials'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TradeModelDtoToJson(TradeModelDto instance) =>
    <String, dynamic>{
      'basicInfo': instance.basicInfo?.toJson(),
      'instrumentInfo': instance.instrumentInfo?.toJson(),
      'executionInfo': instance.executionInfo?.toJson(),
      'fnoInfo': instance.fnoInfo?.toJson(),
      'charges': instance.charges?.toJson(),
      'financials': instance.financials?.toJson(),
    };

TradeDetailsDto _$TradeDetailsDtoFromJson(Map<String, dynamic> json) =>
    TradeDetailsDto(
      tradeId: json['tradeId'] as String,
      portfolioId: json['portfolioId'] as String,
      instrumentInfo: InstrumentInfoDto.fromJson(
          json['instrumentInfo'] as Map<String, dynamic>),
      status: const TradeStatusesConverter().fromJson(json['status'] as String),
      tradePositionType: const TradeDirectionsConverter()
          .fromJson(json['tradePositionType'] as String),
      entryInfo:
          EntryExitInfoDto.fromJson(json['entryInfo'] as Map<String, dynamic>),
      symbol: json['symbol'] as String?,
      strategy: json['strategy'] as String?,
      exitInfo: json['exitInfo'] == null
          ? null
          : EntryExitInfoDto.fromJson(json['exitInfo'] as Map<String, dynamic>),
      currentPrice: (json['currentPrice'] as num?)?.toDouble(),
      metrics: json['metrics'] == null
          ? null
          : TradeMetricsDto.fromJson(json['metrics'] as Map<String, dynamic>),
      tradeExecutions: (json['tradeExecutions'] as List<dynamic>?)
          ?.map((e) => TradeModelDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      userId: json['userId'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => AttachmentDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      psychologyData: json['psychologyData'] == null
          ? null
          : TradePsychologyDataDto.fromJson(
              json['psychologyData'] as Map<String, dynamic>),
      entryReasoning: json['entryReasoning'] == null
          ? null
          : TradeEntryExitReasoningDto.fromJson(
              json['entryReasoning'] as Map<String, dynamic>),
      exitReasoning: json['exitReasoning'] == null
          ? null
          : TradeEntryExitReasoningDto.fromJson(
              json['exitReasoning'] as Map<String, dynamic>),
      tradeDate: json['tradeDate'] as String?,
      tradeEndDate: json['tradeEndDate'] as String?,
    );

Map<String, dynamic> _$TradeDetailsDtoToJson(TradeDetailsDto instance) =>
    <String, dynamic>{
      'tradeId': instance.tradeId,
      'portfolioId': instance.portfolioId,
      'instrumentInfo': instance.instrumentInfo.toJson(),
      'symbol': instance.symbol,
      'strategy': instance.strategy,
      'status': const TradeStatusesConverter().toJson(instance.status),
      'tradePositionType':
          const TradeDirectionsConverter().toJson(instance.tradePositionType),
      'entryInfo': instance.entryInfo.toJson(),
      'exitInfo': instance.exitInfo?.toJson(),
      'currentPrice': instance.currentPrice,
      'metrics': instance.metrics?.toJson(),
      'tradeExecutions':
          instance.tradeExecutions?.map((e) => e.toJson()).toList(),
      'notes': instance.notes,
      'tags': instance.tags,
      'userId': instance.userId,
      'attachments': instance.attachments?.map((e) => e.toJson()).toList(),
      'psychologyData': instance.psychologyData?.toJson(),
      'entryReasoning': instance.entryReasoning?.toJson(),
      'exitReasoning': instance.exitReasoning?.toJson(),
      'tradeDate': instance.tradeDate,
      'tradeEndDate': instance.tradeEndDate,
    };

FilterSummaryDto _$FilterSummaryDtoFromJson(Map<String, dynamic> json) =>
    FilterSummaryDto(
      portfolioIds: (json['portfolioIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      symbols:
          (json['symbols'] as List<dynamic>?)?.map((e) => e as String).toList(),
      statuses: (json['statuses'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      dateRange: json['dateRange'] as String?,
      strategies: (json['strategies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      profitLossRange: json['profitLossRange'] as String?,
      holdingTimeRange: json['holdingTimeRange'] as String?,
    );

Map<String, dynamic> _$FilterSummaryDtoToJson(FilterSummaryDto instance) =>
    <String, dynamic>{
      'portfolioIds': instance.portfolioIds,
      'symbols': instance.symbols,
      'statuses': instance.statuses,
      'dateRange': instance.dateRange,
      'strategies': instance.strategies,
      'profitLossRange': instance.profitLossRange,
      'holdingTimeRange': instance.holdingTimeRange,
    };

FilterTradeDetailsRequestDto _$FilterTradeDetailsRequestDtoFromJson(
        Map<String, dynamic> json) =>
    FilterTradeDetailsRequestDto(
      favoriteFilterId: json['favoriteFilterId'] as String?,
      metricsConfig: json['metricsConfig'] == null
          ? null
          : MetricsFilterConfigDto.fromJson(
              json['metricsConfig'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FilterTradeDetailsRequestDtoToJson(
        FilterTradeDetailsRequestDto instance) =>
    <String, dynamic>{
      'favoriteFilterId': instance.favoriteFilterId,
      'metricsConfig': instance.metricsConfig?.toJson(),
    };

FilterTradeDetailsResponseDto _$FilterTradeDetailsResponseDtoFromJson(
        Map<String, dynamic> json) =>
    FilterTradeDetailsResponseDto(
      trades: (json['trades'] as List<dynamic>?)
          ?.map((e) => TradeDetailsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt(),
      appliedFilterName: json['appliedFilterName'] as String?,
      filterSummary: json['filterSummary'] == null
          ? null
          : FilterSummaryDto.fromJson(
              json['filterSummary'] as Map<String, dynamic>),
      page: (json['page'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      isFirst: json['isFirst'] as bool?,
      isLast: json['isLast'] as bool?,
    );

Map<String, dynamic> _$FilterTradeDetailsResponseDtoToJson(
        FilterTradeDetailsResponseDto instance) =>
    <String, dynamic>{
      'trades': instance.trades?.map((e) => e.toJson()).toList(),
      'totalCount': instance.totalCount,
      'appliedFilterName': instance.appliedFilterName,
      'filterSummary': instance.filterSummary?.toJson(),
      'page': instance.page,
      'size': instance.size,
      'totalPages': instance.totalPages,
      'isFirst': instance.isFirst,
      'isLast': instance.isLast,
    };

PaginatedTradeResponseDto _$PaginatedTradeResponseDtoFromJson(
        Map<String, dynamic> json) =>
    PaginatedTradeResponseDto(
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => TradeDetailsDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalElements: (json['totalElements'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      size: (json['size'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PaginatedTradeResponseDtoToJson(
        PaginatedTradeResponseDto instance) =>
    <String, dynamic>{
      'content': instance.content?.map((e) => e.toJson()).toList(),
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
      'size': instance.size,
      'number': instance.number,
    };

ErrorResponseDto _$ErrorResponseDtoFromJson(Map<String, dynamic> json) =>
    ErrorResponseDto(
      timestamp: json['timestamp'] as String?,
      status: (json['status'] as num?)?.toInt(),
      error: json['error'] as String?,
      message: json['message'] as String?,
      path: json['path'] as String?,
      details:
          (json['details'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ErrorResponseDtoToJson(ErrorResponseDto instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'status': instance.status,
      'error': instance.error,
      'message': instance.message,
      'path': instance.path,
      'details': instance.details,
    };
