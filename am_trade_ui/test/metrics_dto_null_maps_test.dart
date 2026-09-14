import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/internal/data/dtos/metrics/metrics_dtos.dart';

void main() {
  test('distribution maps tolerate null winRate/avgPnl bucket values', () {
    final dto = TradeDistributionMetricsDto.fromJson({
      'tradesBySession': {
        'SESSION_0915_1100': 4,
        'OTHER': 0,
      },
      'profitBySession': {
        'SESSION_0915_1100': 100,
        'OTHER': 0,
      },
      'winRateBySession': {
        'SESSION_0915_1100': 50,
        'OTHER': null,
      },
      'avgPnlBySession': {
        'SESSION_0915_1100': '25.5',
        'OTHER': null,
      },
      'eligibleTradesBySession': {
        'SESSION_0915_1100': 4,
        'OTHER': 0,
      },
      'totalTradesCount': null,
    });

    final entity = dto.toEntity();
    expect(entity.tradesBySession['SESSION_0915_1100'], 4);
    expect(entity.winRateBySession['SESSION_0915_1100'], 50);
    expect(entity.winRateBySession.containsKey('OTHER'), isFalse);
    expect(entity.avgPnlBySession['SESSION_0915_1100'], 25.5);
  });

  test('metrics response tolerates null totalTradesCount', () {
    final dto = TradeMetricsResponseDto.fromJson({
      'portfolioIds': ['9baba209-be43-44db-9b40-e8b664084920'],
      'startDate': '2015-09-13',
      'endDate': '2026-09-14',
      'totalTradesCount': null,
      'distributionMetrics': {
        'tradesBySession': {'OTHER': 0},
        'winRateBySession': {'OTHER': null},
        'avgPnlBySession': {'OTHER': null},
      },
    });

    expect(dto.totalTradesCount, 0);
    expect(dto.distributionMetrics, isNotNull);
    expect(dto.toEntity().distributionMetrics.winRateBySession, isEmpty);
  });
}
