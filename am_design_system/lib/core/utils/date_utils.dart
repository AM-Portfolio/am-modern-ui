import 'package:intl/intl.dart';

/// Pure, stateless date utility functions
class DateUtils {
  static final DateFormat _shortFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _longFormat = DateFormat('MMMM dd, yyyy HH:mm');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _apiFormat = DateFormat('yyyy-MM-ddTHH:mm:ss');

  /// Format date to short format (e.g., "Jan 15, 2024")
  static String formatShort(DateTime date) => _shortFormat.format(date);

  /// Format date to long format (e.g., "January 15, 2024 14:30")
  static String formatLong(DateTime date) => _longFormat.format(date);

  /// Format time only (e.g., "14:30")
  static String formatTime(DateTime date) => _timeFormat.format(date);

  /// Format date for API calls
  static String formatForApi(DateTime date) => _apiFormat.format(date);

  /// Parse API date string
  static DateTime parseFromApi(String dateString) =>
      _apiFormat.parse(dateString);

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  /// Get relative time string (e.g., "2 hours ago", "Yesterday", "Jan 15")
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return formatShort(date);
    }
  }

  /// Get start of day
  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Get end of day
  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

  /// Get start of week (Monday)
  static DateTime startOfWeek(DateTime date) {
    final difference = date.weekday - 1;
    return startOfDay(date.subtract(Duration(days: difference)));
  }

  /// Get end of week (Sunday)
  static DateTime endOfWeek(DateTime date) {
    final difference = 7 - date.weekday;
    return endOfDay(date.add(Duration(days: difference)));
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month);

  /// Get end of month
  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
}
