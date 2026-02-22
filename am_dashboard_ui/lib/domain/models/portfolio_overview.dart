import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_overview.freezed.dart';
part 'portfolio_overview.g.dart';

@freezed
abstract class PortfolioOverview with _$PortfolioOverview {
  const factory PortfolioOverview({
    required String type,
    required double totalValue,
    required double totalReturn,
    required double returnPercentage,
    required double dayChange,
    required double dayChangePercentage,
    required int portfolioCount,
  }) = _PortfolioOverview;

  factory PortfolioOverview.fromJson(Map<String, dynamic> json) =>
      _$PortfolioOverviewFromJson(json);
}
