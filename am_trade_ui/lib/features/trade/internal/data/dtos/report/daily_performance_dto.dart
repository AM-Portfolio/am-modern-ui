import 'package:freezed_annotation/freezed_annotation.dart';
import 'performance_metrics_dto.dart';

part 'daily_performance_dto.g.dart';

@JsonSerializable()
class DailyPerformanceDto {
  final String date; // Using String as per schema format: date
  final double totalProfitLoss;
  final int tradeCount;
  final int winCount;
  final int lossCount;
  final double winRate;
  final String? bestTradeSymbol;
  final double? bestTradePnL;
  final PerformanceMetricsDto metrics;

  DailyPerformanceDto({
    required this.date,
    required this.totalProfitLoss,
    required this.tradeCount,
    required this.winCount,
    required this.lossCount,
    required this.winRate,
    this.bestTradeSymbol,
    this.bestTradePnL,
    required this.metrics,
  });

  factory DailyPerformanceDto.fromJson(Map<String, dynamic> json) {
    // Handle "Infinity" strings and nulls from API
    final patchedJson = Map<String, dynamic>.from(json);
    for (final key in patchedJson.keys) {
      final value = patchedJson[key];
      if (value is String) {
        if (value == 'Infinity' || value == '+Infinity') {
            patchedJson[key] = double.infinity;
        } else if (value == '-Infinity') {
            patchedJson[key] = double.negativeInfinity;
        } else if (value == 'NaN') {
            patchedJson[key] = double.nan;
        }
      } else if (value == null) {
          // If value is null, check if we should likely invoke a default.
          // Since we can't easily know the type here without reflection,
          // checking potentially numeric keys or just setting to 0 if it looks like a number field is risky.
          // But for DTOs where we know fields are required double/int, we can try to be safe.
          // However, simpler is: if the generated code crashes on null, we assume it's a number field.
          // Let's explicitly list known numeric fields or just being safe by assigning 0 for known numeric keys.
          if (['totalProfitLoss', 'tradeCount', 'winCount', 'lossCount', 'winRate', 'bestTradePnL'].contains(key)) {
             patchedJson[key] = 0;
          }
      }
    }
    // Also explicitly ensure known fields are present and not null
    final numericFields = ['totalProfitLoss', 'tradeCount', 'winCount', 'lossCount', 'winRate'];
    for (var field in numericFields) {
        if (patchedJson[field] == null) {
            patchedJson[field] = 0;
        }
    }
    
    return _$DailyPerformanceDtoFromJson(patchedJson);
  }
  Map<String, dynamic> toJson() => _$DailyPerformanceDtoToJson(this);
}
