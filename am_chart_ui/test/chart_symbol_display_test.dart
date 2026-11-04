import 'package:am_chart_ui/src/shell/chart_symbol_display.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('portfolio title hides uuid and PORTFOLIO prefix', () {
    expect(
      ChartSymbolDisplay.title(
        'PORTFOLIO:c46f3f77-1e7c-4850-9e78-ecb6b568485f|Dhan',
      ),
      'Dhan',
    );
    expect(
      ChartSymbolDisplay.isPortfolioSymbol(
        'PORTFOLIO:c46f3f77-1e7c-4850-9e78-ecb6b568485f|Dhan',
      ),
      isTrue,
    );
    expect(ChartSymbolDisplay.brokerKeyFromTitle('Dhan - Portfolio'), 'dhan');
    expect(ChartSymbolDisplay.brokerLogoAsset('dhan'), isNotNull);
  });

  test('market symbols keep raw title', () {
    expect(ChartSymbolDisplay.title('RELIANCE'), 'RELIANCE');
    expect(ChartSymbolDisplay.isPortfolioSymbol('RELIANCE'), isFalse);
  });
}
