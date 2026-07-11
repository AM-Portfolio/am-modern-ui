import 'package:equatable/equatable.dart';

/// DTO for a single entry inside a snapshot (one broker/portfolio)
class PortfolioSnapshotEntryDto extends Equatable {
  final String? portfolioId;
  final String? portfolioName;
  final String? brokerType;
  final double? open;
  final double? high;
  final double? low;
  final double? close;
  final double? totalInvestment;
  final double? totalGainLoss;
  final double? totalGainLossPercentage;

  const PortfolioSnapshotEntryDto({
    this.portfolioId,
    this.portfolioName,
    this.brokerType,
    this.open,
    this.high,
    this.low,
    this.close,
    this.totalInvestment,
    this.totalGainLoss,
    this.totalGainLossPercentage,
  });

  factory PortfolioSnapshotEntryDto.fromJson(Map<String, dynamic> json) =>
      PortfolioSnapshotEntryDto(
        portfolioId: json['portfolioId'] as String?,
        portfolioName: json['portfolioName'] as String?,
        brokerType: json['brokerType'] as String?,
        open: (json['open'] as num?)?.toDouble(),
        high: (json['high'] as num?)?.toDouble(),
        low: (json['low'] as num?)?.toDouble(),
        close: (json['close'] as num?)?.toDouble(),
        totalInvestment: (json['totalInvestment'] as num?)?.toDouble(),
        totalGainLoss: (json['totalGainLoss'] as num?)?.toDouble(),
        totalGainLossPercentage:
            (json['totalGainLossPercentage'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'portfolioId': portfolioId,
        'portfolioName': portfolioName,
        'brokerType': brokerType,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'totalInvestment': totalInvestment,
        'totalGainLoss': totalGainLoss,
        'totalGainLossPercentage': totalGainLossPercentage,
      };

  @override
  List<Object?> get props => [
        portfolioId,
        portfolioName,
        brokerType,
        open,
        high,
        low,
        close,
        totalInvestment,
        totalGainLoss,
        totalGainLossPercentage,
      ];
}

/// DTO for a single daily snapshot (one day = one document)
class PortfolioSnapshotDto extends Equatable {
  final String? snapshotDate;
  final double? totalUserWealth;
  final double? totalUserWealthOpen;
  final double? totalUserWealthHigh;
  final double? totalUserWealthLow;
  final double? totalUserInvestment;
  final double? totalUserGainLoss;
  final double? totalUserGainLossPercentage;
  final List<PortfolioSnapshotEntryDto> portfolios;

  const PortfolioSnapshotDto({
    this.snapshotDate,
    this.totalUserWealth,
    this.totalUserWealthOpen,
    this.totalUserWealthHigh,
    this.totalUserWealthLow,
    this.totalUserInvestment,
    this.totalUserGainLoss,
    this.totalUserGainLossPercentage,
    required this.portfolios,
  });

  factory PortfolioSnapshotDto.fromJson(Map<String, dynamic> json) =>
      PortfolioSnapshotDto(
        snapshotDate: json['snapshotDate'] as String?,
        totalUserWealth: (json['totalUserWealth'] as num?)?.toDouble(),
        totalUserWealthOpen: (json['totalUserWealthOpen'] as num?)?.toDouble(),
        totalUserWealthHigh: (json['totalUserWealthHigh'] as num?)?.toDouble(),
        totalUserWealthLow: (json['totalUserWealthLow'] as num?)?.toDouble(),
        totalUserInvestment: (json['totalUserInvestment'] as num?)?.toDouble(),
        totalUserGainLoss: (json['totalUserGainLoss'] as num?)?.toDouble(),
        totalUserGainLossPercentage:
            (json['totalUserGainLossPercentage'] as num?)?.toDouble(),
        portfolios: (json['portfolios'] as List<dynamic>? ?? [])
            .map((e) =>
                PortfolioSnapshotEntryDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'snapshotDate': snapshotDate,
        'totalUserWealth': totalUserWealth,
        'totalUserWealthOpen': totalUserWealthOpen,
        'totalUserWealthHigh': totalUserWealthHigh,
        'totalUserWealthLow': totalUserWealthLow,
        'totalUserInvestment': totalUserInvestment,
        'totalUserGainLoss': totalUserGainLoss,
        'totalUserGainLossPercentage': totalUserGainLossPercentage,
        'portfolios': portfolios.map((e) => e.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        snapshotDate,
        totalUserWealth,
        totalUserWealthOpen,
        totalUserWealthHigh,
        totalUserWealthLow,
        totalUserInvestment,
        totalUserGainLoss,
        totalUserGainLossPercentage,
        portfolios,
      ];
}
