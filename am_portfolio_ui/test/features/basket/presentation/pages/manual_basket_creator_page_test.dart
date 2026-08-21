import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_portfolio_ui/features/basket/presentation/pages/manual_basket_creator_page.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_design_system/am_design_system.dart';

void main() {
  testWidgets('Delete button sets buyQuantity to null', (WidgetTester tester) async {
    final opportunity = BasketOpportunity(
      etfIsin: 'TEST',
      etfName: 'TEST ETF',
      composition: [
        BasketItem(
          stockSymbol: 'HDFCBANK',
          isin: 'INE040A01034',
          sector: 'Financial Services',
          status: ItemStatus.missing,
          etfWeight: 10.0,
          buyQuantity: 5,
          lastPrice: 1000.0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: ManualBasketCreatorPage(
              opportunity: opportunity,
              userId: 'user1',
              portfolioId: 'portfolio1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    
    debugDumpApp();

    // Scroll the item into view
    final quantityText = find.text('5', skipOffstage: false);
    expect(quantityText, findsOneWidget);
    await tester.ensureVisible(quantityText);
    await tester.pumpAndSettle();

    // Now verify it's visible on screen
    expect(find.text('5'), findsOneWidget);

    // Tap delete button
    final deleteButton = find.byIcon(Icons.delete_outline);
    expect(deleteButton, findsOneWidget);
    
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // After delete, the item should be missing, meaning it says "Add" instead of a number
    expect(find.text('Add'), findsOneWidget);
  });
}
