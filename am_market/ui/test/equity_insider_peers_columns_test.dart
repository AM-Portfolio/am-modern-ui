import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_peers_columns.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('peer column labels stay short for ROE ROA ROCE', () {
    final cols = PeerColumnsHelper.resolveActiveColumns([
      CompetitorPeer(symbol: 'TCS', pe: 20, roe: 15, roa: 8, roce: 18),
    ]);
    expect(cols.map((c) => c.label).toList(), ['P/E', 'ROE', 'ROA', 'ROCE']);
  });
}
