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

  /// am-portfolio V1 uses `currentValue` / `todayGainLoss` / `investmentValue`.
  /// Accept those aliases so Trade cards do not drop Live P&L as null→₹0.
  factory PortfolioSummaryResponseDto.fromJson(Map<String, dynamic> json) {
    double? asDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? asInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return PortfolioSummaryResponseDto(
      totalValue: asDouble(json['totalValue'] ?? json['currentValue']),
      totalGainLoss: asDouble(json['totalGainLoss']),
      totalGainLossPercentage: asDouble(json['totalGainLossPercentage']),
      todayChange:
          asDouble(json['todayChange'] ?? json['todayGainLoss']),
      todayChangePercentage: asDouble(
        json['todayChangePercentage'] ?? json['todayGainLossPercentage'],
      ),
      investedValue:
          asDouble(json['investedValue'] ?? json['investmentValue']),
      totalAssets: asInt(json['totalAssets']),
      gainersCount: asInt(json['gainersCount']),
    );
  }
}
