import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_summary.freezed.dart';
part 'portfolio_summary.g.dart';

/// Domain entity representing portfolio summary
@freezed
abstract class PortfolioSummary with _$PortfolioSummary {
  const factory PortfolioSummary({
    required double totalValue,
    required double totalInvested,
    required double investmentValue,
    required double totalGainLoss,
    required double totalGainLossPercentage,
    /// Null when day P&L baseline is unavailable (do not treat as ₹0).
    double? todayChange,
    double? todayChangePercentage,
    double? todayGainLossPercentage,
    required int totalHoldings,
    required int totalAssets,
    required int todayGainersCount,
    required int todayLosersCount,
    required int gainersCount,
    required int losersCount,
    required DateTime lastUpdated,
    DateTime? asOf,
    @Default('AS_OF') String priceFreshness,
    String? sessionDate,
    @Default([]) List<SectorAllocation> sectorAllocation,
    @Default([]) List<TopPerformer> topPerformers,
    @Default([]) List<TopPerformer> worstPerformers,
  }) = _PortfolioSummary;
  const PortfolioSummary._();

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) =>
      _$PortfolioSummaryFromJson(json);

  factory PortfolioSummary.empty() => PortfolioSummary(
    totalValue: 0.0,
    totalInvested: 0.0,
    investmentValue: 0.0,
    totalGainLoss: 0.0,
    totalGainLossPercentage: 0.0,
    todayChange: null,
    todayChangePercentage: null,
    todayGainLossPercentage: null,
    totalHoldings: 0,
    totalAssets: 0,
    todayGainersCount: 0,
    todayLosersCount: 0,
    gainersCount: 0,
    losersCount: 0,
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

  /// Check if portfolio is profitable
  bool get isProfitable => totalGainLoss >= 0;

  /// Whether day P&L has a usable baseline (vs unavailable after hours).
  bool get hasTodayChange => todayChange != null;

  /// Check if today's performance is positive
  bool get isTodayPositive => (todayChange ?? 0) >= 0;

  /// Get formatted total value
  String get formattedTotalValue => _formatCurrency(totalValue);

  /// Get formatted gain/loss
  String get formattedGainLoss => _formatCurrency(totalGainLoss);

  /// Get formatted today's change
  String get formattedTodayChange =>
      todayChange == null ? '—' : _formatCurrency(todayChange!);

  /// Short as-of label for closed-market day P&L.
  String get todayAsOfLabel {
    if (isLivePrices) return 'today';
    if (sessionDate != null && sessionDate!.isNotEmpty) {
      return 'as of $sessionDate';
    }
    return 'as of last session';
  }

  String _formatCurrency(double amount) {
    if (amount.abs() >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount.abs() >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount.abs() >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '₹${amount.toStringAsFixed(2)}';
    }
  }
}

/// Domain entity representing sector allocation
@freezed
abstract class SectorAllocation with _$SectorAllocation {
  const factory SectorAllocation({
    required String sector,
    required double value,
    required double percentage,
    required int holdings,
  }) = _SectorAllocation;

  factory SectorAllocation.fromJson(Map<String, dynamic> json) =>
      _$SectorAllocationFromJson(json);
}

/// Domain entity representing top/worst performers
@freezed
abstract class TopPerformer with _$TopPerformer {
  const factory TopPerformer({
    required String symbol,
    required String companyName,
    required double gainLoss,
    required double gainLossPercentage,
    required double currentValue,
  }) = _TopPerformer;

  factory TopPerformer.fromJson(Map<String, dynamic> json) =>
      _$TopPerformerFromJson(json);
}
