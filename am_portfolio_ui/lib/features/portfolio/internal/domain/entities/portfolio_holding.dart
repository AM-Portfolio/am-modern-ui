import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:am_design_system/shared/models/holding.dart';

part 'portfolio_holding.freezed.dart';
part 'portfolio_holding.g.dart';

/// Domain entity representing a portfolio holding
@freezed
abstract class PortfolioHolding with _$PortfolioHolding implements Holding {
  const factory PortfolioHolding({
    required String id,
    required String symbol,
    required String name,
    required String companyName,
    required String sector,
    required String industry,
    required double quantity,
    required double avgPrice,
    required double currentPrice,
    required double investedAmount,
    required double currentValue,
    required double todayChange,
    required double todayChangePercentage,
    required double totalGainLoss,
    required double totalGainLossPercentage,
    required double portfolioWeight,
    @Default('EQUITY') String assetClass,
    @Default([]) List<BrokerHolding> brokerHoldings,
  }) = _PortfolioHolding;
  const PortfolioHolding._();

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) =>
      _$PortfolioHoldingFromJson(json);

  /// Check if the holding is profitable
  bool get isProfitable => totalGainLoss >= 0;

  /// Check if today's performance is positive
  bool get isTodayPositive => todayChange >= 0;

  /// Mail/statement imports often have no invested amount or average price.
  @override
  bool get hasCostBasis => investedAmount > 0 || avgPrice > 0;

  /// Get the primary broker holding (with most quantity)
  BrokerHolding? get primaryBroker {
    if (brokerHoldings.isEmpty) return null;
    return brokerHoldings.reduce((a, b) => a.quantity > b.quantity ? a : b);
  }
}

/// Domain entity representing a broker holding
@freezed
abstract class BrokerHolding with _$BrokerHolding {
  const factory BrokerHolding({
    required String brokerId,
    required String brokerName,
    required double quantity,
    required double avgPrice,
    required double investedAmount,
    required DateTime? lastUpdated,
  }) = _BrokerHolding;

  factory BrokerHolding.fromJson(Map<String, dynamic> json) =>
      _$BrokerHoldingFromJson(json);
}

/// Domain entity representing portfolio holdings collection
@freezed
abstract class PortfolioHoldings with _$PortfolioHoldings {
  const factory PortfolioHoldings({
    required List<PortfolioHolding> holdings,
    required DateTime lastUpdated,
    DateTime? asOf,
    @Default('AS_OF') String priceFreshness,
    String? priceSource,
    String? sessionDate,
  }) = _PortfolioHoldings;
  const PortfolioHoldings._();

  factory PortfolioHoldings.fromJson(Map<String, dynamic> json) =>
      _$PortfolioHoldingsFromJson(json);

  factory PortfolioHoldings.empty() => PortfolioHoldings(
    holdings: const [],
    lastUpdated: DateTime.now(),
    priceFreshness: 'AS_OF',
  );

  bool get isLivePrices => priceFreshness == 'LIVE';

  String get priceLabel {
    if (isLivePrices) return 'Live';
    final stamp = asOf ?? lastUpdated;
    final hh = stamp.hour.toString().padLeft(2, '0');
    final mm = stamp.minute.toString().padLeft(2, '0');
    final datePart = (sessionDate != null && sessionDate!.isNotEmpty)
        ? sessionDate!
        : '${stamp.year.toString().padLeft(4, '0')}-'
            '${stamp.month.toString().padLeft(2, '0')}-'
            '${stamp.day.toString().padLeft(2, '0')}';
    return 'As of $datePart $hh:$mm';
  }

  /// True when any holding has invested amount or average price.
  bool get hasCostBasis => holdingsHaveCostBasis(holdings);

  /// Check if portfolio is empty
  bool get isEmpty => holdings.isEmpty;

  /// Get total number of holdings
  int get totalHoldings => holdings.length;

  /// Calculate total portfolio value
  double get totalValue =>
      holdings.fold(0.0, (sum, holding) => sum + holding.currentValue);

  /// Calculate total invested amount
  double get totalInvested =>
      holdings.fold(0.0, (sum, holding) => sum + holding.investedAmount);

  /// Calculate total gain/loss
  double get totalGainLoss => totalValue - totalInvested;

  /// Calculate total gain/loss percentage
  double get totalGainLossPercentage =>
      totalInvested > 0 ? (totalGainLoss / totalInvested) * 100 : 0.0;

  /// Calculate today's total change
  double get todayTotalChange =>
      holdings.fold(0.0, (sum, holding) => sum + holding.todayChange);

  /// Calculate today's total change percentage
  double get todayTotalChangePercentage =>
      totalInvested > 0 ? (todayTotalChange / totalInvested) * 100 : 0.0;

  /// Group holdings by sector
  Map<String, List<PortfolioHolding>> get holdingsBySector {
    final sectors = <String, List<PortfolioHolding>>{};
    for (final holding in holdings) {
      sectors.putIfAbsent(holding.sector, () => []).add(holding);
    }
    return sectors;
  }

  /// Get top performing holdings
  List<PortfolioHolding> getTopPerformers(int count) {
    final sorted = List<PortfolioHolding>.from(holdings);
    sorted.sort(
      (a, b) => b.totalGainLossPercentage.compareTo(a.totalGainLossPercentage),
    );
    return sorted.take(count).toList();
  }

  /// Get worst performing holdings
  List<PortfolioHolding> getWorstPerformers(int count) {
    final sorted = List<PortfolioHolding>.from(holdings);
    sorted.sort(
      (a, b) => a.totalGainLossPercentage.compareTo(b.totalGainLossPercentage),
    );
    return sorted.take(count).toList();
  }

  /// Filter holdings by sector
  List<PortfolioHolding> getHoldingsBySector(String sector) =>
      holdings.where((holding) => holding.sector == sector).toList();
}

/// True when any holding has invested amount or average price.
bool holdingsHaveCostBasis(Iterable<PortfolioHolding> holdings) =>
    holdings.any((h) => h.hasCostBasis);

/// Show Avg / Invested / P&L columns when the book has any cost basis.
bool showHoldingsCostColumns(Iterable<PortfolioHolding> holdings) =>
    holdingsHaveCostBasis(holdings);

/// Mixed books: drop zero-cost rows. All-zero-cost (mail) books: keep all rows.
List<PortfolioHolding> visibleHoldingsForCostPolicy(
  Iterable<PortfolioHolding> holdings,
) {
  final list = holdings.toList(growable: false);
  if (list.isEmpty) return const [];
  if (!holdingsHaveCostBasis(list)) return list;
  return list.where((h) => h.hasCostBasis).toList(growable: false);
}

/// Hide Invested / Total Return only after holdings are in and none have
/// cost, and the summary principal is also zero. Empty holdings (still
/// loading) must not look like a mail book.
bool overviewShowsCostMetrics({
  required double investmentValue,
  required double totalInvested,
  required Iterable<PortfolioHolding> holdings,
}) {
  if (investmentValue > 0 || totalInvested > 0) return true;
  if (holdings.isEmpty) return true;
  return holdingsHaveCostBasis(holdings);
}
