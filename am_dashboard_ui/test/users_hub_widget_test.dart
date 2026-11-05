import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_accounts_hub_widget.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

const _fixtureHub = AccountsHub(
  identity: AccountsIdentity(
    name: 'Test User',
    email: 'test@example.com',
  ),
  stats: AccountsStats(
    activeDematCount: 1,
    mfFolioCount: 2,
    brokerPortfolioCount: 1,
    npsLinked: true,
    overallXirrPct: 8.1,
    householdXirrPct: 10.2,
    primaryTotalValue: 400000,
    householdTotalValue: 1000000,
    familySharePct: 60,
  ),
  familyMembers: [
    FamilyMemberRow(
      id: 'fm1',
      name: 'Priyanshu',
      portfolioCount: 1,
      totalValue: 600000,
      xirrPct: 12.5,
    ),
  ],
  portfolios: [
    AccountsPortfolioRow(
      portfolioId: 'p1',
      displayName: 'Zerodha',
      brokerType: 'ZERODHA',
      current: 100000,
      assetCount: 3,
    ),
  ],
  dematAccounts: [
    DematAccountRow(
      accountNo: '123',
      accountType: 'demat',
      dpName: 'Zerodha DP',
      mappedBroker: 'ZERODHA',
    ),
  ],
  nps: NpsMetaRow(
    pran: '123456789012',
    totalValue: 50000,
  ),
);

Future<ProviderContainer> _pumpUsers(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer(
    overrides: [
      accountsHubProvider('u1').overrideWith((ref) async => _fixtureHub),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _theme(),
        home: const Scaffold(
          body: SizedBox(
            height: 700,
            child: DashboardUsersHubWidget(userId: 'u1'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('accountsHub peer label is Users', () {
    expect(DashboardWidgetId.accountsHub.label, 'Users');
  });

  testWidgets('persona cards show All You and family; Family tab lists member',
      (tester) async {
    await _pumpUsers(tester);
    expect(find.text('USERS'), findsOneWidget);
    expect(find.text('test@example.com'), findsNothing);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Household'), findsOneWidget);
    expect(find.text('Priyanshu'), findsWidgets);
    expect(find.widgetWithText(ChoiceChip, 'Overview'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Family'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Broker (1)'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'NPS (1)'), findsNothing);
    expect(find.textContaining('Family 60% of portfolio'), findsNothing);
    expect(find.textContaining('Demat 1'), findsNothing);
    expect(find.textContaining('XIRR +10.2%'), findsOneWidget);
    expect(find.textContaining('XIRR +8.1%'), findsOneWidget);
    expect(find.textContaining('XIRR +12.5%'), findsOneWidget);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Priyanshu'), findsWidgets);
  });

  testWidgets('selecting persona card syncs familyPortfolioFilterProvider',
      (tester) async {
    final container = await _pumpUsers(tester);
    expect(
      container.read(familyPortfolioFilterProvider),
      FavoritePersonaStore.kAll,
    );

    await tester.tap(find.text('Priyanshu').first);
    await tester.pumpAndSettle();
    expect(container.read(familyPortfolioFilterProvider), 'fm1');

    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(
      container.read(familyPortfolioFilterProvider),
      FavoritePersonaStore.kAll,
    );
  });

  testWidgets('Overview shows NPS strip without Broker/NPS tabs', (tester) async {
    await _pumpUsers(tester);
    expect(find.byKey(const Key('users_nps_strip')), findsOneWidget);
    expect(find.text('Zerodha'), findsWidgets);
    expect(find.widgetWithText(ChoiceChip, 'Broker (1)'), findsNothing);
  });
}
