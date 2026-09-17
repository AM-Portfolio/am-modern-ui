import 'package:json_annotation/json_annotation.dart';
import '../../../domain/entities/metrics/performance_metrics.dart';
import '../../../domain/entities/metrics/risk_metrics.dart';
import '../../../domain/entities/metrics/trade_distribution_metrics.dart';
import '../../../domain/entities/metrics/trade_timing_metrics.dart';
import '../../../domain/entities/metrics/trade_pattern_metrics.dart';
import '../../../domain/entities/metrics/strategy_performance_metrics.dart';
import '../../../domain/entities/metrics/trade_details.dart';
import '../../../domain/entities/metrics/trade_metrics_response.dart';
import '../../../domain/entities/metrics/metrics_filter_request.dart';
import '../../../domain/enums/metric_types.dart';

part 'metrics_dtos.g.dart';

/// Jackson may emit null map values for empty buckets, or BigDecimal as string.
/// These helpers must live in this library (not only in generated `.g.dart`) so
/// Docker `build_runner` cannot wipe null-safety on regenerate.
num? _asNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

Map<String, int>? _distIntMap(Object? raw) {
  if (raw is! Map) return null;
  final out = <String, int>{};
  for (final e in raw.entries) {
    final n = _asNum(e.value);
    if (n != null) out[e.key.toString()] = n.toInt();
  }
  return out;
}

Map<String, double>? _distDoubleMap(Object? raw) {
  if (raw is! Map) return null;
  final out = <String, double>{};
  for (final e in raw.entries) {
    final n = _asNum(e.value);
    if (n != null && n.isFinite) out[e.key.toString()] = n.toDouble();
  }
  return out;
}

int _asIntOrZero(Object? value) => _asNum(value)?.toInt() ?? 0;

@JsonSerializable()
class PerformanceMetricsDto {
  final double? totalProfitLoss;
  final double? totalProfitLossPercentage;
  final double? winRate;
  final double? profitFactor;
  final double? expectancy;
  final double? annualizedReturn;
  final double? yearToDateReturn;
  final double? averageWinningTrade;
  final double? averageLosingTrade;
  final double? largestWinningTrade;
  final double? largestLosingTrade;
  final double? winLossRatio;
  final double? maxDrawdown;
  final int? longestWinningStreak;
  final int? longestLosingStreak;
  final double? returnOnCapital;
  final double? tradesPerDay;
  final double? returnStandardDeviation;
  final double? profitConsistency;
  final int? currentStreak;
  final String? bestDayDate;
  final String? worstDayDate;
  final double? bestDayProfit;
  final double? worstDayLoss;
  final double? averageHoldingTimeMinutes;
  final int? winningTradesCount;
  final int? losingTradesCount;
  final int? eligibleTradesCount;

  PerformanceMetricsDto({
    this.totalProfitLoss,
    this.totalProfitLossPercentage,
    this.winRate,
    this.profitFactor,
    this.expectancy,
    this.annualizedReturn,
    this.yearToDateReturn,
    this.averageWinningTrade,
    this.averageLosingTrade,
    this.largestWinningTrade,
    this.largestLosingTrade,
    this.winLossRatio,
    this.maxDrawdown,
    this.longestWinningStreak,
    this.longestLosingStreak,
    this.returnOnCapital,
    this.tradesPerDay,
    this.returnStandardDeviation,
    this.profitConsistency,
    this.currentStreak,
    this.bestDayDate,
    this.worstDayDate,
    this.bestDayProfit,
    this.worstDayLoss,
    this.averageHoldingTimeMinutes,
    this.winningTradesCount,
    this.losingTradesCount,
    this.eligibleTradesCount,
  });

  factory PerformanceMetricsDto.fromJson(Map<String, dynamic> json) => _$PerformanceMetricsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PerformanceMetricsDtoToJson(this);

