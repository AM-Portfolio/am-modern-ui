import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_financials_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ThemeData testTheme() {
    return ThemeData.dark().copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppColorsTheme.dark,
        MarketThemeExtension.dark(),
      ],
    );
  }

  final mockStatements = [
    {
      'period': 'FY 2026',
      'revenue': 1057219.0,
      'profitAfterTax': 95610.0,
      'operatingProfit': 123162.0,
    },
    {
      'period': 'FY 2025',
      'revenue': 964693.0,
      'profitAfterTax': 80787.0,
      'operatingProfit': 106017.0,
    },
    {
      'period': 'FY 2024',
      'revenue': 901064.0,
      'profitAfterTax': 78633.0,
      'operatingProfit': 104340.0,
    },
    {
      'period': 'FY 2023',
      'revenue': 877835.0,
      'profitAfterTax': 73670.0,
      'operatingProfit': 94046.0,
    },
  ];

  testWidgets('Financial Performance Summary table on mobile layout (390px) renders without overflow and with distinct row spacing', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: testTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(12),
            child: FinancialComparisonSection(
              statements: mockStatements,
              balanceSheets: const [],
              isQuarterly: false,
              periodCount: 4,
              showRevenue: true,
              showPAT: true,
              showPatMargin: false,
              tableOnly: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all 4 period headers exist and are distinct
    expect(find.text('FY26'), findsOneWidget);
    expect(find.text('FY25'), findsOneWidget);
    expect(find.text('FY24'), findsOneWidget);
    expect(find.text('FY23'), findsOneWidget);

    // Verify Revenue and YoY Rev % are visible
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('YoY Rev %'), findsOneWidget);
    expect(find.text('₹1057219'), findsOneWidget);
    expect(find.text('+9.6%'), findsOneWidget);

    // Verify vertical spacing between Revenue and YoY Rev %:
    // Revenue top should be strictly above YoY Rev % top with comfortable space
    final revRect = tester.getRect(find.text('Revenue'));
    final yoyRevRect = tester.getRect(find.text('YoY Rev %'));
    expect(yoyRevRect.top, greaterThanOrEqualTo(revRect.bottom));

    // Verify period values do not overlap:
    final revValRect = tester.getRect(find.text('₹1057219'));
    final yoyValRect = tester.getRect(find.text('+9.6%'));
    expect(yoyValRect.top, greaterThanOrEqualTo(revValRect.bottom));

    // Zero layout overflows
    expect(tester.takeException(), isNull);
  });
}
