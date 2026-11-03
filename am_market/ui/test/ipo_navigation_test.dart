import 'package:am_market_ui/features/ipo/ipo_navigation.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter_test/flutter_test.dart';

AsraxIpoSummaryDto _ipo({
  String? biddingStartDate,
  String? biddingEndDate,
}) {
  return AsraxIpoSummaryDto(
    id: 'ipo-id',
    biddingStartDate: biddingStartDate,
    biddingEndDate: biddingEndDate,
  );
}

void main() {
  test('allows details only when both bidding dates are supplied', () {
    expect(
      ipoHasAnnouncedBiddingDates(
        _ipo(
          biddingStartDate: '2026-11-02',
          biddingEndDate: '2026-11-04',
        ),
      ),
      isTrue,
    );
  });

  test('blocks an IPO when either bidding date is missing', () {
    expect(
      ipoHasAnnouncedBiddingDates(
        _ipo(biddingEndDate: '2026-11-04'),
      ),
      isFalse,
    );
    expect(
      ipoHasAnnouncedBiddingDates(
        _ipo(biddingStartDate: '2026-11-02'),
      ),
      isFalse,
    );
    expect(ipoHasAnnouncedBiddingDates(_ipo()), isFalse);
  });

  test('treats whitespace-only dates as not announced', () {
    expect(
      ipoHasAnnouncedBiddingDates(
        _ipo(
          biddingStartDate: '  ',
          biddingEndDate: '2026-11-04',
        ),
      ),
      isFalse,
    );
  });
}