  PerformanceMetrics toEntity() => PerformanceMetrics(
    totalProfitLoss: totalProfitLoss,
    totalProfitLossPercentage: totalProfitLossPercentage,
    winRate: winRate ?? 0.0,
    profitFactor: profitFactor ?? 0.0,
    expectancy: expectancy ?? 0.0,
    annualizedReturn: annualizedReturn ?? 0.0,
    averageWinningTrade: averageWinningTrade ?? 0.0,
    averageLosingTrade: averageLosingTrade ?? 0.0,
    largestWinningTrade: largestWinningTrade ?? 0.0,
    largestLosingTrade: largestLosingTrade ?? 0.0,
    winLossRatio: winLossRatio ?? 0.0,
    maxDrawdown: maxDrawdown ?? 0.0,
    longestWinningStreak: longestWinningStreak ?? 0,
    longestLosingStreak: longestLosingStreak ?? 0,
    returnOnCapital: returnOnCapital ?? 0.0,
    tradesPerDay: tradesPerDay ?? 0.0,
    averageHoldingTimeMinutes: averageHoldingTimeMinutes,
    winningTradesCount: winningTradesCount,
    losingTradesCount: losingTradesCount,
    eligibleTradesCount: eligibleTradesCount,
  );
}

@JsonSerializable()
class RiskMetricsDto {
  final double? maxDrawdown;
  final double? sharpeRatio;
  final double? sortinoRatio;
  final double? calmarRatio;
  final double? valueAtRisk;
  final double? probabilityOfRuin;
  final double? averagePositionSize;
  final double? largestPositionSize;
  final int? consecutiveLossesToRuin;

  RiskMetricsDto({
    this.maxDrawdown,
    this.sharpeRatio,
    this.sortinoRatio,
    this.calmarRatio,
    this.valueAtRisk,
    this.probabilityOfRuin,
    this.averagePositionSize,
    this.largestPositionSize,
    this.consecutiveLossesToRuin,
  });

  factory RiskMetricsDto.fromJson(Map<String, dynamic> json) => _$RiskMetricsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$RiskMetricsDtoToJson(this);

  RiskMetrics toEntity() => RiskMetrics(
    maxDrawdown: maxDrawdown ?? 0.0,
    sharpeRatio: sharpeRatio ?? 0.0,
    sortinoRatio: sortinoRatio ?? 0.0,
    valueAtRisk: valueAtRisk ?? 0.0,
    probabilityOfRuin: probabilityOfRuin ?? 0.0,
  );
}

class TradingStyleHintDto {
  final String? style;
  final double? confidencePercent;
  final String? basis;
  final int? sampleSize;

  TradingStyleHintDto({
    this.style,
    this.confidencePercent,
    this.basis,
    this.sampleSize,
  });

  factory TradingStyleHintDto.fromJson(Map<String, dynamic> json) =>
      TradingStyleHintDto(
        style: json['style'] as String?,
        confidencePercent: (json['confidencePercent'] as num?)?.toDouble(),
        basis: json['basis'] as String?,
        sampleSize: (json['sampleSize'] as num?)?.toInt(),
      );

  Map<String, dynamic> toJson() => {
        'style': style,
        'confidencePercent': confidencePercent,
        'basis': basis,
        'sampleSize': sampleSize,
      };

  TradingStyleHint? toEntity() {
    if (style == null) return null;
    return TradingStyleHint(
      style: style!,
      confidencePercent: confidencePercent ?? 0,
      basis: basis ?? 'holding_duration',
      sampleSize: sampleSize ?? 0,
    );
  }
}

