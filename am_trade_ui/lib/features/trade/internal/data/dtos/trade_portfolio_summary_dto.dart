import 'package:freezed_annotation/freezed_annotation.dart';
import 'portfolio_metrics_dto.dart';

part 'trade_portfolio_summary_dto.freezed.dart';
part 'trade_portfolio_summary_dto.g.dart';

@freezed
abstract class TradePortfolioSummaryDto with _$TradePortfolioSummaryDto {
  const factory TradePortfolioSummaryDto({
    required String portfolioId,
    required String name,
    String? description,
    String? ownerId,
    @Default(true) bool active,
    String? currency,
    double? initialCapital,
    double? currentCapital,
    String? createdDate,
    String? lastUpdatedDate,
    PortfolioMetricsDto? metrics,
    @Default([]) List<String> tradeIds,
    List<String>? winningTradeIds,
    List<String>? losingTradeIds,
    Map<String, dynamic>? assetAllocations,
  }) = _TradePortfolioSummaryDto;

  factory TradePortfolioSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TradePortfolioSummaryDtoFromJson(json);
}
