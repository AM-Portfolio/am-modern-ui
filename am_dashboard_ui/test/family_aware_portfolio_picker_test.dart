import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Book {
  const _Book({
    required this.id,
    required this.name,
    this.familyMemberId,
    this.familyMemberName,
  });
  final String id;
  final String name;
  final String? familyMemberId;
  final String? familyMemberName;

  _Book copyWithName(String labeled) => _Book(
        id: id,
        name: labeled,
        familyMemberId: familyMemberId,
        familyMemberName: familyMemberName,
      );
}

void main() {
  testWidgets('hides Family dropdown when no members', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FamilyAwarePortfolioPicker<_Book>(
              showFamilyFilter: false,
              familyFilterKey: FavoritePersonaStore.kAll,
              primaryLabel: 'You',
              members: const [],
              onFamilySelected: (_) {},
              currentPortfolioId: 'all',
              currentPortfolioName: 'All Portfolios',
              portfolios: const [
                _Book(id: 'all', name: 'All Portfolios'),
                _Book(id: 'p1', name: 'Dhan'),
              ],
              onPortfolioSelected: (_, __) {},
              idExtractor: (b) => b.id,
              nameExtractor: (b) => b.name,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SharedFamilyFilterDropdown), findsNothing);
    expect(find.byType(SharedPortfolioSelector<_Book>), findsOneWidget);
  });

  testWidgets('shows Family dropdown when members exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FamilyAwarePortfolioPicker<_Book>(
              showFamilyFilter: true,
              familyFilterKey: FavoritePersonaStore.kAll,
              primaryLabel: 'You',
              members: const [(id: 'fm1', name: 'Priyanshu')],
              onFamilySelected: (_) {},
              currentPortfolioId: 'all',
              currentPortfolioName: 'All Portfolios',
              portfolios: const [
                _Book(id: 'all', name: 'All Portfolios'),
                _Book(id: 'p1', name: 'Dhan'),
              ],
              onPortfolioSelected: (_, __) {},
              idExtractor: (b) => b.id,
              nameExtractor: (b) => b.name,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SharedFamilyFilterDropdown), findsOneWidget);
  });

  testWidgets('Family change filters portfolio labels', (tester) async {
    var filter = FavoritePersonaStore.kAll;
    final books = [
      const _Book(id: 'p1', name: 'Groww'),
      const _Book(
        id: 'p2',
        name: 'Groww',
        familyMemberId: 'fm1',
        familyMemberName: 'Priyanshu',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                final filtered = applyFamilyPortfolioFilter<_Book>(
                  items: books,
                  filterKey: filter,
                  showFamilyUi: true,
                  familyMemberIdOf: (b) => b.familyMemberId,
                  familyMemberNameOf: (b) => b.familyMemberName,
                  baseNameOf: (b) => b.name,
                  copyWithName: (b, labeled) => b.copyWithName(labeled),
                );
                return FamilyAwarePortfolioPicker<_Book>(
                  showFamilyFilter: true,
                  familyFilterKey: filter,
                  primaryLabel: 'You',
                  members: const [(id: 'fm1', name: 'Priyanshu')],
                  onFamilySelected: (key) => setState(() => filter = key),
                  currentPortfolioId: 'all',
                  currentPortfolioName: 'All Portfolios',
                  portfolios: [
                    const _Book(id: 'all', name: 'All Portfolios'),
                    ...filtered,
                  ],
                  onPortfolioSelected: (_, __) {},
                  idExtractor: (b) => b.id,
                  nameExtractor: (b) => b.name,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(SharedFamilyFilterDropdown));
    await tester.pumpAndSettle();
    await tester.tap(find.text('You').last);
    await tester.pumpAndSettle();

    expect(filter, FavoritePersonaStore.kYou);
  });
}
