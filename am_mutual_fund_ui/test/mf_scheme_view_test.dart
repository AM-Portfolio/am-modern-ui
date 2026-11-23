import 'package:am_mutual_fund_ui/data/mf_dto.dart';
import 'package:am_mutual_fund_ui/data/mf_scheme_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('seed fallback is identity-only (no client invent NAV/returns)', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AV5',
        'schemeName':
            '360 ONE BALANCED HYBRID FUND - REGULAR PLAN - GROWTH',
        'amcCode': 'IIFLMUTUALFUND_MF',
        'purchaseAllowed': 'Y',
        'source': 'seed-fallback',
      }),
    );
    expect(view.category, 'Hybrid');
    expect(view.option, 'Growth');
    expect(view.nav, isNull);
    expect(view.returnFor('1Y'), isNull);
    expect(view.metricsIllustrative, isTrue);
    expect(view.digPurchaseEnabled, isTrue);
    expect(view.shortName.toUpperCase(), contains('BALANCED HYBRID'));
    expect(view.shortName.toUpperCase(), isNot(contains('GROWTH')));
    expect(view.metaLine, contains('Growth'));
  });

  test('live catalog rows allow invest when purchaseAllowed', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF123A01XYZ',
        'schemeName': 'SOME EQUITY FUND - GROWTH',
        'purchaseAllowed': true,
        'nav': 45.2,
        'navDate': DateTime.now().toIso8601String().substring(0, 10),
        'category': 'Equity',
        'source': 'nse-master',
        'returns': {'1Y': 12.5},
      }),
    );
    expect(view.metricsIllustrative, isFalse);
    expect(view.nav, 45.2);
    expect(view.returnFor('1Y'), 12.5);
    expect(view.digPurchaseEnabled, isTrue);
    expect(view.navStale, isFalse);
    expect(view.navCaption, contains('EOD NAV'));
    expect(view.navCaption.toLowerCase(), isNot(contains('ltp')));
    expect(view.metaLine, contains('Growth'));
  });

  test('stale navDate flags navStale and caption warns', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF123A01XYZ',
        'schemeName': 'SOME EQUITY FUND - GROWTH',
        'nav': 10.0,
        'navDate': '2026-11-05',
        'source': 'nse-master-download',
      }),
    );
    expect(view.navStale, isTrue);
    expect(view.navCaption, contains('stale'));
    expect(view.navCaption.toLowerCase(), contains('not live ltp'));
  });

  test('shortName is clean; Growth/IDCW live in metaLine', () {
    final growth = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AV5',
        'schemeName':
            '360 ONE FLEXICAP FUND - REGULAR PLAN - GROWTH',
        'source': 'nse-master',
      }),
    );
    final idcw = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AW3',
        'schemeName':
            '360 ONE FLEXICAP FUND - REGULAR PLAN - IDCW',
        'source': 'nse-master',
      }),
    );
    expect(growth.shortName.toUpperCase(), contains('FLEXICAP'));
    expect(growth.shortName.toUpperCase(), isNot(contains('REGULAR PLAN')));
    expect(growth.shortName.toUpperCase(), isNot(contains('GROWTH')));
    expect(growth.metaLine, contains('Growth'));
    expect(idcw.metaLine, contains('IDCW'));
    expect(growth.amcLabel.toUpperCase(), contains('360'));
  });

  test('newPurchaseMinAmount maps to minLumpsum; sip only when present', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AV5',
        'schemeName': '360 ONE FLEXICAP FUND - GROWTH',
        'source': 'nse-master',
        'newPurchaseMinAmount': '1000',
      }),
    );
    expect(view.minLumpsum, 1000);
    expect(view.minSip, isNull);

    final withSip = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AV5',
        'schemeName': '360 ONE FLEXICAP FUND - GROWTH',
        'source': 'nse-master',
        'min_investment': 500,
        'sipMinAmount': 100,
      }),
    );
    expect(withSip.minLumpsum, 500);
    expect(withSip.minSip, 100);
  });

  test('aum expenseRatio riskometer and returnsPct map from search payload', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF123HDFC01',
        'schemeName': 'HDFC FLEXI CAP FUND - GROWTH',
        'source': 'nse-master-download',
        'amcName': 'HDFC Mutual Fund',
        'enrichmentSource': 'amfi',
        'sebiCategory': 'Equity',
        'sebiSubCategory': 'Flexi Cap',
        'riskometer': 'VERY HIGH',
        'aum': 25000,
        'expenseRatio': 0.72,
        'newPurchaseMinAmount': '100',
        'returnsPct': {'1Y': 18.2, '3Y': 14.1},
      }),
    );
    expect(view.amcLabel, 'HDFC Mutual Fund');
    expect(view.shortName.toUpperCase(), contains('HDFC'));
    expect(view.category, 'Equity');
    expect(view.subCategory, 'Flexi Cap');
    expect(view.riskLevel, 'VERY HIGH');
    expect(view.aum, 25000);
    expect(view.expenseRatio, 0.72);
    expect(view.displayAum, 25000);
    expect(view.displayExpenseRatio, 0.72);
    expect(view.minLumpsum, 100);
    expect(view.returnFor('1Y'), 18.2);
    expect(view.returnFor('3Y'), 14.1);
  });

  test('exit load face value and cutoff map on detail About helpers', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AV5',
        'schemeName': '360 ONE FLEXICAP FUND - GROWTH',
        'source': 'nse-master-download',
        'exitLoad': '1% if redeemed within 1 year',
        'faceValue': '10',
        'purchaseCutoffTime': '14:30',
        'lockInPeriodFlag': 'Y',
        'lockInPeriod': '3 Years',
        'enrichmentSource': 'amfi',
        'benchmarkName': 'NIFTY 500 TRI',
      }),
    );
    expect(view.exitLoad, contains('1%'));
    expect(view.faceValue, '10');
    expect(view.purchaseCutoffTime, '14:30');
    expect(view.lockInPeriod, '3 Years');
    expect(view.benchmarkName, 'NIFTY 500 TRI');
  });

  test('sample enrichment hides AUM/TER; IIFL code maps to 360 ONE', () {
    final sample = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF579M01AW3',
        'schemeName': '360 ONE BALANCED HYBRID FUND - IDCW',
        'source': 'nse-master-download',
        'amcCode': 'IIFLMUTUALFUND_MF',
        'enrichmentSource': 'sample',
        'aum': 9800,
        'expenseRatio': 0.92,
      }),
    );
    expect(sample.amcLabel, '360 ONE');
    expect(sample.displayAum, isNull);
    expect(sample.displayExpenseRatio, isNull);
  });

  test('dedupeSchemesByIsin prefers Growth non-L1 over IDCW-L1', () {
    MfSchemeView row({
      required String schemeCode,
      required String name,
      required bool purchaseAllowed,
    }) {
      return MfSchemeView.fromSummary(
        MfSchemeSummary.fromJson({
          'isin': 'INF579M01AV5',
          'schemeCode': schemeCode,
          'schemeName': name,
          'purchaseAllowed': purchaseAllowed,
          'source': 'nse-master',
        }),
      );
    }

    final idcwL1 = row(
      schemeCode: 'IIFLMUTUALFUND_MF-L1',
      name: '360 ONE FLEXICAP FUND - REGULAR PLAN - IDCW',
      purchaseAllowed: false,
    );
    final growth = row(
      schemeCode: 'IIFLMUTUALFUND_MF',
      name: '360 ONE FLEXICAP FUND - REGULAR PLAN - GROWTH',
      purchaseAllowed: true,
    );
    final growthL1 = row(
      schemeCode: 'IIFLMUTUALFUND_MF-L1',
      name: '360 ONE FLEXICAP FUND - REGULAR PLAN - GROWTH',
      purchaseAllowed: true,
    );

    final deduped = dedupeSchemesByIsin([idcwL1, growthL1, growth]);
    expect(deduped, hasLength(1));
    expect(deduped.single.schemeCode, 'IIFLMUTUALFUND_MF');
    expect(deduped.single.option.toUpperCase(), 'GROWTH');
    expect(deduped.single.metaLine, contains('Growth'));
  });

  test('IDCW PAYOUT / REINVESTMENT names show distinct metaLine options', () {
    final payout = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF0S5R01109',
        'schemeName':
            'OLD BRIDGE ARBITRAGE FUND - REGULAR PLAN - IDCW PAYOUT',
        'amcCode': '112121',
        'source': 'nse-master',
        'newPurchaseMinAmount': '5000',
      }),
    );
    final reinvest = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF0S5R01117',
        'schemeName':
            'OLD BRIDGE ARBITRAGE FUND - REGULAR PLAN - IDCW REINVESTMENT',
        'amcCode': '112121',
        'source': 'nse-master',
        'newPurchaseMinAmount': '5000',
      }),
    );
    expect(payout.option, 'IDCW Payout');
    expect(payout.metaLine, contains('Payout'));
    expect(reinvest.option, 'IDCW Reinvest');
    expect(reinvest.metaLine, contains('Reinvest'));
    expect(payout.metaLine, isNot(equals(reinvest.metaLine)));
  });

  test('numeric amc_code derives friendly AMC from scheme name', () {
    final view = MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': 'INF0S5R01091',
        'schemeName':
            'OLD BRIDGE ARBITRAGE FUND - REGULAR PLAN - GROWTH',
        'amcCode': '112121',
        'amcName': '112121',
        'source': 'nse-master',
        'newPurchaseMinAmount': '5000',
      }),
    );
    expect(view.amcLabel, isNot('112121'));
    expect(view.amcLabel.toUpperCase(), contains('OLD BRIDGE'));
    expect(view.option, 'Growth');
    expect(view.minLumpsum, 5000);
    expect(MfExploreOptionFilter.growth.matches(view), isTrue);
    expect(MfExploreOptionFilter.idcw.matches(view), isFalse);
  });
}
