import 'dart:math' as math;

/// Parses the backend subscription multiplier for numeric table sorting.
///
/// The API may provide values such as `0.87`, `0.87x`, or `0.87×`.
/// Missing, malformed, negative, and non-finite values are unavailable and
/// should be placed after valid values by the shared table comparator.
double? ipoSubscriptionSortValue(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final normalized = value.replaceAll(RegExp(r'[xX×]'), '').trim();
  final parsed = double.tryParse(normalized);
  if (parsed == null || !parsed.isFinite || parsed < 0) return null;
  return parsed;
}

/// Dynamic meter ceiling so high-demand IPOs (150x–400x+) do not clamp at 100.
double ipoSubscriptionMeterMax(double subscription) {
  final safe = subscription.isFinite ? math.max(0.0, subscription) : 0.0;
  return math.max(100.0, ((safe / 50).ceil() * 50).toDouble());
}
