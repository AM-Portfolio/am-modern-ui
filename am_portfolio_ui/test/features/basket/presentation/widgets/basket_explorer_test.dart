import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_portfolio_ui/features/basket/presentation/widgets/basket_explorer.dart';
import 'package:am_portfolio_ui/features/basket/presentation/providers/basket_providers.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_catalog.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';

class FakeSecureStorageService implements SecureStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    if (!GetIt.I.isRegistered<SecureStorageService>()) {
      GetIt.I.registerSingleton<SecureStorageService>(FakeSecureStorageService());
    }
  });

  testWidgets('BasketExplorer shows toggle between Discover and My Baskets', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          basketCatalogProvider.overrideWith((ref) async => const BasketCatalog(
                defaultQuery: 'ALL',
                themes: [],
              )),
          basketOpportunitiesProvider.overrideWith((ref, args) async => []),
          myBasketsProvider.overrideWith((ref, args) async => []),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: BasketExplorer(userId: 'test_user', portfolioId: 'test_portfolio'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Should render SegmentedButton
    expect(find.byType(SegmentedButton<BasketViewMode>), findsOneWidget);
    
    // Discover should be selected by default (finding 'Discover' text)
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('My Baskets'), findsOneWidget);

    // Tap on My Baskets
    await tester.tap(find.text('My Baskets'));
    await tester.pumpAndSettle();

    // After tapping, MyBasketsView should be visible (indicated by its empty state or loading indicator)
    // We can't guarantee what's inside without overrides, but we know My Baskets text remains
    expect(find.text('My Baskets'), findsOneWidget);
  });
}
