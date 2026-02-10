
class PortfolioSocketUpdateDto {
  final String userId;
  final double currentValue;
  final double investmentValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double todayGainLoss;
  final double todayGainLossPercentage;
  final List<SocketEquityHoldingDto> equities;

  PortfolioSocketUpdateDto({
    required this.userId,
    required this.currentValue,
    required this.investmentValue,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.todayGainLoss,
    required this.todayGainLossPercentage,
    required this.equities,
  });

  factory PortfolioSocketUpdateDto.fromJson(Map<String, dynamic> json) {
    return PortfolioSocketUpdateDto(
      userId: json['userId'] as String? ?? '',
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      investmentValue: (json['investmentValue'] as num?)?.toDouble() ?? 0.0,
      totalGainLoss: (json['totalGainLoss'] as num?)?.toDouble() ?? 0.0,
      totalGainLossPercentage: (json['totalGainLossPercentage'] as num?)?.toDouble() ?? 0.0,
      todayGainLoss: (json['todayGainLoss'] as num?)?.toDouble() ?? 0.0,
      todayGainLossPercentage: (json['todayGainLossPercentage'] as num?)?.toDouble() ?? 0.0,
      equities: (json['equities'] as List<dynamic>?)
          ?.map((e) => SocketEquityHoldingDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class SocketEquityHoldingDto {
  final String isin;
  final String symbol;
  final double quantity;
  final double currentPrice;
  final double currentValue;
  final double investmentValue;
  final double profitLoss;
  final double profitLossPercentage;
  final double todayProfitLoss;
  final double todayProfitLossPercentage;

  SocketEquityHoldingDto({
    required this.isin,
    required this.symbol,
    required this.quantity,
    required this.currentPrice,
    required this.currentValue,
    required this.investmentValue,
    required this.profitLoss,
    required this.profitLossPercentage,
    required this.todayProfitLoss,
    required this.todayProfitLossPercentage,
  });

  factory SocketEquityHoldingDto.fromJson(Map<String, dynamic> json) {
    return SocketEquityHoldingDto(
      isin: json['isin'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toDouble() ?? 0.0,
      investmentValue: (json['investmentValue'] as num?)?.toDouble() ?? 0.0,
      profitLoss: (json['profitLoss'] as num?)?.toDouble() ?? 0.0,
      profitLossPercentage: (json['profitLossPercentage'] as num?)?.toDouble() ?? 0.0,
      todayProfitLoss: (json['todayProfitLoss'] as num?)?.toDouble() ?? 0.0,
      todayProfitLossPercentage: (json['todayProfitLossPercentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
