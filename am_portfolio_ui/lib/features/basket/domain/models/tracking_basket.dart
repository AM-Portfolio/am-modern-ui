import 'package:flutter/foundation.dart';
import 'basket_enums.dart';

@immutable
class TrackingBasket {
  final String basketId;
  final String? etfIsin;
  final String? etfName;
  final BasketStatus status;
  final int totalLines;
  final int activeLines;
  final DateTime? createdAt;
  final double? totalValue;
  final double? investmentAmount;
  final double? totalPnL;
  final double? pnlPercent;
  final double? replicaScore;
  final double? coveragePercent;

  const TrackingBasket({
    required this.basketId,
    this.etfIsin,
    this.etfName,
    this.status = BasketStatus.unknown,
    this.totalLines = 0,
    this.activeLines = 0,
    this.createdAt,
    this.totalValue,
    this.investmentAmount,
    this.totalPnL,
    this.pnlPercent,
    this.replicaScore,
    this.coveragePercent,
  });

  factory TrackingBasket.fromJson(Map<String, dynamic> json) {
    final invested = (json['investmentAmount'] as num?)?.toDouble();
    final current = (json['totalValue'] as num?)?.toDouble();
    final pnlFromApi = (json['totalPnL'] as num?)?.toDouble();
    final pnlPctFromApi = (json['pnlPercent'] as num?)?.toDouble();
    final derivedPnl = (pnlFromApi == null && invested != null && current != null)
        ? current - invested
        : pnlFromApi;
    final derivedPnlPct = (pnlPctFromApi == null &&
            invested != null &&
            invested > 0 &&
            derivedPnl != null)
        ? (derivedPnl / invested) * 100.0
        : pnlPctFromApi;

    return TrackingBasket(
      basketId: json['id']?.toString() ?? '',
      etfIsin: json['etfIsin']?.toString(),
      etfName: json['etfName']?.toString() ?? json['name']?.toString(),
      status: BasketStatus.fromString(json['status']?.toString()),
      totalLines: (json['assetCount'] as num?)?.toInt() ?? 0,
      activeLines: ((json['assetCount'] as num?)?.toInt() ?? 0) -
          ((json['gapMissingCount'] as num?)?.toInt() ?? 0),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      totalValue: current,
      investmentAmount: invested,
      totalPnL: derivedPnl,
      pnlPercent: derivedPnlPct,
      replicaScore: (json['replicaScore'] as num?)?.toDouble(),
      coveragePercent: (json['coveragePercent'] as num?)?.toDouble(),
    );
  }

  /// Prefer replica / coverage from API; fall back to line fill ratio.
  double get displayCoveragePercent {
    if (replicaScore != null && replicaScore! > 0) return replicaScore!;
    if (coveragePercent != null && coveragePercent! > 0) return coveragePercent!;
    return fillPercent;
  }

  // Derived helpers
  double get fillPercent =>
      totalLines == 0 ? 0.0 : (activeLines / totalLines) * 100.0;
  bool get isUnderfunded => status == BasketStatus.partially_filled;
}
