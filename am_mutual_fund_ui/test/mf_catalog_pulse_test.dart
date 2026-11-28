import 'package:am_mutual_fund_ui/data/mf_dto.dart';
import 'package:am_mutual_fund_ui/data/mf_scheme_view.dart';
import 'package:am_mutual_fund_ui/presentation/widgets/mf_catalog_pulse.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MfSchemeView scheme({
    required String isin,
    required String name,
    double? ret1y,
    double? navChange,
  }) {
    return MfSchemeView.fromSummary(
      MfSchemeSummary.fromJson({
        'isin': isin,
        'schemeName': name,
        'category': 'Equity',
        'source': 'nse-master',
        'nav': 10.0,
        if (ret1y != null) 'returns': {'1Y': ret1y},
        if (navChange != null) 'navChangePercent': navChange,
      }),
    );
  }

  test('topMovers ranks by selected period return then skips nulls', () {
    final funds = [
      scheme(isin: 'A', name: 'A FUND - GROWTH', ret1y: 5),
      scheme(isin: 'B', name: 'B FUND - GROWTH', ret1y: 15),
      scheme(isin: 'C', name: 'C FUND - GROWTH'),
      scheme(isin: 'D', name: 'D FUND - GROWTH', ret1y: 10),
    ];
    final movers = MfCatalogPulse.topMovers(funds, MfReturnPeriod.y1, limit: 3);
    expect(movers.map((m) => m.isin).toList(), ['B', 'D', 'A']);
  });

  test('topMovers falls back to NAV change when returns missing', () {
    final funds = [
      scheme(isin: 'X', name: 'X FUND - GROWTH', navChange: 1.2),
      scheme(isin: 'Y', name: 'Y FUND - GROWTH', navChange: 3.4),
    ];
    final movers = MfCatalogPulse.topMovers(funds, MfReturnPeriod.y1);
    expect(movers.first.isin, 'Y');
  });
}
