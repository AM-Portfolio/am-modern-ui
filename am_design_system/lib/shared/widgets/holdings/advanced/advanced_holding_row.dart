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
    this.assetClass,
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
  /// EQUITY / BONDS / CASH / … — chip when non-equity class rows.
  final String? assetClass;
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

  bool get isTodayUp => todayChangePercentage >= 0;

  bool get hasDistinctCompanyName =>
      companyName.isNotEmpty &&
      companyName.toUpperCase() != symbol.toUpperCase();

  /// True when row is a non-equity class sleeve (cash/bonds/etc.).
  bool get showAssetClassChip {
    final c = assetClass?.trim().toUpperCase();
    return c != null && c.isNotEmpty && c != 'EQUITY' && c != 'EQ';
  }

  String get displayAssetClass {
    final c = assetClass?.trim();
    if (c == null || c.isEmpty) return '';
    if (c.length == 1) return c.toUpperCase();
    return '${c[0].toUpperCase()}${c.substring(1).toLowerCase()}';
  }

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _qty = NumberFormat('#,##0.##');

  String get displaySymbol => symbol.isEmpty ? '—' : symbol;

  String get displayCompanyName =>
      companyName.isEmpty ? displaySymbol : companyName;

  String get displaySector {
    final s = sector?.trim();
    if (s != null && s.isNotEmpty) return s;
    if (showAssetClassChip) return displayAssetClass;
    return '—';
  }

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

  String get displayTodayChangePercentage {
    final prefix = todayChangePercentage >= 0 ? '+' : '';
    return '$prefix${todayChangePercentage.toStringAsFixed(2)}%';
  }

  String get displayWeight => '${portfolioWeight.toStringAsFixed(1)}%';

  String get displayMetaSubtitle {
    final parts = <String>[];
    final s = sector?.trim();
    if (s != null && s.isNotEmpty) {
      parts.add(s);
    } else if (showAssetClassChip) {
      parts.add(displayAssetClass);
    }
    parts.add(displayTodayChangePercentage);
    return parts.join(' · ');
  }
}
