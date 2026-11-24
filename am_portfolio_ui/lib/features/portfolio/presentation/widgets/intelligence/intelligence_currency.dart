/// Compact INR display aligned with portfolio allocation widgets (₹ + K/L/Cr).
///
/// Crore uses 2 decimals so book totals stay close to Total Balance
/// (e.g. ₹1,36,68,230 → ₹1.37Cr, not ₹1.4Cr from 1-decimal rounding).
String formatIntelligenceCompactInr(double? value) {
  if (value == null) return '—';
  final abs = value.abs();
  final sign = value < 0 ? '-' : '';
  if (abs >= 10000000) {
    return '$sign₹${(abs / 10000000).toStringAsFixed(2)}Cr';
  }
  if (abs >= 100000) {
    return '$sign₹${(abs / 100000).toStringAsFixed(1)}L';
  }
  if (abs >= 1000) {
    return '$sign₹${(abs / 1000).toStringAsFixed(1)}K';
  }
  return '$sign₹${abs.toStringAsFixed(0)}';
}
