import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';
import 'package:am_portfolio_ui/features/basket/presentation/utils/discover_view_state.dart';
import 'package:am_portfolio_ui/features/basket/presentation/widgets/discover/discover_layout.dart';

void main() {
  group('DiscoverViewState labels', () {
    test('period labels use return / CAGR rules', () {
      expect(
        const DiscoverViewState(period: DiscoverPerformancePeriod.oneY)
            .periodReturnColumnLabel,
        '1Y return',
      );
      expect(
        const DiscoverViewState(period: DiscoverPerformancePeriod.threeY)
            .periodReturnColumnLabel,
        '3Y CAGR',
      );
      expect(
        const DiscoverViewState(period: DiscoverPerformancePeriod.fiveY)
            .periodReturnColumnLabel,
        '5Y CAGR',
      );
      expect(
        const DiscoverViewState(period: DiscoverPerformancePeriod.all)
            .periodReturnColumnLabel,
        '5Y CAGR',
      );
      expect(
        const DiscoverViewState(period: DiscoverPerformancePeriod.threeY)
            .periodReturnSubtitle,
        '3Y CAGR',
      );
    });

    test('apply sorts by match, return, required', () {
      final a = BasketOpportunity(
        etfIsin: 'A',
        etfName: 'A',
        matchScore: 40,
        return1Y: 10,
        minimumInvestmentAmount: 50000,
      );
      final b = BasketOpportunity(
        etfIsin: 'B',
        etfName: 'B',
        matchScore: 80,
        return1Y: 5,
        minimumInvestmentAmount: 10000,
      );
      final c = BasketOpportunity(
        etfIsin: 'C',
        etfName: 'C',
        matchScore: 60,
        return1Y: 20,
        minimumInvestmentAmount: 30000,
      );
      final source = [a, b, c];

      final byMatch = const DiscoverViewState(
        sort: DiscoverSortMode.matchDesc,
      ).apply(source);
      expect(byMatch.map((e) => e.etfIsin).toList(), ['B', 'C', 'A']);

      final byReturn = const DiscoverViewState(
        sort: DiscoverSortMode.returnDesc,
      ).apply(source);
      expect(byReturn.map((e) => e.etfIsin).toList(), ['C', 'A', 'B']);

      final byRequired = const DiscoverViewState(
        sort: DiscoverSortMode.requiredAsc,
      ).apply(source);
      expect(byRequired.map((e) => e.etfIsin).toList(), ['B', 'C', 'A']);
    });

    test('topPicks are sector champions by period return', () {
      final a = BasketOpportunity(
        etfIsin: 'A',
        etfName: 'A',
        categoryLabel: 'Bank',
        matchScore: 99,
        return1Y: 5,
      );
      final b = BasketOpportunity(
        etfIsin: 'B',
        etfName: 'B',
        categoryLabel: 'IT',
        matchScore: 10,
        return1Y: 25,
      );
      final c = BasketOpportunity(
        etfIsin: 'C',
        etfName: 'C',
        categoryLabel: 'Auto',
        matchScore: 50,
        return1Y: 15,
      );
      final sameSectorLower = BasketOpportunity(
        etfIsin: 'B2',
        etfName: 'B2',
        categoryLabel: 'IT',
        matchScore: 90,
        return1Y: 20,
      );
      // Match-sorted segment would prefer A; champions prefer B, C, A
      final segment = [a, c, b, sameSectorLower];
      final picks = const DiscoverViewState(
        period: DiscoverPerformancePeriod.oneY,
        sort: DiscoverSortMode.matchDesc,
      ).topPicks(segment);
      expect(picks.map((e) => e.etfIsin).toList(), ['B', 'C', 'A']);
    });

    test('topPicks returns all category champions without a hard cap', () {
      final segment = [
        BasketOpportunity(
          etfIsin: 'A',
          etfName: 'A',
          categoryLabel: 'Bank',
          matchScore: 40,
          return1Y: 5,
        ),
        BasketOpportunity(
          etfIsin: 'B',
          etfName: 'B',
          categoryLabel: 'IT',
          matchScore: 40,
          return1Y: 25,
        ),
        BasketOpportunity(
          etfIsin: 'C',
          etfName: 'C',
          categoryLabel: 'Auto',
          matchScore: 40,
          return1Y: 15,
        ),
        BasketOpportunity(
          etfIsin: 'D',
          etfName: 'D',
          categoryLabel: 'Metal',
          matchScore: 40,
          return1Y: 40,
        ),
        BasketOpportunity(
          etfIsin: 'D2',
          etfName: 'D2',
          categoryLabel: 'Metal',
          matchScore: 90,
          return1Y: 10,
        ),
      ];
      final picks = const DiscoverViewState(
        period: DiscoverPerformancePeriod.oneY,
      ).topPicks(segment);
      expect(picks.length, 4);
      expect(picks.map((e) => e.etfIsin).toList(), ['D', 'B', 'C', 'A']);

      final limited = const DiscoverViewState(
        period: DiscoverPerformancePeriod.oneY,
      ).topPicks(segment, limit: 3);
      expect(limited.map((e) => e.etfIsin).toList(), ['D', 'B', 'C']);
    });

    test('formatters', () {
      expect(DiscoverViewState.formatReturn(null), '—');
      expect(DiscoverViewState.formatReturn(7.432), '+7.43%');
      expect(DiscoverViewState.formatReturn(-1.2), '-1.20%');
      expect(DiscoverViewState.formatRequiredInr(50000), '₹0.5L');
    });
  });

  group('DiscoverLayout', () {
    test('card height and flex totals in range', () {
      expect(DiscoverLayout.cardHeightInRange, isTrue);
      expect(DiscoverLayout.flexTotal, 104);
      expect(DiscoverLayout.sectionGap, 20);
      expect(DiscoverLayout.gridGap, 12);
    });
  });
}
