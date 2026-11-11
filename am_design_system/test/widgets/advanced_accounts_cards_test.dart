import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

const _accounts = [
  AdvancedAccountRow(
    id: 'b1',
    type: 'broker',
    title: 'Groww',
    broker: 'GROWW',
    subtitle: 'GROWW · 5 assets',
    value: 1831,
    hasValue: true,
    statusKind: AccountStatusKind.active,
    weightPct: 98,
  ),
  AdvancedAccountRow(
    id: 'd1',
    type: 'demat',
    title: 'ANGEL ONE LIMITED',
    broker: 'ANGEL_ONE',
    subtitle: 'Depository: CDSL · DP 12088702',
    value: 0,
    hasValue: true,
    nomineeMissing: true,
    nominee: 'No nominee',
    statusKind: AccountStatusKind.active,
    weightPct: 0,
  ),
];

void main() {
  testWidgets('horizontal cards: letter tile, Active, no nominee pill',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 844)),
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: AdvancedAccountsCards(
              accounts: _accounts,
              isDarkChrome: true,
              accent: ModuleColors.dashboard,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Broker'), findsOneWidget);
    expect(find.text('Demat'), findsOneWidget);
    expect(find.text('Groww'), findsOneWidget);
    expect(find.text('ANGEL ONE LIMITED'), findsOneWidget);
    expect(find.textContaining('₹1,831'), findsOneWidget);
    expect(find.text('98%'), findsOneWidget);
    expect(find.text('G'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Active'), findsNWidgets(2));
    expect(find.text('No nominee'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('advancedAccountTileLetter falls back to title when broker missing', () {
    const row = AdvancedAccountRow(
      id: 'x',
      type: 'nps',
      title: 'PRAN 123',
      statusKind: AccountStatusKind.active,
    );
    expect(advancedAccountTileLetter(row), 'P');
  });
}
