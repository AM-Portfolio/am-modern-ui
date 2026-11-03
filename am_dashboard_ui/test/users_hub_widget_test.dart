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
  ),
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

Future<void> _pumpUsers(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountsHubProvider('u1').overrideWith((ref) async => _fixtureHub),
      ],
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
}

void main() {
  test('accountsHub peer label is Users', () {
    expect(DashboardWidgetId.accountsHub.label, 'Users');
  });

  testWidgets('Family tab shows Add family member CTA', (tester) async {
    await _pumpUsers(tester);
    expect(find.text('USERS'), findsOneWidget);
    expect(find.text('test@example.com'), findsNothing);
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    expect(find.text('Add family member'), findsOneWidget);
    expect(find.text('No family members yet'), findsOneWidget);
  });

  testWidgets('NPS strip is not under Brokers tab', (tester) async {
    await _pumpUsers(tester);
    // Overview may show NPS.
    expect(find.byKey(const Key('users_nps_strip')), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Broker (1)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('users_nps_strip')), findsNothing);
    expect(find.text('Zerodha'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'NPS (1)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('users_nps_strip')), findsOneWidget);
  });
}
