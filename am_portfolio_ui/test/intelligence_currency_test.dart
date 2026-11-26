import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_currency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Cr uses two decimals for Overview NAV alignment', () {
    expect(formatIntelligenceCompactInr(13066720.64), '₹1.31Cr');
    expect(formatIntelligenceCompactInr(10000000), '₹1.00Cr');
  });

  test('L uses two decimals', () {
    expect(formatIntelligenceCompactInr(2198000), '₹21.98L');
  });
}
