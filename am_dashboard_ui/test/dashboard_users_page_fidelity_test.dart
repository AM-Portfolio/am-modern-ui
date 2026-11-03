import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/pages/dashboard_users_page.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
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

void main() {
  testWidgets('Demat tab shows header KPIs, zero-count swatch, table chrome',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountsHubProvider('u1').overrideWith((ref) async => _hub),
        ],
        child: MaterialApp(
          theme: _theme(),
          home: const Scaffold(
            body: DashboardUsersPage(userId: 'u1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
    expect(find.textContaining('Primary Investor Profile'), findsOneWidget);
    expect(find.textContaining('ABHIMANYU KUMAR 100%'), findsWidgets);

    await tester.tap(find.text('Demat (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Total Demat Value'), findsOneWidget);
    expect(find.text('Linked Demats'), findsOneWidget);
    expect(find.text('2 Accounts'), findsOneWidget);
    expect(find.text('Nominee Audits'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 action needed'), findsOneWidget);

    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Dhan (0)'), findsOneWidget);
    expect(find.textContaining('Displaying 2 active accounts mapped'),
        findsOneWidget);

    expect(find.text('Demat Accounts'), findsNothing);
    expect(find.text('Managed CDSL/NSDL'), findsNothing);
    expect(find.text('Table'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('TYPE'), findsOneWidget);
    expect(find.text('NOMINEE STATUS'), findsOneWidget);
    expect(find.text('No nominee'), findsOneWidget);
    expect(find.textContaining('All CDSL accounts verified via OTP'),
        findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
