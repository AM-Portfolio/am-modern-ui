import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crore compact uses 2 decimals so book totals match Total Balance', () {
    expect(formatIntelligenceCompactInr(13668229.67), '₹1.37Cr');
    expect(formatIntelligenceCompactInr(10000000), '₹1.00Cr');
    expect(formatIntelligenceCompactInr(9530000), '₹95.3L');
    expect(formatIntelligenceCompactInr(null), '—');
  });
}
