import 'package:am_market_common/models/market_info_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses snake_case Upstox market-info payloads', () {
    final overview = FlowsOverview.fromJson({
      'interval': '1D',
      'fii': {
        'status': 'success',
        'data': {
          'NSE_EQ|CASH': [
            {
              'time_stamp': 1789669800000,
              'buy_amount': 120.5,
              'sell_amount': 100,
            },
          ],
        },
      },
      'dii': {'status': 'success', 'data': <String, dynamic>{}},
      'oi': [
        {
          'symbol': 'NIFTY 50',
          'instrument_key': 'NSE_INDEX|Nifty 50',
          'total_calls': 100,
          'total_puts': 125,
          'spot': 23000,
          'expiry': '29-09-2026',
          'pcr': 1.25,
        },
      ],
    });

    expect(overview.fii.latestFor('NSE_EQ|CASH')?.netAmount, 20.5);
    expect(overview.oi.single.instrumentKey, 'NSE_INDEX|Nifty 50');
    expect(overview.oi.single.pcr, 1.25);
  });

  test('parses camelCase Java market-info payloads', () {
    final oi = OiData.fromJson({
      'totalPuts': 125,
      'totalCalls': 100,
      'spotClosingPrice': 23000.5,
      'expiry': '29-09-2026',
      'callPutOiDataList': [
        {'strikePrice': 23000, 'callOi': 40, 'putOi': 55},
      ],
    });
    final change = ChangeOiData.fromJson({
      'totalPutChangeOi': 50,
      'totalCallChangeOi': 25,
      'spotClosingPrice': 23000.5,
      'callPutOiDataList': [
        {'strikePrice': 23000, 'callChangeOi': -5, 'putChangeOi': 10},
      ],
    });

    expect(oi.pcr, 1.25);
    expect(oi.rows.single.putOi, 55);
    expect(change.changePcr, 2);
    expect(change.rows.single.callChangeOi, -5);
  });
}
