import 'package:freezed_annotation/freezed_annotation.dart';

part 'trade_report_dto.g.dart';

/// DTO for trade report data from API
@JsonSerializable()
class TradeReportDto {
  final int totalTrades;
  final double netProfitLoss;
  final double winRate;
  final double profitFactor;
  final double maxDrawdown;
  final double avgWin;
  final double avgLoss;
  final List<String>? insights;
  final String generatedAt;

  TradeReportDto({
    required this.totalTrades,
    required this.netProfitLoss,
    required this.winRate,
    required this.profitFactor,
    required this.maxDrawdown,
    required this.avgWin,
    required this.avgLoss,
    this.insights,
    required this.generatedAt,
  });

  factory TradeReportDto.fromJson(Map<String, dynamic> json) => _$TradeReportDtoFromJson(json);
  Map<String, dynamic> toJson() => _$TradeReportDtoToJson(this);
}
