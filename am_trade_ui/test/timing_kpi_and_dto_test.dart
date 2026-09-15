import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/internal/data/dtos/metrics/metrics_dtos.dart';
import 'package:am_trade_ui/features/trade/presentation/analysis/models/timing_bucket.dart';
import 'package:am_trade_ui/features/trade/presentation/analysis/widgets/timing_kpi_row.dart';

void main() {
  group('formatHoldDuration', () {
    test('minutes under 60', () {
      expect(formatHoldDuration(0), '0m');
      expect(formatHoldDuration(18), '18m');
      expect(formatHoldDuration(59.4), '59m');
    });

    test('hours and minutes', () {
      expect(formatHoldDuration(60), '1h');
      expect(formatHoldDuration(130), '2h 10m');
      expect(formatHoldDuration(1439), '23h 59m');
    });

    test('days for swing holds', () {
      expect(formatHoldDuration(24 * 60), '1.0d');
      expect(formatHoldDuration(36 * 60), '1.5d');
    });
  });

  group('buildTimingBuckets hold + R:R', () {
    test('threads avgHoldMinutes and riskReward', () {
      final buckets = buildTimingBuckets(
        trades: {'SESSION_0915_1100': 4},
        profit: {'SESSION_0915_1100': 100},
        avgPnl: {'SESSION_0915_1100': 25},
        eligible: {'SESSION_0915_1100': 4},
        avgHoldMinutes: {'SESSION_0915_1100': 18.5},
        riskReward: {'SESSION_0915_1100': 1.6},
        labelFor: formatSessionLabel,
      );
      expect(buckets.single.avgHoldMinutes, 18.5);
      expect(buckets.single.riskReward, 1.6);
    });

    test('missing hold/RR maps leave fields null', () {
      final buckets = buildTimingBuckets(
        trades: {'SESSION_0915_1100': 2},
        profit: {'SESSION_0915_1100': 10},
        labelFor: formatSessionLabel,
      );
      expect(buckets.single.avgHoldMinutes, isNull);
      expect(buckets.single.riskReward, isNull);
    });
  });

  group('TradeDistributionMetricsDto new Timing fields', () {
    test('parses avgHold, riskReward, bestSession and skips nulls', () {
      final dto = TradeDistributionMetricsDto.fromJson({
        'avgHoldMinutesBySession': {
          'SESSION_0915_1100': 15.0,
          'SESSION_1100_1300': null,
        },
        'riskRewardBySession': {
          'SESSION_0915_1100': 2.0,
          'SESSION_1100_1300': null,
        },
        'avgHoldMinutesByDay': {'MONDAY': 12.5},
        'riskRewardByDay': {'MONDAY': 1.1},
        'avgHoldMinutesByMonth': {'JANUARY': 20},
        'riskRewardByMonth': {'JANUARY': 0.8},
        'bestSessionKey': 'SESSION_0915_1100',
        'bestSessionAvgPnl': 42.5,
        'timezoneNote': 'entry_local_as_stored',
        'tradingStyleHint': {
          'style': 'SCALPER',
          'confidencePercent': 59,
          'basis': 'holding_duration',
          'sampleSize': 157,
        },
      });

      expect(dto.avgHoldMinutesBySession, {'SESSION_0915_1100': 15.0});
      expect(dto.riskRewardBySession, {'SESSION_0915_1100': 2.0});
      expect(dto.bestSessionKey, 'SESSION_0915_1100');
      expect(dto.bestSessionAvgPnl, 42.5);

      final entity = dto.toEntity();
      expect(entity.avgHoldMinutesBySession['SESSION_0915_1100'], 15.0);
      expect(entity.riskRewardBySession.containsKey('SESSION_1100_1300'), isFalse);
      expect(entity.bestSessionKey, 'SESSION_0915_1100');
      expect(entity.bestSessionAvgPnl, 42.5);
      expect(entity.tradingStyleHint!.style, 'SCALPER');
      expect(entity.avgHoldMinutesByDay['MONDAY'], 12.5);
      expect(entity.riskRewardByMonth['JANUARY'], 0.8);
    });

    test('BigDecimal-as-string values parse', () {
      final dto = TradeDistributionMetricsDto.fromJson({
        'avgHoldMinutesBySession': {'SESSION_0915_1100': '18.2500'},
        'riskRewardBySession': {'SESSION_0915_1100': '1.3333'},
        'bestSessionAvgPnl': '99.5',
      });
      expect(dto.avgHoldMinutesBySession!['SESSION_0915_1100'], 18.25);
      expect(dto.riskRewardBySession!['SESSION_0915_1100'], closeTo(1.3333, 0.0001));
      expect(dto.bestSessionAvgPnl, 99.5);
    });
  });

  group('PerformanceMetricsDto Timing KPI fields', () {
    test('parses win/loss counts and hold minutes', () {
      final dto = PerformanceMetricsDto.fromJson({
        'totalProfitLoss': -6230,
        'totalProfitLossPercentage': -12.4,
        'winRate': 52.9,
        'winningTradesCount': 92,
        'losingTradesCount': 82,
        'averageHoldingTimeMinutes': 18.25,
      });
      expect(dto.winningTradesCount, 92);
      expect(dto.losingTradesCount, 82);
      expect(dto.averageHoldingTimeMinutes, 18.25);

      final entity = dto.toEntity();
      expect(entity.totalProfitLoss, -6230);
      expect(entity.winningTradesCount, 92);
      expect(entity.losingTradesCount, 82);
      expect(entity.averageHoldingTimeMinutes, 18.25);
    });

    test('missing KPI fields stay null', () {
      final entity = PerformanceMetricsDto.fromJson({
        'totalProfitLoss': 10,
        'winRate': 50,
      }).toEntity();
      expect(entity.winningTradesCount, isNull);
      expect(entity.losingTradesCount, isNull);
      expect(entity.averageHoldingTimeMinutes, isNull);
    });
  });

  group('TradeMetricsResponseDto PERFORMANCE+DISTRIBUTION payload', () {
    test('maps full Timing Analysis response shape', () {
      final dto = TradeMetricsResponseDto.fromJson({
        'portfolioIds': ['p1'],
        'startDate': '2015-01-01',
        'endDate': '2026-09-15',
        'totalTradesCount': 174,
        'performanceMetrics': {
          'totalProfitLoss': -6230,
          'totalProfitLossPercentage': -12.4,
          'winRate': 52.9,
          'winningTradesCount': 92,
          'losingTradesCount': 82,
          'averageHoldingTimeMinutes': 18,
        },
        'distributionMetrics': {
          'tradesBySession': {
            'SESSION_0915_1100': 42,
            'SESSION_1100_1300': 0,
            'SESSION_1300_1500': 0,
            'SESSION_1500_1530': 0,
            'OTHER': 0,
          },
          'avgPnlBySession': {'SESSION_0915_1100': -148},
          'eligibleTradesBySession': {'SESSION_0915_1100': 42},
          'avgHoldMinutesBySession': {'SESSION_0915_1100': 12},
          'riskRewardBySession': {'SESSION_0915_1100': 0.6},
          'bestSessionKey': 'SESSION_1500_1530',
          'bestSessionAvgPnl': 6740,
          'timezoneNote': 'entry_local_as_stored',
          'tradingStyleHint': {
            'style': 'SCALPER',
            'confidencePercent': 59,
            'basis': 'holding_duration',
            'sampleSize': 157,
          },
        },
      });

      final entity = dto.toEntity();
      expect(entity.totalTradesCount, 174);
      expect(entity.performanceMetrics.winningTradesCount, 92);
      expect(entity.performanceMetrics.averageHoldingTimeMinutes, 18);
      expect(
        entity.distributionMetrics.avgHoldMinutesBySession['SESSION_0915_1100'],
        12,
      );
      expect(
        entity.distributionMetrics.riskRewardBySession['SESSION_0915_1100'],
        0.6,
      );
      expect(entity.distributionMetrics.bestSessionKey, 'SESSION_1500_1530');
      expect(entity.distributionMetrics.tradingStyleHint!.confidencePercent, 59);
    });
  });

  group('Best session ranking parity with min sample', () {
    test('client ranking ignores low-sample hot session', () {
      final sessions = buildTimingBuckets(
        trades: {
          'SESSION_0915_1100': 2,
          'SESSION_1500_1530': 5,
        },
        profit: {
          'SESSION_0915_1100': 2000,
          'SESSION_1500_1530': 500,
        },
        avgPnl: {
          'SESSION_0915_1100': 1000,
          'SESSION_1500_1530': 100,
        },
        eligible: {
          'SESSION_0915_1100': 2,
          'SESSION_1500_1530': 5,
        },
        labelFor: formatSessionLabel,
        orderedKeys: kSessionKeys,
        includeZeroTradeBuckets: false,
      );
      final best = rowsForRankView(sessions, TimingRankView.best);
      expect(best.single.key, 'SESSION_1500_1530');
      expect(best.single.label, '3:00–3:30');
    });
  });
}
