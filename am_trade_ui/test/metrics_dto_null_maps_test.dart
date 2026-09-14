import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/internal/data/dtos/metrics/metrics_dtos.dart';

/// Prod Jackson emits null win%/avgPnl for empty buckets. Default
/// json_serializable `(e as num)` throws; hand-written fromJson must tolerate.
void main() {
  test('TradeDistributionMetricsDto.fromJson skips null map values', () {
    final dto = TradeDistributionMetricsDto.fromJson({
      'tradesBySession': {'MORNING': 10, 'OTHER': 0},
      'profitBySession': {'MORNING': 100.0, 'OTHER': null},
      'winRateBySession': {'MORNING': 55.0, 'OTHER': null},
      'avgPnlBySession': {'MORNING': 12.5, 'OTHER': null},
      'eligibleTradesBySession': {'MORNING': 10, 'OTHER': 0},
      'winRateByHour': {'09': 40.0, '15': null},
      'avgPnlByHour': {'09': 1.0, '15': null},
      'winRateByDay': {'MONDAY': null, 'TUESDAY': 50.0},
      'avgPnlByDay': {'MONDAY': null, 'TUESDAY': 2.0},
    });

    expect(dto.winRateBySession, {'MORNING': 55.0});
    expect(dto.avgPnlBySession, {'MORNING': 12.5});
    expect(dto.profitBySession, {'MORNING': 100.0});
    expect(dto.winRateByHour, {'09': 40.0});
    expect(dto.avgPnlByHour, {'09': 1.0});
    expect(dto.winRateByDay, {'TUESDAY': 50.0});
    expect(dto.avgPnlByDay, {'TUESDAY': 2.0});

    final entity = dto.toEntity();
    expect(entity.avgPnlBySession['MORNING'], 12.5);
    expect(entity.winRateBySession.containsKey('OTHER'), isFalse);
  });

  test('TradeMetricsResponseDto tolerates null totalTradesCount', () {
    final dto = TradeMetricsResponseDto.fromJson({
      'portfolioIds': ['p1'],
      'startDate': '2015-01-01',
      'endDate': '2026-09-14',
      'totalTradesCount': null,
      'distributionMetrics': {
        'avgPnlBySession': {'MORNING': null},
      },
    });
    expect(dto.totalTradesCount, 0);
    expect(dto.distributionMetrics?.avgPnlBySession, isEmpty);
  });
}
