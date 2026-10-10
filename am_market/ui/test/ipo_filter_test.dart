import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:am_market_ui/features/ipo/providers/ipo_providers.dart';
import 'package:flutter_test/flutter_test.dart';

AsraxIpoSummaryDto _ipo({
  required String id,
  String? status,
  String? biddingEndDate,
  String? issueType,
  String? industry,
  String? companyName,
}) {
  return AsraxIpoSummaryDto(
    id: id,
    status: status,
    biddingEndDate: biddingEndDate,
    issueType: issueType,
    industry: industry,
    companyName: companyName,
  );
}

void main() {
  final now = DateTime(2026, 10, 10);
  final today = '2026-10-10';

  group('ipoMatchesFilter — Closing Today', () {
    test('keeps open IPO ending today', () {
      final ipo = _ipo(id: '1', status: 'open', biddingEndDate: today);
      expect(
        ipoMatchesFilter(
          ipo,
          const IpoFilterState(statusFilter: IpoStatusFilter.closingToday),
          now: now,
        ),
        isTrue,
      );
    });

    test('rejects open IPO ending on another day', () {
      final ipo = _ipo(id: '2', status: 'open', biddingEndDate: '2026-10-12');
      expect(
        ipoMatchesFilter(
          ipo,
          const IpoFilterState(statusFilter: IpoStatusFilter.closingToday),
          now: now,
        ),
        isFalse,
      );
    });

    test('rejects upcoming IPO even if end date is today', () {
      final ipo = _ipo(id: '3', status: 'upcoming', biddingEndDate: today);
      expect(
        ipoMatchesFilter(
          ipo,
          const IpoFilterState(statusFilter: IpoStatusFilter.closingToday),
          now: now,
        ),
        isFalse,
      );
    });

    test('accepts datetime-prefixed end date for today', () {
      final ipo = _ipo(
        id: '4',
        status: 'open',
        biddingEndDate: '2026-10-10T17:00:00',
      );
      expect(
        ipoMatchesFilter(
          ipo,
          const IpoFilterState(statusFilter: IpoStatusFilter.closingToday),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('ipoMatchesFilter — Closed includes listed', () {
    test('keeps closed and listed', () {
      expect(
        ipoMatchesFilter(
          _ipo(id: 'c', status: 'closed'),
          const IpoFilterState(statusFilter: IpoStatusFilter.closed),
          now: now,
        ),
        isTrue,
      );
      expect(
        ipoMatchesFilter(
          _ipo(id: 'l', status: 'listed'),
          const IpoFilterState(statusFilter: IpoStatusFilter.closed),
          now: now,
        ),
        isTrue,
      );
      expect(
        ipoMatchesFilter(
          _ipo(id: 'o', status: 'open'),
          const IpoFilterState(statusFilter: IpoStatusFilter.closed),
          now: now,
        ),
        isFalse,
      );
    });
  });

  group('ipoMatchesFilter — board', () {
    test('mainboard-only excludes SME', () {
      expect(
        ipoMatchesFilter(
          _ipo(id: 's', status: 'open', issueType: 'SME'),
          const IpoFilterState(filterMainboard: true),
          now: now,
        ),
        isFalse,
      );
      expect(
        ipoMatchesFilter(
          _ipo(id: 'm', status: 'open', issueType: 'Mainboard'),
          const IpoFilterState(filterMainboard: true),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
