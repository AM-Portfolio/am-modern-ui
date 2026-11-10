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
      holdingValue: 100000,
      status: 'Active',
    ),
  ],
  nps: NpsMetaRow(
    pran: '123456789012',
    totalValue: 50000,
  ),
);

Future<ProviderContainer> _pumpUsers(WidgetTester tester) async {
  tester.view.physicalSize = const Size(480, 900);
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
            width: 420,
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
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Family'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.textContaining('Family 60% of portfolio'), findsNothing);
    expect(find.textContaining('+10.2%'), findsOneWidget);
    expect(find.textContaining('+8.1%'), findsOneWidget);
    // Persona role icons removed on hub; Family tab still uses groups icon.
    expect(find.byIcon(Icons.work_outline_rounded), findsNothing);
    expect(find.text('Search mapped accounts...'), findsNothing);
    expect(find.textContaining('Mapped Accounts'), findsOneWidget);
    expect(find.textContaining('Nominee'), findsNothing);

    await tester.drag(
      find.byKey(const Key('persona-card-strip-scroll')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Priyanshu'), findsWidgets);
    expect(find.textContaining('+12.5%'), findsOneWidget);

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

    await tester.drag(
      find.byKey(const Key('persona-card-strip-scroll')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Priyanshu').first);
    await tester.pumpAndSettle();
    expect(container.read(familyPortfolioFilterProvider), 'fm1');

    await tester.drag(
      find.byKey(const Key('persona-card-strip-scroll')),
      const Offset(240, 0),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('All').first);
    await tester.tap(find.text('All').first);
    await tester.pumpAndSettle();
    expect(
      container.read(familyPortfolioFilterProvider),
      FavoritePersonaStore.kAll,
    );
  });

  testWidgets('Overview shows Mapped Accounts without nominee section',
      (tester) async {
    await _pumpUsers(tester);
    expect(find.textContaining('Mapped Accounts'), findsOneWidget);
    expect(find.text('Zerodha'), findsWidgets);
    expect(find.text('NPS'), findsWidgets);
    expect(find.textContaining('Nominee details'), findsNothing);
    expect(find.text('Broker'), findsWidgets);
  });
}
