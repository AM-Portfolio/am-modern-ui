import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/mappers/advanced_account_row_mapper.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _hub = AccountsHub(
  identity: AccountsIdentity(name: 'Munish', email: 'ssd2658@gmail.com'),
  portfolios: [
    AccountsPortfolioRow(
      portfolioId: 'fyers-1',
      displayName: 'Fyers',
      brokerType: 'FYERS',
      current: 113,
      assetCount: 1,
    ),
    AccountsPortfolioRow(
      portfolioId: 'groww-1',
      displayName: 'Groww',
      brokerType: 'GROWW',
      current: 29674,
      assetCount: 4,
    ),
    AccountsPortfolioRow(
      portfolioId: 'dhan-1',
      displayName: 'Dhan',
      brokerType: 'DHAN',
      current: 2462709,
      assetCount: 86,
    ),
    AccountsPortfolioRow(
      portfolioId: 'cdsl-agg',
      displayName: 'CDSL',
      brokerType: 'CDSL',
      current: 999,
      assetCount: 10,
    ),
  ],
  dematAccounts: [
    DematAccountRow(
      accountNo: 'folio-1',
      accountType: 'mf',
      folio: '910162484964/0',
      amcName: 'Motilal Oswal MF',
      email: 'ssd2658@gmail.com',
      mobile: 'XXXXXX2257',
      nominee: 'Please Nominate',
      nomineeRegistered: false,
      holdingValue: 9005,
      status: 'Active',
      mappedBroker: 'GROWW',
    ),
    DematAccountRow(
      accountNo: 'demat-1',
      accountType: 'demat',
      dpName: 'FYERS SECURITIES PRIVATE LIMITED',
      boid: '12033201',
      mappedBroker: 'FYERS',
      holdingValue: 113,
      status: 'Active',
      nominee: 'ABHIMANYU KUMAR',
      nomineeRegistered: true,
    ),
    DematAccountRow(
      accountNo: 'demat-2',
      accountType: 'demat',
      dpName: 'GROWW DP',
      boid: '12081600',
      mappedBroker: 'GROWW',
      holdingValue: 500,
      status: 'Active',
      nomineeRegistered: false,
      nominee: 'Not Registered',
    ),
  ],
  nps: NpsMetaRow(
    pran: '110115289881',
    totalValue: 937908,
    nomineeDetails: 'ABHIMANYU KUMAR (100%)',
    registrationDate: '21-Dec-20',
  ),
);

