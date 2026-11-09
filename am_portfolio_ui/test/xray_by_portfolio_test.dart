import 'package:am_portfolio_ui/features/portfolio/internal/data/dtos/accounts_hub_dto.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_xray_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('xrayTabLabels includes By Portfolio as 5th tab', () {
    expect(xrayTabLabels.length, 5);
    expect(xrayTabLabels[4], 'By Portfolio');
    expect(xrayTabLabels[3], 'Class');
  });

  test('portfolioWeightsFromHubRows All splits by contribution', () {
    final weights = portfolioWeightsFromHubRows(
      portfolioId: 'all',
      portfolios: const [
        AccountsPortfolioRowDto(
          portfolioId: 'a',
          displayName: 'Zerodha',
          current: 600,
        ),
        AccountsPortfolioRowDto(
          portfolioId: 'b',
          displayName: 'Groww',
          current: 400,
        ),
        AccountsPortfolioRowDto(
          portfolioId: 'c',
          displayName: 'Empty',
          current: 0,
        ),
      ],
    );
    expect(weights.length, 2);
    expect(weights.first.name, 'Zerodha');
    expect(weights.first.weightPct, closeTo(60, 0.01));
    expect(weights.last.name, 'Groww');
    expect(weights.last.weightPct, closeTo(40, 0.01));
  });

  test('portfolioWeightsFromHubRows single book is 100%', () {
    final weights = portfolioWeightsFromHubRows(
      portfolioId: 'a',
      portfolios: const [
        AccountsPortfolioRowDto(
          portfolioId: 'a',
          displayName: 'Zerodha',
          current: 600,
        ),
        AccountsPortfolioRowDto(
          portfolioId: 'b',
          displayName: 'Groww',
          current: 400,
        ),
      ],
    );
    expect(weights, hasLength(1));
    expect(weights.single.name, 'Zerodha');
    expect(weights.single.weightPct, 100);
  });

  test('portfolioWeightsFromHubRows skips zero-current books', () {
    final weights = portfolioWeightsFromHubRows(
      portfolioId: 'all',
      portfolios: const [
        AccountsPortfolioRowDto(
          portfolioId: 'z',
          displayName: 'Zerodha',
          current: 0,
          invested: 10,
        ),
        AccountsPortfolioRowDto(
          portfolioId: 'd',
          displayName: 'Dhan',
          current: 100,
        ),
      ],
    );
    expect(weights, hasLength(1));
    expect(weights.single.name, 'Dhan');
  });
}
