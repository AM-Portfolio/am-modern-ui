import 'package:am_market_ui/features/ipo/ipo_sorting.dart';
import 'package:am_market_ui/features/ipo/ipo_subscription_sorting.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter_test/flutter_test.dart';

AsraxIpoSummaryDto _ipo({
  required String id,
  required String status,
  String? biddingEndDate,
  String? companyName,
}) {
  return AsraxIpoSummaryDto(
    id: id,
    status: status,
    biddingEndDate: biddingEndDate,
    companyName: companyName ?? id,
  );
}

void main() {
  test('normalizes explicit UTC timestamps to the IST calendar date', () {
    expect(
      ipoIndiaDateKey('2026-11-02T18:30:00Z'),
      '2026-11-03',
    );
  });

  test('puts closing today first, then dates, TBA, and terminal IPOs', () {
    final items = [
      _ipo(id: 'closed', status: 'closed', biddingEndDate: '2026-10-01'),
      _ipo(id: 'tba', status: 'upcoming'),
      _ipo(id: 'future', status: 'upcoming', biddingEndDate: '2026-11-05'),
      _ipo(id: 'today', status: 'open', biddingEndDate: '2026-11-02'),
      _ipo(id: 'tomorrow', status: 'open', biddingEndDate: '2026-11-03'),
    ];

    final sorted = sortIposForAll(
      items,
      now: DateTime(2026, 11, 2),
    );

    expect(sorted.map((item) => item.id).toList(), [
      'today',
      'tomorrow',
      'future',
      'tba',
      'closed',
    ]);
  });

  test('keeps stale nonterminal records before TBA but after closing today',
      () {
    final sorted = sortIposForAll(
      [
        _ipo(id: 'future', status: 'open', biddingEndDate: '2026-11-04'),
        _ipo(id: 'stale', status: 'open', biddingEndDate: '2026-11-01'),
        _ipo(id: 'today', status: 'open', biddingEndDate: '2026-11-02'),
        _ipo(id: 'tba', status: 'upcoming'),
      ],
      now: DateTime(2026, 11, 2),
    );

    expect(sorted.map((item) => item.id).toList(), [
      'today',
      'stale',
      'future',
      'tba',
    ]);
  });

  test('parses subscription multipliers for numeric sorting', () {
    expect(ipoSubscriptionSortValue('0.87'), 0.87);
    expect(ipoSubscriptionSortValue('1.13x'), 1.13);
    expect(ipoSubscriptionSortValue('4.65×'), 4.65);
    expect(ipoSubscriptionSortValue(''), isNull);
    expect(ipoSubscriptionSortValue('N/A'), isNull);
    expect(ipoSubscriptionSortValue('-1.2x'), isNull);
  });
}
