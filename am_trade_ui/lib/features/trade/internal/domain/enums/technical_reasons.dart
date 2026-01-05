import 'package:json_annotation/json_annotation.dart';

/// Technical analysis reasons for trade entry/exit
enum TechnicalReasons {
  @JsonValue('BREAKOUT')
  breakout,
  @JsonValue('SUPPORT_BOUNCE')
  supportBounce,
  @JsonValue('RESISTANCE_BREAK')
  resistanceBreak,
  @JsonValue('RESISTANCE_BREAKOUT')
  resistanceBreakout,
  @JsonValue('TREND_FOLLOWING')
  trendFollowing,
  @JsonValue('PATTERN_RECOGNITION')
  patternRecognition,
  @JsonValue('INDICATOR_SIGNAL')
  indicatorSignal,
  @JsonValue('MOVING_AVERAGE_CROSS')
  movingAverageCross,
  @JsonValue('MOVING_AVERAGE_CROSSOVER')
  movingAverageCrossover,
  @JsonValue('RSI_DIVERGENCE')
  rsiDivergence,
  @JsonValue('MACD_SIGNAL')
  macdSignal,
  @JsonValue('VOLUME_SPIKE')
  volumeSpike,
  @JsonValue('CHART_PATTERN')
  chartPattern,
  @JsonValue('OVERBOUGHT_RSI')
  overboughtRsi,
  @JsonValue('DIVERGENCE')
  divergence,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Converter for TechnicalReasons enum
class TechnicalReasonsConverter implements JsonConverter<TechnicalReasons?, String?> {
  const TechnicalReasonsConverter();

  @override
  TechnicalReasons? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'BREAKOUT':
        return TechnicalReasons.breakout;
      case 'SUPPORT_BOUNCE':
      case 'BOUNCE_FROM_SUPPORT':
        return TechnicalReasons.supportBounce;
      case 'RESISTANCE_BREAK':
      case 'BREAKING_RESISTANCE':
        return TechnicalReasons.resistanceBreak;
      case 'RESISTANCE_BREAKOUT':
      case 'BREAKOUT_RESISTANCE':
        return TechnicalReasons.resistanceBreakout;
      case 'TREND_FOLLOWING':
      case 'FOLLOWING_TREND':
        return TechnicalReasons.trendFollowing;
      case 'PATTERN_RECOGNITION':
      case 'PATTERN':
        return TechnicalReasons.patternRecognition;
      case 'INDICATOR_SIGNAL':
      case 'INDICATOR':
        return TechnicalReasons.indicatorSignal;
      case 'MOVING_AVERAGE_CROSS':
      case 'MA_CROSS':
      case 'EMA_CROSS':
        return TechnicalReasons.movingAverageCross;
      case 'MOVING_AVERAGE_CROSSOVER':
      case 'MA_CROSSOVER':
      case 'EMA_CROSSOVER':
        return TechnicalReasons.movingAverageCrossover;
      case 'RSI_DIVERGENCE':
      case 'RSI_DIV':
        return TechnicalReasons.rsiDivergence;
      case 'MACD_SIGNAL':
      case 'MACD':
      case 'MACD_CROSSOVER':
        return TechnicalReasons.macdSignal;
      case 'VOLUME_SPIKE':
      case 'HIGH_VOLUME':
      case 'VOLUME_SURGE':
        return TechnicalReasons.volumeSpike;
      case 'CHART_PATTERN':
      case 'PATTERN_BREAKOUT':
        return TechnicalReasons.chartPattern;
      case 'OVERBOUGHT_RSI':
      case 'RSI_OVERBOUGHT':
      case 'OVERBOUGHT':
        return TechnicalReasons.overboughtRsi;
      case 'DIVERGENCE':
      case 'BEARISH_DIVERGENCE':
      case 'BULLISH_DIVERGENCE':
        return TechnicalReasons.divergence;
      default:
        return TechnicalReasons.unknown;
    }
  }

  @override
  String? toJson(TechnicalReasons? value) {
    if (value == null) return null;

    switch (value) {
      case TechnicalReasons.breakout:
        return 'BREAKOUT';
      case TechnicalReasons.supportBounce:
        return 'SUPPORT_BOUNCE';
      case TechnicalReasons.resistanceBreak:
        return 'RESISTANCE_BREAK';
      case TechnicalReasons.resistanceBreakout:
        return 'RESISTANCE_BREAKOUT';
      case TechnicalReasons.trendFollowing:
        return 'TREND_FOLLOWING';
      case TechnicalReasons.patternRecognition:
        return 'PATTERN_RECOGNITION';
      case TechnicalReasons.indicatorSignal:
        return 'INDICATOR_SIGNAL';
      case TechnicalReasons.movingAverageCross:
        return 'MOVING_AVERAGE_CROSS';
      case TechnicalReasons.movingAverageCrossover:
        return 'MOVING_AVERAGE_CROSSOVER';
      case TechnicalReasons.rsiDivergence:
        return 'RSI_DIVERGENCE';
      case TechnicalReasons.macdSignal:
        return 'MACD_SIGNAL';
      case TechnicalReasons.volumeSpike:
        return 'VOLUME_SPIKE';
      case TechnicalReasons.chartPattern:
        return 'CHART_PATTERN';
      case TechnicalReasons.overboughtRsi:
        return 'OVERBOUGHT_RSI';
      case TechnicalReasons.divergence:
        return 'DIVERGENCE';
      case TechnicalReasons.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for TechnicalReasons enum
extension TechnicalReasonsExtension on TechnicalReasons {
  String get displayName {
    switch (this) {
      case TechnicalReasons.breakout:
        return 'Breakout';
      case TechnicalReasons.supportBounce:
        return 'Support Bounce';
      case TechnicalReasons.resistanceBreak:
        return 'Resistance Break';
      case TechnicalReasons.resistanceBreakout:
        return 'Resistance Breakout';
      case TechnicalReasons.trendFollowing:
        return 'Trend Following';
      case TechnicalReasons.patternRecognition:
        return 'Pattern Recognition';
      case TechnicalReasons.indicatorSignal:
        return 'Indicator Signal';
      case TechnicalReasons.movingAverageCross:
        return 'Moving Average Cross';
      case TechnicalReasons.movingAverageCrossover:
        return 'Moving Average Crossover';
      case TechnicalReasons.rsiDivergence:
        return 'RSI Divergence';
      case TechnicalReasons.macdSignal:
        return 'MACD Signal';
      case TechnicalReasons.volumeSpike:
        return 'Volume Spike';
      case TechnicalReasons.chartPattern:
        return 'Chart Pattern';
      case TechnicalReasons.overboughtRsi:
        return 'Overbought RSI';
      case TechnicalReasons.divergence:
        return 'Divergence';
      case TechnicalReasons.unknown:
        return 'Unknown';
    }
  }
}

/// List converter for TechnicalReasons
class TechnicalReasonsListConverter implements JsonConverter<List<TechnicalReasons>?, List<dynamic>?> {
  const TechnicalReasonsListConverter();

  @override
  List<TechnicalReasons>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    const converter = TechnicalReasonsConverter();
    return json.map((e) => converter.fromJson(e as String?)).whereType<TechnicalReasons>().toList();
  }

  @override
  List<dynamic>? toJson(List<TechnicalReasons>? values) {
    if (values == null) return null;
    const converter = TechnicalReasonsConverter();
    return values.map((e) => converter.toJson(e)).toList();
  }
}
