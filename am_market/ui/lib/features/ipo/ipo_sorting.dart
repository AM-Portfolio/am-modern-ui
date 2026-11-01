import 'package:am_market_ui/features/ipo/models/ipo_models.dart';

const _indiaOffset = Duration(hours: 5, minutes: 30);
final _datePrefixPattern = RegExp(r'^\d{4}-\d{2}-\d{2}');
final _explicitZonePattern = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// Returns a market-local ISO date for an API date/timestamp.
///
/// Date-only and timezone-less API values are already treated as market dates;
/// explicit-offset timestamps are converted to Asia/Kolkata before comparison.
String? ipoIndiaDateKey(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  final prefix = _datePrefixPattern.firstMatch(value)?.group(0);
  if (prefix == null) return null;

  final parts = prefix.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.any((part) => part == null)) return null;
  final date = DateTime.utc(parts[0]!, parts[1]!, parts[2]!);
  if (date.year != parts[0] || date.month != parts[1] || date.day != parts[2]) {
    return null;
  }

  if (!_explicitZonePattern.hasMatch(value)) return prefix;

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return _formatDate(parsed.toUtc().add(_indiaOffset));
}

/// Produces today's date in the market timezone.
///
/// An explicit non-UTC clock is treated as already market-local so unit tests
/// can pass a deterministic wall-clock value. Production calls use UTC plus
/// India's fixed offset, which avoids browser/device timezone differences.
String ipoTodayIndiaDateKey({DateTime? now}) {
  final marketNow = now == null
      ? DateTime.now().toUtc().add(_indiaOffset)
      : now.isUtc
          ? now.toUtc().add(_indiaOffset)
          : now;
  return _formatDate(marketNow);
}

/// Applies the IPO landing-page lifecycle ordering without mutating [items].
///
/// Closing today is first, followed by all other non-terminal IPOs with valid
/// close dates, then missing/invalid dates, and terminal records last.
List<AsraxIpoSummaryDto> sortIposForAll(
  Iterable<AsraxIpoSummaryDto> items, {
  DateTime? now,
}) {
  final today = ipoTodayIndiaDateKey(now: now);
  final sorted = List<AsraxIpoSummaryDto>.from(items);
  sorted.sort((a, b) {
    final aRank = _orderRank(a, today);
    final bRank = _orderRank(b, today);
    if (aRank != bRank) return aRank.compareTo(bRank);

    final aDate = ipoIndiaDateKey(a.biddingEndDate);
    final bDate = ipoIndiaDateKey(b.biddingEndDate);
    if (aRank == 1 && aDate != bDate) {
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      final dateResult = aDate.compareTo(bDate);
      if (dateResult != 0) return dateResult;
    }

    final nameResult = _displayName(a).toLowerCase().compareTo(
          _displayName(b).toLowerCase(),
        );
    if (nameResult != 0) return nameResult;
    return a.id.compareTo(b.id);
  });
  return sorted;
}

bool _isTerminal(AsraxIpoSummaryDto ipo) {
  final status = (ipo.status ?? '').trim().toLowerCase();
  return status == 'closed' || status == 'listed';
}

int _orderRank(AsraxIpoSummaryDto ipo, String today) {
  if (_isTerminal(ipo)) return 3;

  final status = (ipo.status ?? '').trim().toLowerCase();
  final date = ipoIndiaDateKey(ipo.biddingEndDate);
  if (status == 'open' && date == today) return 0;
  if (date != null) return 1;
  return 2;
}

String _displayName(AsraxIpoSummaryDto ipo) =>
    (ipo.companyName?.trim().isNotEmpty == true
        ? ipo.companyName!.trim()
        : ipo.symbol?.trim().isNotEmpty == true
            ? ipo.symbol!.trim()
            : ipo.id.trim());

String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
