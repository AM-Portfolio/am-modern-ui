import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/manual_basket_creator_page.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_design_system/am_design_system.dart';

void main() {
  testWidgets('ManualBasketCreatorPage renders properly', (tester) async {
    final mockOpportunity = BasketOpportunity(
      etfIsin: 'US123',
      etfName: 'Tech ETF',
      composition: [],
      matchScore: 90.0,
      totalItems: 0,
      missingCount: 0,
      heldCount: 0,
      readyToReplicate: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ManualBasketCreatorPage(
              userId: 'user1',
              portfolioId: 'port1',
              opportunity: mockOpportunity,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Customize Basket'), findsWidgets);
    
    // Verify "Save Portfolio" button
    expect(find.text('Save Portfolio'), findsWidgets);
  });
}