/// [createFactory: false] — hand-written fromJson so CI build_runner cannot
/// regenerate `(e as num).toDouble()` and crash on Jackson null map values.
@JsonSerializable(createFactory: false)
class TradeDistributionMetricsDto {
  final Map<String, int>? tradesByDay;
  final Map<String, int>? tradesByMonth;
  final Map<String, double>? profitByDay;
  final Map<String, double>? profitByMonth;
  final Map<String, double>? winRateByDay;
  final Map<String, double>? winRateByMonth;
  final Map<String, double>? avgPnlByDay;
  final Map<String, double>? avgPnlByMonth;
  final Map<String, double>? avgPnlPerActiveDayByDay;
  final Map<String, double>? avgPnlPerActiveDayByMonth;
  final Map<String, int>? eligibleTradesByDay;
  final Map<String, int>? eligibleTradesByMonth;
  final Map<String, int>? activeTradingDaysByDay;
  final Map<String, int>? activeTradingDaysByMonth;
  final Map<String, int>? tradesByHour;
  final Map<String, double>? profitByHour;
  final Map<String, double>? winRateByHour;
  final Map<String, double>? avgPnlByHour;
  final Map<String, double>? avgPnlPerActiveDayByHour;
  final Map<String, int>? eligibleTradesByHour;
  final Map<String, int>? activeTradingDaysByHour;
  final Map<String, int>? tradesBySession;
  final Map<String, double>? profitBySession;
  final Map<String, double>? winRateBySession;
  final Map<String, double>? avgPnlBySession;
  final Map<String, double>? avgPnlPerActiveDayBySession;
  final Map<String, int>? eligibleTradesBySession;
  final Map<String, int>? activeTradingDaysBySession;
  final Map<String, double>? avgHoldMinutesByDay;
  final Map<String, double>? avgHoldMinutesByHour;
  final Map<String, double>? avgHoldMinutesByMonth;
  final Map<String, double>? avgHoldMinutesBySession;
  final Map<String, double>? riskRewardByDay;
  final Map<String, double>? riskRewardByHour;
  final Map<String, double>? riskRewardByMonth;
  final Map<String, double>? riskRewardBySession;
  final Map<String, int>? tradeCountByAssetClass;
  final Map<String, double>? profitByAssetClass;
  final Map<String, double>? winRateByAssetClass;
  final Map<String, int>? tradeCountByStrategy;
  final Map<String, double>? profitByStrategy;
  final Map<String, double>? winRateByStrategy;
  final Map<String, int>? tradesByDuration;
  final Map<String, double>? profitByDuration;
  final Map<String, double>? winRateByDuration;
  final Map<String, int>? tradesByPositionSize;
  final Map<String, double>? profitByPositionSize;
  final Map<String, double>? winRateByPositionSize;
  final int? skippedMissingEntryCount;
  final int? openOrMissingPnlCount;
  final int? badTimestampCount;
  final String? timezoneNote;
  final TradingStyleHintDto? tradingStyleHint;
  final String? bestSessionKey;
  final double? bestSessionAvgPnl;
  final int? activeTradingDaysCount;
  final double? avgPnlPerActiveDay;

  TradeDistributionMetricsDto({
    this.tradesByDay,
    this.tradesByMonth,
    this.profitByDay,
    this.profitByMonth,
    this.winRateByDay,
    this.winRateByMonth,
    this.avgPnlByDay,
    this.avgPnlByMonth,
    this.avgPnlPerActiveDayByDay,
    this.avgPnlPerActiveDayByMonth,
    this.eligibleTradesByDay,
    this.eligibleTradesByMonth,
    this.activeTradingDaysByDay,
    this.activeTradingDaysByMonth,
    this.tradesByHour,
    this.profitByHour,
    this.winRateByHour,
    this.avgPnlByHour,
    this.avgPnlPerActiveDayByHour,
    this.eligibleTradesByHour,
    this.activeTradingDaysByHour,
    this.tradesBySession,
    this.profitBySession,
    this.winRateBySession,
    this.avgPnlBySession,
    this.avgPnlPerActiveDayBySession,
    this.eligibleTradesBySession,
    this.activeTradingDaysBySession,
    this.avgHoldMinutesByDay,
    this.avgHoldMinutesByHour,
    this.avgHoldMinutesByMonth,
    this.avgHoldMinutesBySession,
    this.riskRewardByDay,
    this.riskRewardByHour,
    this.riskRewardByMonth,
    this.riskRewardBySession,
    this.tradeCountByAssetClass,
    this.profitByAssetClass,
    this.winRateByAssetClass,
    this.tradeCountByStrategy,
    this.profitByStrategy,
    this.winRateByStrategy,
    this.tradesByDuration,
    this.profitByDuration,
    this.winRateByDuration,
    this.tradesByPositionSize,
    this.profitByPositionSize,
    this.winRateByPositionSize,
    this.skippedMissingEntryCount,
    this.openOrMissingPnlCount,
    this.badTimestampCount,
    this.timezoneNote,
    this.tradingStyleHint,
    this.bestSessionKey,
    this.bestSessionAvgPnl,
    this.activeTradingDaysCount,
    this.avgPnlPerActiveDay,
  });

