import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/pages/dashboard_users_page.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_refresh_binder.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/persona_card_strip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

const _hub = AccountsHub(
  identity: AccountsIdentity(
    name: 'Munish',
    email: 'ssd2658@gmail.com',
    mobile: 'XXXXXX2257',
  ),
  stats: AccountsStats(
    overallXirrPct: 12.4,
    householdXirrPct: -35.5,
    primaryTotalValue: 2492496,
    householdTotalValue: 3549496,
  ),
  familyMembers: [
    FamilyMemberRow(
      id: 'fm1',
      name: 'Priyanshu Kumar',
      email: 'priyanshukpd@gmail.com',
      portfolioCount: 2,
      source: 'CAS',
      totalValue: 1057000,
      xirrPct: 8.2,
    ),
  ],
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
      portfolioId: 'zerodha-family',
      displayName: 'Zerodha',
      brokerType: 'ZERODHA',
      current: 930000,
      assetCount: 109,
      familyMemberId: 'fm1',
      familyMemberName: 'Priyanshu Kumar',
    ),
    AccountsPortfolioRow(
      portfolioId: 'cdsl-family',
      displayName: 'CDSL CAS',
      brokerType: 'CDSL',
      current: 127000,
      assetCount: 12,
      familyMemberId: 'fm1',
      familyMemberName: 'Priyanshu Kumar',
    ),
  ],
  dematAccounts: [
    DematAccountRow(
      accountNo: 'demat-1',
      accountType: 'demat',
      dpName: 'FYERS SECURITIES',
      boid: '12033201',
      mappedBroker: 'FYERS',
      holdingValue: 113,
      status: 'Active',
      nominee: 'ABHIMANYU KUMAR',
      nomineeRegistered: true,
      email: 'ssd2658@gmail.com',
      mobile: 'XXXXXX2257',
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
    nomineeDetails: 'ABHIMANYU KUMAR 100%',
    registrationDate: '21-Dec-20',
  ),
);

Widget _harness({
  required Size size,
  required Widget child,
}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: ProviderScope(
      overrides: [
        accountsHubProvider('u1').overrideWith((ref) async => _hub),
      ],
      child: MaterialApp(
        theme: _theme(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  testWidgets('1400 web: names, XIRR, table chrome, no Displaying crush',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        size: const Size(1400, 1000),
        child: const DashboardUsersPage(userId: 'u1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.textContaining('Primary Investor Profile'), findsNothing);
    expect(find.textContaining('accounts'), findsWidgets);
    expect(find.textContaining('ABHIMANYU KUMAR 100%'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Priyanshu Kumar'), findsWidgets);
    expect(find.textContaining('XIRR +12.4%'), findsWidgets);
    expect(find.textContaining('XIRR -35.5%'), findsWidgets);
    expect(find.textContaining('XIRR +8.2%'), findsWidgets);
    expect(find.text('+12.4%'), findsWidgets);
    expect(find.byType(Tooltip), findsWidgets);
    expect(find.byType(PersonaCardStrip), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('HOUSEHOLD'), findsOneWidget);
    expect(find.textContaining('Primary Investor Profile'), findsNothing);

    await tester.tap(find.text('Priyanshu Kumar').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Primary Investor Profile'), findsNothing);
    expect(find.textContaining('Family member'), findsNothing);

    await tester.tap(find.text('Munish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Primary Investor Profile'), findsNothing);
    expect(find.textContaining('accounts'), findsWidgets);

    await tester.tap(find.text('Demat (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Total Demat Value'), findsNothing);
    expect(find.text('Linked Demats'), findsNothing);
    expect(find.textContaining('Family'), findsWidgets);

    expect(find.text('All (2)'), findsNothing);
    expect(find.text('Dhan (0)'), findsNothing);
    expect(find.textContaining('Displaying'), findsNothing);

    expect(find.text('Demat Accounts'), findsNothing);
    expect(find.text('Managed CDSL/NSDL'), findsNothing);
    expect(find.text('Table'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('BROKER'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
    expect(find.text('NOMINEE STATUS'), findsOneWidget);
    // Demat directory rows (nominee badge + verified footer).
    expect(find.textContaining('ABHIMANYU'), findsWidgets);
    expect(find.text('No nominee'), findsOneWidget);
    expect(find.textContaining('All CDSL accounts verified via OTP'),
        findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('390 mobile: dropdown, cards-only, selected XIRR', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        size: const Size(390, 844),
        child: const DashboardUsersPage(userId: 'u1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SharedFamilyFilterDropdown), findsOneWidget);
    expect(find.byTooltip('Account type'), findsOneWidget);
    expect(find.byType(PersonaCardStrip), findsNothing);
    expect(find.text('Table'), findsNothing);
    expect(find.text('Card'), findsNothing);
    expect(find.text('XIRR'), findsOneWidget);
    expect(find.text('+12.4%'), findsOneWidget);
    expect(find.textContaining('XIRR +12.4%'), findsNothing);
    expect(find.textContaining('Primary Investor Profile'), findsNothing);
    // Compact header omits account-count label (e.g. "6 accounts").
    expect(find.text('6 accounts'), findsNothing);
    expect(find.text('0 accounts'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('import notify refreshes Users hub via binder', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var loads = 0;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(1400, 1000)),
        child: ProviderScope(
          overrides: [
            accountsHubProvider('u1').overrideWith((ref) async {
              loads++;
              return _hub;
            }),
          ],
          child: MaterialApp(
            theme: _theme(),
            home: const Scaffold(
              body: DashboardPortfolioRefreshBinder(
                userId: 'u1',
                child: DashboardUsersPage(userId: 'u1'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(loads, 1);

    PortfolioDataRefresh.instance.notifyImported();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(loads, greaterThan(1));
  });

  testWidgets('Family tab shows members and tagged books', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _harness(
        size: const Size(1400, 1000),
        child: const DashboardUsersPage(userId: 'u1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Family linking is not available yet.'), findsNothing);
    await tester.ensureVisible(find.text('Family (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Add family member'), findsOneWidget);
    expect(find.text('Priyanshu Kumar'), findsWidgets);
    expect(find.textContaining('priyanshukpd@gmail.com'), findsWidgets);
    expect(find.byTooltip('Edit'), findsWidgets);
    expect(find.byTooltip('Delete'), findsWidgets);
  });
}
