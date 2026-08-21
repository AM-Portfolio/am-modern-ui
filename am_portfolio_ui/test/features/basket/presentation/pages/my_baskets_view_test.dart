import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/my_baskets_view.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/tracking_basket.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_enums.dart';
import 'package:am_portfolio_ui/features/basket/presentation/providers/basket_providers.dart';
import 'package:am_design_system/am_design_system.dart';

void main() {
  testWidgets('MyBasketsView shows empty state when no baskets', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBasketsProvider.overrideWith((ref, args) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MyBasketsView(userId: 'test_user', portfolioId: 'test_portfolio'),
          ),
        ),
      ),
    );

    // Initial load
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    
    // Pump to settle
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('No Baskets Tracked'), findsOneWidget);
    expect(find.byIcon(Icons.shopping_basket_outlined), findsOneWidget);
  });

  testWidgets('MyBasketsView shows baskets when available', (tester) async {
    final mockBaskets = [
      const TrackingBasket(
        basketId: '1',
        etfName: 'Tech ETF',
        status: BasketStatus.completed,
      ),
      const TrackingBasket(
        basketId: '2',
        etfName: 'Finance ETF',
        status: BasketStatus.partially_filled,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myBasketsProvider.overrideWith((ref, args) async => mockBaskets),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: MyBasketsView(userId: 'test_user', portfolioId: 'test_portfolio'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify list rendering
    expect(find.text('Tech ETF'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('Finance ETF'), findsOneWidget);
    expect(find.text('UNDERFUNDED'), findsOneWidget);
    // Feature "Retry Gap" button for underfunded is not implemented yet.
  });
}
