import 'package:intl/intl.dart';

/// Domain-neutral row for [AdvancedHoldingsTemplate].
///
/// Feature packages map their entities (portfolio holdings, etc.) into this
/// model. No trade-specific fields (tradeId, R:R, strategy).
class AdvancedHoldingRow {
  const AdvancedHoldingRow({
    required this.id,
    required this.symbol,
    required this.companyName,
    this.sector,
    this.industry,
    this.exchange,
    this.brokerLabel,
    this.quantity = 0,
    this.avgPrice = 0,
    this.currentPrice = 0,
    this.investedAmount = 0,
    this.currentValue = 0,
    this.totalGainLoss = 0,
    this.totalGainLossPercentage = 0,
    this.todayChange = 0,
    this.todayChangePercentage = 0,
    this.portfolioWeight = 0,
  });

  final String id;
  final String symbol;
  final String companyName;
  final String? sector;
  final String? industry;
  final String? exchange;
  final String? brokerLabel;
  final double quantity;
  final double avgPrice;
  final double currentPrice;
  final double investedAmount;
  final double currentValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double todayChange;
  final double todayChangePercentage;
  final double portfolioWeight;

  bool get isProfit => totalGainLoss >= 0;

  bool get hasDistinctCompanyName =>
      companyName.isNotEmpty &&
      companyName.toUpperCase() != symbol.toUpperCase();

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _qty = NumberFormat('#,##0.##');

  String get displaySymbol => symbol.isEmpty ? '—' : symbol;

  String get displayCompanyName =>
      companyName.isEmpty ? displaySymbol : companyName;

  String get displayQuantity => _qty.format(quantity);

  String get displayAvgPrice => _inr.format(avgPrice);

  String get displayCurrentPrice => _inr.format(currentPrice);

  String get displayCurrentValue => _inr.format(currentValue);

  String get displayInvestedAmount => _inr.format(investedAmount);

  String get displayProfitLoss {
    final prefix = totalGainLoss >= 0 ? '+' : '';
    return '$prefix${_inr.format(totalGainLoss)}';
  }

  String get displayProfitLossPercentage {
    final prefix = totalGainLossPercentage >= 0 ? '+' : '';
    return '$prefix${totalGainLossPercentage.toStringAsFixed(2)}%';
  }

  String get displayWeight => '${portfolioWeight.toStringAsFixed(1)}%';
}
