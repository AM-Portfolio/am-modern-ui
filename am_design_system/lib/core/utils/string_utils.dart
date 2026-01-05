import 'dart:math' as math;

/// Pure, stateless string utility functions
class StringUtils {
  /// Capitalize first letter of each word
  static String toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  /// Capitalize first letter only
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Truncate text with ellipsis
  static String truncate(String text, int maxLength, {String suffix = '...'}) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength - suffix.length) + suffix;
  }

  /// Remove extra whitespace and normalize spacing
  static String normalizeWhitespace(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Check if string is null or empty
  static bool isNullOrEmpty(String? text) => text == null || text.isEmpty;

  /// Check if string is null, empty, or just whitespace
  static bool isNullOrWhitespace(String? text) =>
      text == null || text.trim().isEmpty;

  /// Format currency with symbol
  static String formatCurrency(
    double amount, {
    String symbol = '₹',
    int decimals = 2,
  }) {
    if (amount.isNaN || amount.isInfinite) return '$symbol 0.00';

    final isNegative = amount < 0;
    final absAmount = amount.abs();

    String formatted;
    if (absAmount >= 10000000) {
      // 1 crore
      formatted = '${(absAmount / 10000000).toStringAsFixed(2)}Cr';
    } else if (absAmount >= 100000) {
      // 1 lakh
      formatted = '${(absAmount / 100000).toStringAsFixed(2)}L';
    } else if (absAmount >= 1000) {
      // 1 thousand
      formatted = '${(absAmount / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = absAmount.toStringAsFixed(decimals);
    }

    return '${isNegative ? '-' : ''}$symbol$formatted';
  }

  /// Format percentage
  static String formatPercentage(double percentage, {int decimals = 2}) {
    if (percentage.isNaN || percentage.isInfinite) return '0.00%';
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  /// Format large numbers with Indian numbering system
  static String formatNumber(double number, {int decimals = 2}) {
    if (number.isNaN || number.isInfinite) return '0';

    final isNegative = number < 0;
    final absNumber = number.abs();

    String formatted;
    if (absNumber >= 10000000) {
      // 1 crore
      formatted = '${(absNumber / 10000000).toStringAsFixed(decimals)}Cr';
    } else if (absNumber >= 100000) {
      // 1 lakh
      formatted = '${(absNumber / 100000).toStringAsFixed(decimals)}L';
    } else if (absNumber >= 1000) {
      // 1 thousand
      formatted = '${(absNumber / 1000).toStringAsFixed(1)}K';
    } else {
      formatted = absNumber.toStringAsFixed(decimals);
    }

    return '${isNegative ? '-' : ''}$formatted';
  }

  /// Generate random string
  static String generateRandomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = math.Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Validate email format
  static bool isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  /// Validate phone number (Indian format)
  static bool isValidPhoneNumber(String phone) =>
      RegExp(r'^[6-9]\d{9}$').hasMatch(phone);

  /// Extract initials from name
  static String getInitials(String name, {int maxInitials = 2}) {
    if (name.isEmpty) return '';

    final words = name.trim().split(' ');
    final initials = words
        .take(maxInitials)
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .join();

    return initials;
  }

  /// Mask sensitive data (e.g., phone, email)
  static String maskString(
    String text, {
    int visibleStart = 2,
    int visibleEnd = 2,
  }) {
    if (text.length <= visibleStart + visibleEnd) return text;

    final start = text.substring(0, visibleStart);
    final end = text.substring(text.length - visibleEnd);
    final masked = '*' * (text.length - visibleStart - visibleEnd);

    return '$start$masked$end';
  }

  /// Convert snake_case to camelCase
  static String snakeToCamelCase(String snakeCase) =>
      snakeCase.split('_').asMap().entries.map((entry) {
        final index = entry.key;
        final word = entry.value;
        return index == 0 ? word : capitalize(word);
      }).join();

  /// Convert camelCase to snake_case
  static String camelToSnakeCase(String camelCase) =>
      camelCase.replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
}
