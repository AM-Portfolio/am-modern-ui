import 'package:am_design_system/am_design_system.dart' show TimeFrame;
import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/data/mappers/portfolio_analytics_mapper.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/cubit/portfolio_analytics_cubit.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';

void main() {
  group('createDefaultRequest timeframe', () {
    test('oneDay omits timeFrame and dates (live path)', () {
      final req = PortfolioAnalyticsMapper.createDefaultRequest(
        'pid',
        timeFrame: TimeFrame.oneDay,
      );
      expect(req.timeFrame, isNull);
      expect(req.fromDate, isNull);
      expect(req.toDate, isNull);
    });

    test('oneWeek sends 1W with dates', () {
      final req = PortfolioAnalyticsMapper.createDefaultRequest(
        'pid',
        timeFrame: TimeFrame.oneWeek,
      );
      expect(req.timeFrame, '1W');
      expect(req.fromDate, isNotNull);
      expect(req.toDate, isNotNull);
    });

    test('threeMonths sends dates with 1M candle code', () {
      final req = PortfolioAnalyticsMapper.createDefaultRequest(
        'pid',
        timeFrame: TimeFrame.threeMonths,
      );
      expect(req.timeFrame, '1M');
      expect(req.fromDate, isNotNull);
      expect(req.toDate, isNotNull);
    });

    test('oneYear sends 1Y with dates', () {
      final req = PortfolioAnalyticsMapper.createDefaultRequest(
        'pid',
        timeFrame: TimeFrame.oneYear,
      );
      expect(req.timeFrame, '1Y');
      expect(req.fromDate, isNotNull);
      expect(req.toDate, isNotNull);
    });
  });

  group('preferNonEmptyAllocation', () {
    test('keeps live when hist weights empty', () {
      final live = SectorAllocation(
        sectorWeights: const [
          SectorWeight(
            sectorName: 'IT',
            weightPercentage: 10,
            marketCap: 100,
            topStocks: ['TCS'],
          ),
        ],
        industryWeights: const [],
      );
      const hist = SectorAllocation(
        sectorWeights: [],
        industryWeights: [],
      );
      final merged =
          PortfolioAnalyticsCubit.preferNonEmptyAllocation(hist, live);
      expect(merged, same(live));
    });

    test('prefers hist when hist has weights', () {
      final live = SectorAllocation(
        sectorWeights: const [
          SectorWeight(
            sectorName: 'IT',
            weightPercentage: 10,
            marketCap: 100,
            topStocks: ['TCS'],
          ),
        ],
        industryWeights: const [],
      );
      final hist = SectorAllocation(
        sectorWeights: const [
          SectorWeight(
            sectorName: 'Bank',
            weightPercentage: 20,
            marketCap: 200,
            topStocks: ['HDFC'],
          ),
        ],
        industryWeights: const [],
      );
      final merged =
          PortfolioAnalyticsCubit.preferNonEmptyAllocation(hist, live);
      expect(merged, same(hist));
    });
  });

  group('preferQualityHeatmap', () {
    test('keeps live when hist sectors empty', () {
      final live = Heatmap(
        sectors: [
          Sector(
            sectorName: 'IT',
            performanceRank: 1,
            performance: 1,
            changePercent: 1,
            weightage: 10,
            color: '',
            stockCount: 1,
            totalValue: 100,
            totalReturnAmount: 0,
            stocks: const [],
          ),
        ],
      );
      const hist = Heatmap(sectors: []);
      final merged = PortfolioAnalyticsCubit.preferQualityHeatmap(hist, live);
      expect(merged, same(live));
    });

    test('thin hist does not replace rich live; overlays matching pct', () {
      final live = Heatmap(
        sectors: [
          Sector(
            sectorName: 'IT',
            performanceRank: 1,
            performance: 1,
            changePercent: 1,
            weightage: 40,
            color: '',
            stockCount: 2,
            totalValue: 400000,
            totalReturnAmount: 0,
            stocks: const [],
          ),
          Sector(
            sectorName: 'Bank',
            performanceRank: 2,
            performance: 2,
            changePercent: 2,
            weightage: 60,
            color: '',
            stockCount: 3,
            totalValue: 600000,
            totalReturnAmount: 0,
            stocks: const [],
          ),
        ],
      );
      final hist = Heatmap(
        sectors: [
          Sector(
            sectorName: 'IT',
            performanceRank: 1,
            performance: 8,
            changePercent: 8,
            weightage: 100,
            color: '',
            stockCount: 1,
            totalValue: 5000,
            totalReturnAmount: 0,
            stocks: const [],
          ),
        ],
      );
      final merged = PortfolioAnalyticsCubit.preferQualityHeatmap(hist, live);
      expect(merged!.sectors.length, 2);
      expect(merged.sectors.first.totalValue, 400000);
      expect(merged.sectors.first.changePercent, 8);
      expect(merged.sectors.last.changePercent, 2);
    });
  });
}
