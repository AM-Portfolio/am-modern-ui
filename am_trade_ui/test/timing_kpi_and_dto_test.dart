import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/internal/data/dtos/metrics/metrics_dtos.dart';
import 'package:am_trade_ui/features/trade/internal/domain/entities/metrics/trade_distribution_metrics.dart';
import 'package:am_trade_ui/features/trade/presentation/analysis/models/timing_bucket.dart';
import 'package:am_trade_ui/features/trade/presentation/analysis/widgets/timing_kpi_math.dart';
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
        'avgPnlPerActiveDayByMonth': {'AUGUST': 9232.22},
        'activeTradingDaysByMonth': {'AUGUST': 9},
        'activeTradingDaysCount': 31,
        'avgPnlPerActiveDay': 1755.19,
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
      expect(dto.activeTradingDaysCount, 31);
      expect(dto.avgPnlPerActiveDay, closeTo(1755.19, 0.01));

      final entity = dto.toEntity();
      expect(entity.avgHoldMinutesBySession['SESSION_0915_1100'], 15.0);
      expect(entity.riskRewardBySession.containsKey('SESSION_1100_1300'), isFalse);
      expect(entity.bestSessionKey, 'SESSION_0915_1100');
      expect(entity.bestSessionAvgPnl, 42.5);
      expect(entity.tradingStyleHint!.style, 'SCALPER');
      expect(entity.avgHoldMinutesByDay['MONDAY'], 12.5);
      expect(entity.riskRewardByMonth['JANUARY'], 0.8);
      expect(entity.activeTradingDaysByMonth['AUGUST'], 9);
      expect(entity.avgPnlPerActiveDayByMonth['AUGUST'], closeTo(9232.22, 0.01));
      expect(entity.activeTradingDaysCount, 31);
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
      expect(entity.totalProfitLossPercentage, isNull);
    });

    test('missing totalProfitLoss stays null not zero', () {
      final entity = PerformanceMetricsDto.fromJson({
        'winRate': 50,
      }).toEntity();
      expect(entity.totalProfitLoss, isNull);
      expect(entity.totalProfitLossPercentage, isNull);
    });
  });

  group('timing_kpi_math', () {
    test('total avg winRate from session maps', () {
      final dist = TradeDistributionMetrics(
        tradesByDay: const {},
        profitByDay: const {},
        tradesByHour: const {},
        profitByHour: const {},
        tradeCountByAssetClass: const {},
        tradeCountByStrategy: const {},
        profitBySession: const {
          'SESSION_0915_1100': 100,
          'SESSION_1100_1300': -40,
          'OTHER': 0,
        },
        eligibleTradesBySession: const {
          'SESSION_0915_1100': 2,
          'SESSION_1100_1300': 2,
          'OTHER': 1,
        },
        winRateBySession: const {
          'SESSION_0915_1100': 50,
          'SESSION_1100_1300': 50,
          'OTHER': 0,
        },
      );
      expect(timingTotalPnl(dist), 60);
      expect(timingEligibleSum(dist), 5);
      expect(timingAvgPnl(dist), closeTo(12, 0.001));
      // wins = 0.5*2 + 0.5*2 + 0*1 = 2; eligible 5 → 40%
      expect(timingWinRate(dist), closeTo(40, 0.05));
      final counts = timingWinCounts(dist)!;
      expect(counts.wins, 2);
      expect(counts.losses, 3);
      expect(counts.eligible, 5);
      expect(
        timingAvgPnlForBasis(dist, TimingAvgBasis.perTrade),
        closeTo(12, 0.001),
      );
    });

    test('avg hold is eligible-weighted from session map', () {
      final dist = TradeDistributionMetrics(
        tradesByDay: const {},
        profitByDay: const {},
        tradesByHour: const {},
        profitByHour: const {},
        tradeCountByAssetClass: const {},
        tradeCountByStrategy: const {},
        eligibleTradesBySession: const {
          'SESSION_0915_1100': 2,
          'SESSION_1100_1300': 2,
        },
        avgHoldMinutesBySession: const {
          'SESSION_0915_1100': 10,
          'SESSION_1100_1300': 30,
        },
      );
      // (10*2 + 30*2) / 4 = 20
      expect(timingAvgHoldMinutes(dist), closeTo(20, 0.001));
    });

    test('avg per active day uses server field or days count', () {
      final dist = TradeDistributionMetrics(
        tradesByDay: const {},
        profitByDay: const {},
        tradesByHour: const {},
        profitByHour: const {},
        tradeCountByAssetClass: const {},
        tradeCountByStrategy: const {},
        profitBySession: const {'SESSION_0915_1100': 83090},
        eligibleTradesBySession: const {'SESSION_0915_1100': 34},
        activeTradingDaysCount: 9,
        avgPnlPerActiveDay: 83090 / 9,
      );
      expect(timingAvgPnl(dist), closeTo(83090 / 34, 0.01));
      expect(
        timingAvgPnlForBasis(dist, TimingAvgBasis.perActiveDay),
        closeTo(83090 / 9, 0.01),
      );
    });

    test('null dist yields null KPIs', () {
      expect(timingTotalPnl(null), isNull);
      expect(timingAvgPnl(null), isNull);
      expect(timingAvgPnlForBasis(null, TimingAvgBasis.perActiveDay), isNull);
      expect(timingWinRate(null), isNull);
    });
  });

  group('Avg basis bucket display', () {
    test('Aug-style per trade vs per active day without refetch', () {
      final perTrade = buildTimingBuckets(
        trades: {'AUGUST': 34},
        profit: {'AUGUST': 83090},
        avgPnl: {'AUGUST': 83090 / 34},
        avgPnlPerActiveDay: {'AUGUST': 83090 / 9},
        eligible: {'AUGUST': 34},
        activeTradingDays: {'AUGUST': 9},
        labelFor: formatMonthLabel,
        avgBasis: TimingAvgBasis.perTrade,
      ).single;
      final perDay = buildTimingBuckets(
        trades: {'AUGUST': 34},
        profit: {'AUGUST': 83090},
        avgPnl: {'AUGUST': 83090 / 34},
        avgPnlPerActiveDay: {'AUGUST': 83090 / 9},
        eligible: {'AUGUST': 34},
        activeTradingDays: {'AUGUST': 9},
        labelFor: formatMonthLabel,
        avgBasis: TimingAvgBasis.perActiveDay,
      ).single;
      expect(perTrade.avgPnl, closeTo(2443.82, 0.1));
      expect(perDay.avgPnl, closeTo(9232.22, 0.1));
      expect(perDay.activeTradingDays, 9);
      expect(perDay.displayAvg(TimingAvgBasis.perTrade), closeTo(2443.82, 0.1));
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
