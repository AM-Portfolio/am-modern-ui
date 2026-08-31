import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary_response_dto.freezed.dart';
part 'portfolio_summary_response_dto.g.dart';

/// Lightweight DTO for the fields we consume from am-portfolio's
/// GET /v1/portfolios/summary?portfolioId={id} response.
///
/// Only maps the fields needed by the Trade Portfolio card to display
/// live Unrealized P&L. The full PortfolioSummaryV1 Java model has 30+
/// fields — we intentionally don't map them all to keep this DTO lean.
@freezed
abstract class PortfolioSummaryResponseDto with _$PortfolioSummaryResponseDto {
  const factory PortfolioSummaryResponseDto({
    /// Total live market value of all holdings
    double? totalValue,

    /// Live unrealized gain/loss in absolute currency (e.g. -₹64.09)
    double? totalGainLoss,

    /// Live unrealized gain/loss as a percentage (e.g. -2.33)
    double? totalGainLossPercentage,

    /// Intraday change in absolute currency
    double? todayChange,

    /// Intraday change as a percentage
    double? todayChangePercentage,

    /// Total invested amount (cost basis)
    double? investedValue,

    /// Number of total open holdings (from am-portfolio)
    int? totalAssets,

    /// Number of open holdings that are currently in profit (from am-portfolio)
    int? gainersCount,
  }) = _PortfolioSummaryResponseDto;

  factory PortfolioSummaryResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryResponseDtoFromJson(json);
}
