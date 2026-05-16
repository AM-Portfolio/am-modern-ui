class PortfolioSocketUpdateDto {
  final String userId;
  final String? portfolioId;
  final double currentValue;
  final double investmentValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double todayGainLoss;
  final double todayGainLossPercentage;
  final List<SocketEquityHoldingDto> equities;

  PortfolioSocketUpdateDto({
    required this.userId,
    this.portfolioId,
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
      portfolioId: json['portfolioId'] as String?,
      currentValue: _parseDouble(json['currentValue']),
      investmentValue: _parseDouble(json['investmentValue']),
      totalGainLoss: _parseDouble(json['totalGainLoss']),
      totalGainLossPercentage: _parseDouble(json['totalGainLossPercentage']),
      todayGainLoss: _parseDouble(json['todayGainLoss']),
      todayGainLossPercentage: _parseDouble(json['todayGainLossPercentage']),
      equities: json['equities'] is List
          ? (json['equities'] as List)
                .map(
                  (e) => SocketEquityHoldingDto.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class SocketEquityHoldingDto {
  final String isin;
  final String symbol;
  final String name;
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
    required this.name,
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
      name: json['name'] as String? ?? '',
      quantity: PortfolioSocketUpdateDto._parseDouble(json['quantity']),
      currentPrice: PortfolioSocketUpdateDto._parseDouble(json['currentPrice']),
      currentValue: PortfolioSocketUpdateDto._parseDouble(json['currentValue']),
      investmentValue: PortfolioSocketUpdateDto._parseDouble(
        json['investmentValue'],
      ),
      profitLoss: PortfolioSocketUpdateDto._parseDouble(json['profitLoss']),
      profitLossPercentage: PortfolioSocketUpdateDto._parseDouble(
        json['profitLossPercentage'],
      ),
      todayProfitLoss: PortfolioSocketUpdateDto._parseDouble(
        json['todayProfitLoss'],
      ),
      todayProfitLossPercentage: PortfolioSocketUpdateDto._parseDouble(
        json['todayProfitLossPercentage'],
      ),
    );
  }
}