void main() {
  test('mapper maps brokers MF demat NPS and skips CDSL aggregator', () {
    final brokers = _hub.portfolios.where((p) => p.isRunningBroker).toList();
    final mf = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
        .toList();
    final demat = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();

    final rows = mapAccountsHubToAdvancedRows(
      brokers: brokers,
      mf: mf,
      demat: demat,
      hub: _hub,
      hasNps: true,
    );

    expect(rows.where((r) => r.type == 'broker').map((r) => r.title),
        containsAll(['Fyers', 'Groww', 'Dhan']));
    expect(rows.any((r) => r.title == 'CDSL'), isFalse);

    final folio = rows.firstWhere((r) => r.type == 'mf');
    expect(folio.title, contains('910162484964/0'));
    expect(folio.displayNominee, 'No nominee');
    expect(folio.nomineeMissing, isTrue);
    expect(folio.hasValue, isTrue);
    expect(folio.statusKind, AccountStatusKind.active);

    final dematRow = rows.firstWhere((r) => r.accountId == '12033201');
    expect(dematRow.broker, 'FYERS');
    expect(dematRow.subtitle, contains('Depository: CDSL'));
    expect(dematRow.nomineeMissing, isFalse);

    final nps = rows.firstWhere((r) => r.type == 'nps');
    expect(nps.accountId, '110115289881');
    expect(nps.value, 937908);
  });

  test('mapper sets weightPct from scope total; subtitle has no %', () {
    final brokers = _hub.portfolios.where((p) => p.isRunningBroker).toList();
    final mf = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
        .toList();
    final demat = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();
    const scope = 1000000.0;
    final rows = mapAccountsHubToAdvancedRows(
      brokers: brokers,
      mf: mf,
      demat: demat,
      hub: _hub,
      hasNps: true,
      scopeTotalValue: scope,
      includeFamilySummaries: false,
    );
    final dhan = rows.firstWhere((r) => r.title == 'Dhan');
    expect(dhan.weightPct, closeTo(246.2709, 0.01));
    expect(dhan.displayWeightPct, '246%');
    expect(dhan.subtitle ?? '', isNot(contains('%')));

    final dematRow = rows.firstWhere((r) => r.accountId == '12033201');
    expect(dematRow.weightPct, closeTo(0.0113, 0.0001));
    expect(dematRow.subtitle ?? '', isNot(contains('%')));
  });

  test('displayBroker falls back to first word of title', () {
    expect(
      AdvancedAccountRow.firstWordOfTitle('Dhan Equity'),
      'DHAN',
    );
    final row = AdvancedAccountRow(
      id: 'x',
      type: 'demat',
      title: 'Groww Demat 1208',
      value: 1,
      hasValue: true,
    );
    expect(row.displayBroker, 'GROWW');
    expect(row.displayWeightPct, '');
  });

  test('tab and broker filters intersect', () {
    final brokers = _hub.portfolios.where((p) => p.isRunningBroker).toList();
    final mf = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
        .toList();
    final demat = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();
    final all = mapAccountsHubToAdvancedRows(
      brokers: brokers,
      mf: mf,
      demat: demat,
      hub: _hub,
      hasNps: true,
    );

    final brokersOnly =
        filterAdvancedAccountRowsByTab(rows: all, tab: 'brokers');
    expect(brokersOnly.every((r) => r.type == 'broker'), isTrue);
    expect(brokersOnly.length, 3);

    final fyers = filterAdvancedAccountRowsByBroker(
      rows: all,
      brokerFilter: 'FYERS',
    );
    expect(fyers.map((r) => r.type), containsAll(['broker', 'demat']));
    expect(fyers.every((r) {
      final key = (r.broker ?? r.title).toUpperCase();
      return key == 'FYERS' || r.title.toUpperCase() == 'FYERS';
    }), isTrue);
  });

  test('swatch counts include zero-count running brokers on Demat tab', () {
    final brokers = _hub.portfolios.where((p) => p.isRunningBroker).toList();
    final mf = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() == 'mf')
        .toList();
    final demat = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();

    final options = buildBrokerSwatchOptions(
      runningBrokers: brokers,
      demat: demat,
      mf: mf,
      tab: 'demat',
    );

    expect(options.first.key, 'all');
    expect(options.first.count, 2);

    final byKey = {for (final o in options) o.key: o.count};
    expect(byKey['FYERS'], 1);
    expect(byKey['GROWW'], 1);
    expect(byKey['DHAN'], 0);
  });

  test('nominee audit stats for demat rows', () {
    final demat = _hub.dematAccounts
        .where((a) => (a.accountType ?? '').toLowerCase() != 'mf')
        .toList();
    final stats = dematNomineeStats(demat);
    expect(stats.linkedCount, 2);
    expect(stats.nomineeOk, 1);
    expect(stats.nomineeMissing, 1);
    expect(stats.brokersActive, 2);
    expect(stats.totalValue, 613);
  });

  testWidgets('AdvancedAccountsTemplate renders empty and table states',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvancedAccountsTemplate(
            accounts: const [],
            isLoading: false,
            emptyTitle: 'No rows for this view',
            toolbarLeading: const Text('Overview'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No rows for this view'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    final rows = mapAccountsHubToAdvancedRows(
      brokers: _hub.portfolios.where((p) => p.isRunningBroker).toList(),
      mf: const [],
      demat: const [],
      hub: _hub,
      hasNps: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: AdvancedAccountsTemplate(
              accounts: rows,
              isLoading: false,
              sectionTitle: 'Brokers',
              footerNoun: 'broker accounts',
              footerCenterNote: null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fyers'), findsWidgets);
    expect(find.text('TYPE'), findsOneWidget);
    expect(find.text('ACCOUNT LEGAL NAME'), findsOneWidget);
    expect(find.textContaining('Showing'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
