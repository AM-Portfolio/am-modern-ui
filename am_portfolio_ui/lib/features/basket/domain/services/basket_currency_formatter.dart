import 'package:intl/intl.dart';

/// Shared INR formatting for basket screens.
class BasketCurrencyFormatter {
  BasketCurrencyFormatter._();

  static final NumberFormat _inr =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  /// Formats a rupee amount using Indian locale grouping (no decimals).
  static String formatInr(double amount) => _inr.format(amount);
}
