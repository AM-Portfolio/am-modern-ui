import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ActivityStatus { win, loss, neutral }

/// dd MMM yyyy — e.g. 06 Aug 2026
String formatActivityDate(DateTime timestamp) {
  return DateFormat('dd MMM yyyy').format(timestamp);
}

/// Average buy price @ quantity — no currency symbol.
String? formatAvgPriceAtQty(double? avgPrice, double? quantity) {
  if (avgPrice == null || quantity == null) return null;
  final priceFmt = NumberFormat('#,##0.00', 'en_IN');
  final qtyFmt = NumberFormat('#,##0', 'en_IN');
  return '${priceFmt.format(avgPrice)} @ ${qtyFmt.format(quantity)}';
}

double? resolveTotalInvested(ActivityItem item) {
  if (item.investmentValue != null) return item.investmentValue;
  if (item.avgBuyingPrice != null && item.quantity != null) {
    return item.avgBuyingPrice! * item.quantity!;
  }
  return null;
}

ActivityStatus resolveStatus(ActivityItem item) {
  final raw = item.status?.toUpperCase().trim();
  if (raw == 'WIN') return ActivityStatus.win;
  if (raw == 'LOSS') return ActivityStatus.loss;
  if (raw == 'NEUTRAL') return ActivityStatus.neutral;

  final pct = item.profitLossPercent;
  if (pct == null) return ActivityStatus.neutral;
  if (pct > 0) return ActivityStatus.win;
  if (pct < 0) return ActivityStatus.loss;
  return ActivityStatus.neutral;
}

String statusLabel(ActivityStatus status) => switch (status) {
      ActivityStatus.win => 'WIN',
      ActivityStatus.loss => 'LOSS',
      ActivityStatus.neutral => 'NEUTRAL',
    };

Color statusAccentColor(BuildContext context, ActivityStatus status) {
  final colors = context.colors;
  return switch (status) {
    ActivityStatus.win => colors.statusSuccess,
    ActivityStatus.loss => colors.statusError,
    ActivityStatus.neutral => colors.textSecondary,
  };
}

String formatReturnPercent(double? pct) {
  if (pct == null) return '—';
  final sign = pct > 0 ? '+' : '';
  return '$sign${pct.toStringAsFixed(2)}%';
}

String formatCurrencyInr(double? value) {
  if (value == null) return '—';
  return NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN')
      .format(value);
}

String formatPnlLine(double? profitLoss) {
  if (profitLoss == null) return 'P&L —';
  final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');
  return 'P&L ${fmt.format(profitLoss)}';
}

String symbolInitial(ActivityItem item) {
  final symbol = (item.symbol ?? item.title).trim();
  if (symbol.isEmpty) return '?';
  return symbol[0].toUpperCase();
}

/// Deterministic purple/navy tint for letter avatars.
Color avatarColorForSymbol(String symbol) {
  const palette = [
    Color(0xFF6C5DD3),
    Color(0xFF5B4EB5),
    Color(0xFF8B7EE0),
    Color(0xFF4A6FA5),
    Color(0xFF7B68EE),
    Color(0xFF5C6BC0),
  ];
  var hash = 0;
  for (final c in symbol.codeUnits) {
    hash = (hash + c) % palette.length;
  }
  return palette[hash];
}