  factory TradeDistributionMetricsDto.fromJson(Map<String, dynamic> json) {
    return TradeDistributionMetricsDto(
      tradesByDay: _distIntMap(json['tradesByDay']),
      tradesByMonth: _distIntMap(json['tradesByMonth']),
      profitByDay: _distDoubleMap(json['profitByDay']),
      profitByMonth: _distDoubleMap(json['profitByMonth']),
      winRateByDay: _distDoubleMap(json['winRateByDay']),
      winRateByMonth: _distDoubleMap(json['winRateByMonth']),
      avgPnlByDay: _distDoubleMap(json['avgPnlByDay']),
      avgPnlByMonth: _distDoubleMap(json['avgPnlByMonth']),
      avgPnlPerActiveDayByDay: _distDoubleMap(json['avgPnlPerActiveDayByDay']),
      avgPnlPerActiveDayByMonth:
          _distDoubleMap(json['avgPnlPerActiveDayByMonth']),
      eligibleTradesByDay: _distIntMap(json['eligibleTradesByDay']),
      eligibleTradesByMonth: _distIntMap(json['eligibleTradesByMonth']),
      activeTradingDaysByDay: _distIntMap(json['activeTradingDaysByDay']),
      activeTradingDaysByMonth: _distIntMap(json['activeTradingDaysByMonth']),
      tradesByHour: _distIntMap(json['tradesByHour']),
      profitByHour: _distDoubleMap(json['profitByHour']),
      winRateByHour: _distDoubleMap(json['winRateByHour']),
      avgPnlByHour: _distDoubleMap(json['avgPnlByHour']),
      avgPnlPerActiveDayByHour:
          _distDoubleMap(json['avgPnlPerActiveDayByHour']),
      eligibleTradesByHour: _distIntMap(json['eligibleTradesByHour']),
      activeTradingDaysByHour: _distIntMap(json['activeTradingDaysByHour']),
      tradesBySession: _distIntMap(json['tradesBySession']),
      profitBySession: _distDoubleMap(json['profitBySession']),
      winRateBySession: _distDoubleMap(json['winRateBySession']),
      avgPnlBySession: _distDoubleMap(json['avgPnlBySession']),
      avgPnlPerActiveDayBySession:
          _distDoubleMap(json['avgPnlPerActiveDayBySession']),
      eligibleTradesBySession: _distIntMap(json['eligibleTradesBySession']),
      activeTradingDaysBySession:
          _distIntMap(json['activeTradingDaysBySession']),
      avgHoldMinutesByDay: _distDoubleMap(json['avgHoldMinutesByDay']),
      avgHoldMinutesByHour: _distDoubleMap(json['avgHoldMinutesByHour']),
      avgHoldMinutesByMonth: _distDoubleMap(json['avgHoldMinutesByMonth']),
      avgHoldMinutesBySession: _distDoubleMap(json['avgHoldMinutesBySession']),
      riskRewardByDay: _distDoubleMap(json['riskRewardByDay']),
      riskRewardByHour: _distDoubleMap(json['riskRewardByHour']),
      riskRewardByMonth: _distDoubleMap(json['riskRewardByMonth']),
      riskRewardBySession: _distDoubleMap(json['riskRewardBySession']),
      tradeCountByAssetClass: _distIntMap(json['tradeCountByAssetClass']),
      profitByAssetClass: _distDoubleMap(json['profitByAssetClass']),
      winRateByAssetClass: _distDoubleMap(json['winRateByAssetClass']),
      tradeCountByStrategy: _distIntMap(json['tradeCountByStrategy']),
      profitByStrategy: _distDoubleMap(json['profitByStrategy']),
      winRateByStrategy: _distDoubleMap(json['winRateByStrategy']),
      tradesByDuration: _distIntMap(json['tradesByDuration']),
      profitByDuration: _distDoubleMap(json['profitByDuration']),
      winRateByDuration: _distDoubleMap(json['winRateByDuration']),
      tradesByPositionSize: _distIntMap(json['tradesByPositionSize']),
      profitByPositionSize: _distDoubleMap(json['profitByPositionSize']),
      winRateByPositionSize: _distDoubleMap(json['winRateByPositionSize']),
      skippedMissingEntryCount: _asNum(json['skippedMissingEntryCount'])?.toInt(),
      openOrMissingPnlCount: _asNum(json['openOrMissingPnlCount'])?.toInt(),
      badTimestampCount: _asNum(json['badTimestampCount'])?.toInt(),
      timezoneNote: json['timezoneNote'] as String?,
      tradingStyleHint: json['tradingStyleHint'] == null
          ? null
          : TradingStyleHintDto.fromJson(
              json['tradingStyleHint'] as Map<String, dynamic>,
            ),
      bestSessionKey: json['bestSessionKey'] as String?,
      bestSessionAvgPnl: _asNum(json['bestSessionAvgPnl'])?.toDouble(),
      activeTradingDaysCount: _asNum(json['activeTradingDaysCount'])?.toInt(),
      avgPnlPerActiveDay: _asNum(json['avgPnlPerActiveDay'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => _$TradeDistributionMetricsDtoToJson(this);

  TradeDistributionMetrics toEntity() => TradeDistributionMetrics(
        tradesByDay: tradesByDay ?? {},
        profitByDay: profitByDay ?? {},
        winRateByDay: _nullableDoubleMap(winRateByDay),
        avgPnlByDay: _nullableDoubleMap(avgPnlByDay),
        avgPnlPerActiveDayByDay: _nullableDoubleMap(avgPnlPerActiveDayByDay),
        eligibleTradesByDay: eligibleTradesByDay ?? {},
        activeTradingDaysByDay: activeTradingDaysByDay ?? {},
        avgHoldMinutesByDay: _nullableDoubleMap(avgHoldMinutesByDay),
        riskRewardByDay: _nullableDoubleMap(riskRewardByDay),
        tradesByHour: tradesByHour ?? {},
        profitByHour: profitByHour ?? {},
        winRateByHour: _nullableDoubleMap(winRateByHour),
        avgPnlByHour: _nullableDoubleMap(avgPnlByHour),
        avgPnlPerActiveDayByHour: _nullableDoubleMap(avgPnlPerActiveDayByHour),
        eligibleTradesByHour: eligibleTradesByHour ?? {},
        activeTradingDaysByHour: activeTradingDaysByHour ?? {},
        avgHoldMinutesByHour: _nullableDoubleMap(avgHoldMinutesByHour),
        riskRewardByHour: _nullableDoubleMap(riskRewardByHour),
        tradesByMonth: tradesByMonth ?? {},
        profitByMonth: profitByMonth ?? {},
        winRateByMonth: _nullableDoubleMap(winRateByMonth),
        avgPnlByMonth: _nullableDoubleMap(avgPnlByMonth),
        avgPnlPerActiveDayByMonth:
            _nullableDoubleMap(avgPnlPerActiveDayByMonth),
        eligibleTradesByMonth: eligibleTradesByMonth ?? {},
        activeTradingDaysByMonth: activeTradingDaysByMonth ?? {},
        avgHoldMinutesByMonth: _nullableDoubleMap(avgHoldMinutesByMonth),
        riskRewardByMonth: _nullableDoubleMap(riskRewardByMonth),
        tradesBySession: tradesBySession ?? {},
        profitBySession: profitBySession ?? {},
        winRateBySession: _nullableDoubleMap(winRateBySession),
        avgPnlBySession: _nullableDoubleMap(avgPnlBySession),
        avgPnlPerActiveDayBySession:
            _nullableDoubleMap(avgPnlPerActiveDayBySession),
        eligibleTradesBySession: eligibleTradesBySession ?? {},
        activeTradingDaysBySession: activeTradingDaysBySession ?? {},
        avgHoldMinutesBySession: _nullableDoubleMap(avgHoldMinutesBySession),
        riskRewardBySession: _nullableDoubleMap(riskRewardBySession),
        tradeCountByAssetClass: tradeCountByAssetClass ?? {},
        tradeCountByStrategy: tradeCountByStrategy ?? {},
        skippedMissingEntryCount: skippedMissingEntryCount ?? 0,
        openOrMissingPnlCount: openOrMissingPnlCount ?? 0,
        badTimestampCount: badTimestampCount ?? 0,
        timezoneNote: timezoneNote ?? 'entry_local_as_stored',
        tradingStyleHint: tradingStyleHint?.toEntity(),
        bestSessionKey: bestSessionKey,
        bestSessionAvgPnl: bestSessionAvgPnl,
        activeTradingDaysCount: activeTradingDaysCount ?? 0,
        avgPnlPerActiveDay: avgPnlPerActiveDay,
      );
}

/// Keeps only non-null numeric entries (Jackson may send null win%/avg).
Map<String, double> _nullableDoubleMap(Map<String, double>? source) {
  if (source == null) return {};
  return {
    for (final e in source.entries)
      if (e.value.isFinite) e.key: e.value,
  };
}

@JsonSerializable()
class TradeTimingMetricsDto {
  final double? entryTimingScore;
  final double? exitTimingScore;
  final Map<String, int>? earlyEntries;
  final Map<String, int>? optimalEntries;

  TradeTimingMetricsDto({
    this.entryTimingScore,
    this.exitTimingScore,
    this.earlyEntries,
    this.optimalEntries,
  });

  factory TradeTimingMetricsDto.fromJson(Map<String, dynamic> json) => _$TradeTimingMetricsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TradeTimingMetricsDtoToJson(this);

  TradeTimingMetrics toEntity() => TradeTimingMetrics(
    entryTimingScore: entryTimingScore ?? 0.0,
    exitTimingScore: exitTimingScore ?? 0.0,
    earlyEntries: earlyEntries ?? {},
    optimalEntries: optimalEntries ?? {},
  );
}

@JsonSerializable()
class TradePatternMetricsDto {
  final double? emotionalControlScore;
  final double? disciplineScore;
  final double? patternConsistencyScore;
  final Map<String, int>? patternFrequency;

  TradePatternMetricsDto({
    this.emotionalControlScore,
    this.disciplineScore,
    this.patternConsistencyScore,
    this.patternFrequency,
  });

  factory TradePatternMetricsDto.fromJson(Map<String, dynamic> json) => _$TradePatternMetricsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TradePatternMetricsDtoToJson(this);

  TradePatternMetrics toEntity() => TradePatternMetrics(
    emotionalControlScore: emotionalControlScore ?? 0.0,
    disciplineScore: disciplineScore ?? 0.0,
    patternConsistencyScore: patternConsistencyScore ?? 0.0,
    patternFrequency: patternFrequency ?? {},
  );
}

@JsonSerializable(createFactory: false)
class StrategyPerformanceMetricsDto {
  final String strategyName;
  final double totalProfitLoss;
  final double winRate;
  final double sharpeRatio;

  StrategyPerformanceMetricsDto({
    required this.strategyName,
    required this.totalProfitLoss,
    required this.winRate,
    required this.sharpeRatio,
  });

  factory StrategyPerformanceMetricsDto.fromJson(Map<String, dynamic> json) {
    return StrategyPerformanceMetricsDto(
      strategyName: json['strategyName'] as String? ?? '',
      totalProfitLoss: _asNum(json['totalProfitLoss'])?.toDouble() ?? 0,
      winRate: _asNum(json['winRate'])?.toDouble() ?? 0,
      sharpeRatio: _asNum(json['sharpeRatio'])?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => _$StrategyPerformanceMetricsDtoToJson(this);

  StrategyPerformanceMetrics toEntity() => StrategyPerformanceMetrics(
    strategyName: strategyName,
    totalProfitLoss: totalProfitLoss,
    winRate: winRate,
    sharpeRatio: sharpeRatio,
  );
}

@JsonSerializable()
class TradeDetailsDto {
  final String? tradeId;
  final String? symbol;
  final String? strategy;
  final String? status;
  final String? tradePositionType;
  final String? notes;
  final List<String>? tags;

  TradeDetailsDto({
    this.tradeId,
    this.symbol,
    this.strategy,
    this.status,
    this.tradePositionType,
    this.notes,
    this.tags,
  });

  factory TradeDetailsDto.fromJson(Map<String, dynamic> json) => _$TradeDetailsDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TradeDetailsDtoToJson(this);

  TradeDetails toEntity() => TradeDetails(
    tradeId: tradeId,
    symbol: symbol,
    strategy: strategy,
    status: status,
    tradePositionType: tradePositionType,
    notes: notes,
    tags: tags,
  );
}

@JsonSerializable()
class TradeMetricsResponseDto {
  final List<String> portfolioIds;
  final DateTime startDate;
  final DateTime endDate;
  @JsonKey(fromJson: _asIntOrZero)
  final int totalTradesCount;
  final List<TradeDetailsDto>? tradeDetails;
  final PerformanceMetricsDto? performanceMetrics;
  final RiskMetricsDto? riskMetrics;
  final TradeDistributionMetricsDto? distributionMetrics;
  final TradeTimingMetricsDto? timingMetrics;
  final TradePatternMetricsDto? patternMetrics;
  final Map<String, StrategyPerformanceMetricsDto>? strategyMetrics;
  final Map<String, Map<String, dynamic>>? groupedMetrics;
  final Map<String, dynamic>? metadata;

  TradeMetricsResponseDto({
    required this.portfolioIds,
    required this.startDate,
    required this.endDate,
    required this.totalTradesCount,
    this.tradeDetails,
    this.performanceMetrics,
    this.riskMetrics,
    this.distributionMetrics,
    this.timingMetrics,
    this.patternMetrics,
    this.strategyMetrics,
    this.groupedMetrics,
    this.metadata,
  });

  factory TradeMetricsResponseDto.fromJson(Map<String, dynamic> json) => _$TradeMetricsResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TradeMetricsResponseDtoToJson(this);

  TradeMetricsResponse toEntity() => TradeMetricsResponse(
    portfolioIds: portfolioIds,
    startDate: startDate,
    endDate: endDate,
    totalTradesCount: totalTradesCount,
    tradeDetails: tradeDetails?.map((e) => e.toEntity()).toList(),
    performanceMetrics: performanceMetrics?.toEntity() ?? PerformanceMetrics(
      totalProfitLoss: null,
      totalProfitLossPercentage: null,
      winRate: 0.0,
      profitFactor: 0.0,
      expectancy: 0.0,
      annualizedReturn: 0.0,
      averageWinningTrade: 0.0,
      averageLosingTrade: 0.0,
      largestWinningTrade: 0.0,
      largestLosingTrade: 0.0,
      winLossRatio: 0.0,
      maxDrawdown: 0.0,
      longestWinningStreak: 0,
      longestLosingStreak: 0,
      returnOnCapital: 0.0,
      tradesPerDay: 0.0,
    ),
    riskMetrics: riskMetrics?.toEntity() ?? RiskMetrics(
      maxDrawdown: 0.0,
      sharpeRatio: 0.0,
      sortinoRatio: 0.0,
      valueAtRisk: 0.0,
      probabilityOfRuin: 0.0,
    ),
    distributionMetrics: distributionMetrics?.toEntity() ??
        TradeDistributionMetrics(
          tradesByDay: {},
          profitByDay: {},
          tradesByHour: {},
          profitByHour: {},
          tradeCountByAssetClass: {},
          tradeCountByStrategy: {},
        ),
    timingMetrics: timingMetrics?.toEntity() ?? TradeTimingMetrics(
      entryTimingScore: 0.0,
      exitTimingScore: 0.0,
      earlyEntries: {},
      optimalEntries: {},
    ),
    patternMetrics: patternMetrics?.toEntity() ?? TradePatternMetrics(
      emotionalControlScore: 0.0,
      disciplineScore: 0.0,
      patternConsistencyScore: 0.0,
      patternFrequency: {},
    ),
    strategyMetrics: strategyMetrics?.map((k, v) => MapEntry(k, v.toEntity())) ?? {},
    groupedMetrics: groupedMetrics ?? {},
    metadata: metadata ?? {},
  );
}

@JsonSerializable()
class DateRangeDto {
  final DateTime startDate;
  final DateTime endDate;

  DateRangeDto({required this.startDate, required this.endDate});

  factory DateRangeDto.fromJson(Map<String, dynamic> json) => _$DateRangeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$DateRangeDtoToJson(this);
}



@JsonSerializable()
class MetricsFilterRequestDto {
  final List<String> portfolioIds;
  final DateRangeDto dateRange;
  final String? timePeriod;
  final List<MetricTypes>? metricTypes;
  final List<String>? instruments;
  final List<String>? groupBy;
  final bool includeTradeDetails;
  final Map<String, dynamic>? customFilters;
  final Map<String, dynamic>? tradeCharacteristics;

  MetricsFilterRequestDto({
    required this.portfolioIds,
    required this.dateRange,
    this.timePeriod,
    this.metricTypes,
    this.instruments,
    this.groupBy,
    this.includeTradeDetails = false,
    this.customFilters,
    this.tradeCharacteristics,
  });

  factory MetricsFilterRequestDto.fromJson(Map<String, dynamic> json) =>
      _$MetricsFilterRequestDtoFromJson(json);

  Map<String, dynamic> toJson() {
    final json = _$MetricsFilterRequestDtoToJson(this);
    // json_serializable emits DateRangeDto object; API expects nested map.
    json['dateRange'] = {
      'startDate': dateRange.startDate.toIso8601String().split('T').first,
      'endDate': dateRange.endDate.toIso8601String().split('T').first,
    };
    return json;
  }

  factory MetricsFilterRequestDto.fromEntity(MetricsFilterRequest entity) =>
      MetricsFilterRequestDto(
        portfolioIds: entity.portfolioIds,
        dateRange: DateRangeDto(
          startDate: entity.startDate,
          endDate: entity.endDate,
        ),
        timePeriod: entity.timePeriod,
        metricTypes: entity.metricTypes,
        instruments: entity.instruments,
        groupBy: entity.groupBy,
        includeTradeDetails: entity.includeTradeDetails,
        customFilters: entity.customFilters,
        tradeCharacteristics: entity.holdingStyle == null
            ? null
            : {'holdingStyle': entity.holdingStyle},
      );
}
