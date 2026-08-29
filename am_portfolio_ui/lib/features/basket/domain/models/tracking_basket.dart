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

  const TrackingBasket({
    required this.basketId,
    this.etfIsin,
    this.etfName,
    this.status = BasketStatus.unknown,
    this.totalLines = 0,
    this.activeLines = 0,
    this.createdAt,
    this.totalValue,
  });

  factory TrackingBasket.fromJson(Map<String, dynamic> json) {
    return TrackingBasket(
      basketId: json['id']?.toString() ?? '',
      etfIsin: json['etfIsin']?.toString(),
      etfName: json['etfName']?.toString() ?? json['name']?.toString(),
      status: BasketStatus.fromString(json['status']?.toString()),
      totalLines: (json['assetCount'] as num?)?.toInt() ?? 0,
      activeLines: ((json['assetCount'] as num?)?.toInt() ?? 0) - ((json['gapMissingCount'] as num?)?.toInt() ?? 0),
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      totalValue: (json['totalValue'] as num?)?.toDouble(),
    );
  }

  // Derived helpers
  double get fillPercent => totalLines == 0 ? 0.0 : (activeLines / totalLines) * 100.0;
  bool get isUnderfunded => status == BasketStatus.partially_filled;
}
