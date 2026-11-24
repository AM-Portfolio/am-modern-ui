import 'package:am_design_system/shared/models/heatmap/heatmap_tile_data.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/mappers/sector_heatmap_converter.dart';
import 'package:flutter_test/flutter_test.dart';

Sector _sector({
  required String name,
  required double changePercent,
  required double totalValue,
  List<Stock> stocks = const [],
}) =>
    Sector(
      sectorName: name,
      performanceRank: 1,
      performance: changePercent,
      changePercent: changePercent,
      weightage: 0,
      color: '',
      stockCount: stocks.length,
      totalValue: totalValue,
      totalReturnAmount: 0,
      stocks: stocks,
    );

Stock _stock({
  required String symbol,
  required String sector,
  required double changePercent,
  required double marketValue,
}) =>
    Stock(
      symbol: symbol,
      companyName: symbol,
      lastPrice: 100,
      changeAmount: 0,
      changePercent: changePercent,
      sector: sector,
      marketValue: marketValue,
    );

void main() {
  group('SectorHeatmapConverter', () {
    test('resolves Unknown via stock.sector; Top/Weakest match tiles', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Financial Services',
            changePercent: 1.5,
            totalValue: 60000,
            stocks: [
              _stock(
                symbol: 'HDFCBANK',
                sector: 'Financial Services',
                changePercent: 1.5,
                marketValue: 60000,
              ),
            ],
          ),
          _sector(
            name: 'Unknown',
            changePercent: -3.2,
            totalValue: 40000,
            stocks: [
              _stock(
                symbol: 'TCS',
                sector: 'Information Technology',
                changePercent: -3.2,
                marketValue: 40000,
              ),
            ],
          ),
        ],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        showSubCards: false,
      );
      final tileNames = data.tiles.map((t) => t.name).toSet();

      expect(tileNames.contains('Information Technology'), isTrue);
      expect(tileNames.contains('Financial Services'), isTrue);
      expect(tileNames.contains('Other'), isFalse);

      final summary = SectorHeatmapConverter.resolveSectorSummary(
        heatmap: heatmap,
      );
      expect(summary.worstSector, 'Information Technology');
      expect(summary.topSector, 'Financial Services');
    });

    test('zero-weight named sector is omitted from tiles and summary', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Financial Services',
            changePercent: 2,
            totalValue: 100000,
          ),
          _sector(
            name: 'Information Technology',
            changePercent: -5,
            totalValue: 0,
          ),
        ],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        showSubCards: false,
      );
      expect(data.tiles.map((t) => t.name), ['Financial Services']);

      final summary = SectorHeatmapConverter.resolveSectorSummary(
        heatmap: heatmap,
      );
      expect(summary.topSector, 'Financial Services');
      expect(summary.worstSector, 'Financial Services');
    });

    test('all-flat performances yield -- for Top/Weakest', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(name: 'Financial Services', changePercent: 0, totalValue: 50000),
          _sector(name: 'Energy', changePercent: 0, totalValue: 50000),
        ],
      );
      final summary = SectorHeatmapConverter.resolveSectorSummary(
        heatmap: heatmap,
      );
      expect(summary.topSector, '--');
      expect(summary.worstSector, '--');
    });

    test('allocation overlay finds % across Unknown heatmap bucket', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Unknown',
            changePercent: 0,
            totalValue: 100000,
            stocks: [
              _stock(
                symbol: 'TCS',
                sector: 'Unknown',
                changePercent: -2.5,
                marketValue: 40000,
              ),
              _stock(
                symbol: 'RELIANCE',
                sector: 'Unknown',
                changePercent: 1.2,
                marketValue: 35000,
              ),
              _stock(
                symbol: 'HDFCBANK',
                sector: 'Unknown',
                changePercent: 0.8,
                marketValue: 25000,
              ),
            ],
          ),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Information Technology',
            weightPercentage: 40,
            marketCap: 40000,
            topStocks: const ['TCS'],
          ),
          SectorWeight(
            sectorName: 'Energy',
            weightPercentage: 35,
            marketCap: 35000,
            topStocks: const ['RELIANCE'],
          ),
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 25,
            marketCap: 25000,
            topStocks: const ['HDFCBANK'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );

      final byName = {for (final t in data.tiles) t.name: t.performance};
      expect(byName['Information Technology'], closeTo(-2.5, 0.01));
      expect(byName['Energy'], closeTo(1.2, 0.01));
      expect(byName['Financial Services'], closeTo(0.8, 0.01));
    });

    test('allocation fallback overlays heatmap changePercent by name', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Unknown',
            changePercent: 0,
            totalValue: 1,
            stocks: [
              _stock(
                symbol: 'INFY',
                sector: 'Unknown',
                changePercent: -4.5,
                marketValue: 1,
              ),
            ],
          ),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Information Technology',
            weightPercentage: 70,
            marketCap: 70000,
            topStocks: const ['INFY'],
          ),
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 30,
            marketCap: 30000,
            topStocks: const ['HDFCBANK'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );
      expect(data.tiles.length, greaterThanOrEqualTo(2));

      final itTile = data.tiles.firstWhere(
        (t) => t.name == 'Information Technology',
      );
      expect(itTile.performance, -4.5);

      final summary = SectorHeatmapConverter.resolveSectorSummary(
        heatmap: heatmap,
        sectorAllocation: allocation,
      );
      expect(summary.worstSector, 'Information Technology');
    });
    test('incomplete heatmap still falls back when allocation has richer names',
        () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Financial Services',
            changePercent: 1.0,
            totalValue: 50000,
            stocks: [
              _stock(
                symbol: 'HDFCBANK',
                sector: 'Financial Services',
                changePercent: 1.0,
                marketValue: 50000,
              ),
            ],
          ),
          _sector(
            name: 'Unknown',
            changePercent: -1.0,
            totalValue: 50000,
            stocks: [
              _stock(
                symbol: 'TCS',
                sector: 'Unknown',
                changePercent: -2.0,
                marketValue: 30000,
              ),
              _stock(
                symbol: 'RELIANCE',
                sector: 'Unknown',
                changePercent: 0.5,
                marketValue: 20000,
              ),
            ],
          ),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 40,
            marketCap: 40000,
            topStocks: const ['HDFCBANK'],
          ),
          SectorWeight(
            sectorName: 'Information Technology',
            weightPercentage: 35,
            marketCap: 35000,
            topStocks: const ['TCS'],
          ),
          SectorWeight(
            sectorName: 'Energy',
            weightPercentage: 25,
            marketCap: 25000,
            topStocks: const ['RELIANCE'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );
      final names = data.tiles.map((t) => t.name).toSet();
      expect(names.contains('Financial Services'), isTrue);
      expect(names.contains('Information Technology'), isTrue);
      expect(names.contains('Energy'), isTrue);
      expect(data.tiles.length, greaterThanOrEqualTo(3));
    });

    test('complete heatmap prefers heatmap-direct over richer allocation', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Financial Services',
            changePercent: 1.5,
            totalValue: 40000,
            stocks: [
              _stock(
                symbol: 'HDFCBANK',
                sector: 'Financial Services',
                changePercent: 1.5,
                marketValue: 40000,
              ),
            ],
          ),
          _sector(
            name: 'Information Technology',
            changePercent: -2.0,
            totalValue: 35000,
            stocks: [
              _stock(
                symbol: 'TCS',
                sector: 'Information Technology',
                changePercent: -2.0,
                marketValue: 35000,
              ),
            ],
          ),
          _sector(
            name: 'Energy',
            changePercent: 0.8,
            totalValue: 25000,
            stocks: [
              _stock(
                symbol: 'RELIANCE',
                sector: 'Energy',
                changePercent: 0.8,
                marketValue: 25000,
              ),
            ],
          ),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 35,
            marketCap: 35000,
            topStocks: const ['HDFCBANK'],
          ),
          SectorWeight(
            sectorName: 'Information Technology',
            weightPercentage: 30,
            marketCap: 30000,
            topStocks: const ['TCS'],
          ),
          SectorWeight(
            sectorName: 'Energy',
            weightPercentage: 20,
            marketCap: 20000,
            topStocks: const ['RELIANCE'],
          ),
          // Extra allocation-only label must not force fallback.
          SectorWeight(
            sectorName: 'Exchange Traded Funds (ETFs)',
            weightPercentage: 15,
            marketCap: 15000,
            topStocks: const ['NIFTYBEES'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );
      final byName = {for (final t in data.tiles) t.name: t.performance};
      expect(byName.containsKey('Exchange Traded Funds (ETFs)'), isFalse);
      expect(byName['Financial Services'], closeTo(1.5, 0.01));
      expect(byName['Information Technology'], closeTo(-2.0, 0.01));
      expect(byName['Energy'], closeTo(0.8, 0.01));
    });

    test('tiny heatmap value mass still uses allocation fallback', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Financial Services',
            changePercent: 0.2,
            totalValue: 200,
          ),
          _sector(
            name: 'Energy',
            changePercent: 0.1,
            totalValue: 100,
          ),
          _sector(
            name: 'Healthcare',
            changePercent: -0.1,
            totalValue: 100,
          ),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 50,
            marketCap: 50000,
            topStocks: const ['HDFCBANK'],
          ),
          SectorWeight(
            sectorName: 'Energy',
            weightPercentage: 30,
            marketCap: 30000,
            topStocks: const ['RELIANCE'],
          ),
          SectorWeight(
            sectorName: 'Healthcare',
            weightPercentage: 20,
            marketCap: 20000,
            topStocks: const ['CIPLA'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );
      // Allocation path: tile values follow marketCap weights, not tiny heatmap.
      final finance = data.tiles.firstWhere((t) => t.name == 'Financial Services');
      expect(finance.value, closeTo(50000, 0.01));
    });

    test('giant Unknown value mass falls back to named allocation sectors', () {
      // Prod UI: Unknown ≈85% of book; Top/Weakest still show real sectors.
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Unknown',
            changePercent: 0.5,
            totalValue: 753000,
            stocks: [
              _stock(
                symbol: 'TITAN',
                sector: 'Unknown',
                changePercent: 2.2,
                marketValue: 40000,
              ),
              _stock(
                symbol: 'TCS',
                sector: 'Unknown',
                changePercent: -3.2,
                marketValue: 120000,
              ),
              _stock(
                symbol: 'HDFCBANK',
                sector: 'Unknown',
                changePercent: 1.1,
                marketValue: 90000,
              ),
            ],
          ),
          _sector(
            name: 'Consumer Discretionary',
            changePercent: 2.58,
            totalValue: 50000,
            stocks: [
              _stock(
                symbol: 'TITAN',
                sector: 'Consumer Discretionary',
                changePercent: 2.58,
                marketValue: 50000,
              ),
            ],
          ),
          _sector(
            name: 'Information Technology',
            changePercent: -3.26,
            totalValue: 40000,
          ),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Consumer Discretionary',
            weightPercentage: 35,
            marketCap: 350000,
            topStocks: const ['TITAN'],
          ),
          SectorWeight(
            sectorName: 'Information Technology',
            weightPercentage: 30,
            marketCap: 300000,
            topStocks: const ['TCS'],
          ),
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 35,
            marketCap: 350000,
            topStocks: const ['HDFCBANK'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );
      final names = data.tiles.map((t) => t.name).toSet();
      expect(names.contains('Unknown'), isFalse);
      expect(names.contains('Consumer Discretionary'), isTrue);
      expect(names.contains('Information Technology'), isTrue);
      expect(names.contains('Financial Services'), isTrue);
    });

    test('prod-like zero-value heatmap sectors use allocation fallback', () {
      // Mirrors PROD: many sector names but only ~2 have totalValue > 0 (~5.7% mass).
      final heatmap = Heatmap(
        sectors: [
          _sector(name: 'Unknown', changePercent: 2.3, totalValue: 31885),
          _sector(
            name: 'Financial Services',
            changePercent: 0.22,
            totalValue: 21655,
          ),
          _sector(name: 'Information Technology', changePercent: 0, totalValue: 0),
          _sector(name: 'Healthcare', changePercent: 0, totalValue: 0),
          _sector(name: 'Energy', changePercent: 0, totalValue: 0),
        ],
      );
      final allocation = SectorAllocation(
        sectorWeights: [
          SectorWeight(
            sectorName: 'Financial Services',
            weightPercentage: 40,
            marketCap: 400000,
            topStocks: const ['HDFCBANK'],
          ),
          SectorWeight(
            sectorName: 'Information Technology',
            weightPercentage: 30,
            marketCap: 300000,
            topStocks: const ['TCS'],
          ),
          SectorWeight(
            sectorName: 'Healthcare',
            weightPercentage: 20,
            marketCap: 200000,
            topStocks: const ['CIPLA'],
          ),
          SectorWeight(
            sectorName: 'Energy',
            weightPercentage: 10,
            marketCap: 100000,
            topStocks: const ['RELIANCE'],
          ),
        ],
        industryWeights: const [],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        sectorAllocation: allocation,
        showSubCards: false,
      );
      expect(data.tiles.length, greaterThanOrEqualTo(3));
      final financeTile =
          data.tiles.firstWhere((t) => t.name == 'Financial Services');
      expect(financeTile.value, closeTo(400000, 0.01));
    });

    test('invalid sectors become Unknown tile not Other', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Unknown',
            changePercent: 1.0,
            totalValue: 40000,
            stocks: [
              _stock(
                symbol: 'FOO',
                sector: 'Unknown',
                changePercent: 1.0,
                marketValue: 40000,
              ),
            ],
          ),
          _sector(
            name: 'Financial Services',
            changePercent: 2.0,
            totalValue: 60000,
          ),
        ],
      );
      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        showSubCards: false,
      );
      final names = data.tiles.map((t) => t.name).toSet();
      expect(names.contains('Unknown'), isTrue);
      expect(names.contains('Other'), isFalse);
    });

    test('treemap merge keeps SEBI MF category shells under 3%', () {
      final tiles = [
        HeatmapTileData(
          id: 'sector_big',
          name: 'Financial Services',
          displayName: 'Finance',
          weightage: 40,
          performance: 1.0,
          value: 40000,
        ),
        HeatmapTileData(
          id: 'sector_mf_liquid',
          name: 'Liquid',
          displayName: 'Liquid',
          weightage: 1.2,
          performance: 0.1,
          value: 1200,
          metadata: const {
            'type': 'sector',
            'mfCategory': 'liquid',
            'schemeCategory': 'Liquid',
          },
        ),
        HeatmapTileData(
          id: 'sector_tiny',
          name: 'Utilities',
          displayName: 'Utilities',
          weightage: 1.5,
          performance: -1.0,
          value: 1500,
        ),
      ];
      final merged =
          SectorHeatmapConverter.mergeSmallWeightTilesForTreemap(tiles);
      final names = merged.map((t) => t.name).toSet();
      expect(names.contains('Liquid'), isTrue);
      expect(names.contains('Utilities'), isFalse);
      expect(names.contains('Other (<3%)'), isTrue);
    });

    test('compact budget on MF drill keeps category shells and schemes', () {
      HeatmapTileData scheme(String id, String name, double value) =>
          HeatmapTileData(
            id: 'stock_$id',
            name: id,
            displayName: name,
            weightage: value,
            performance: -0.5,
            value: value,
            metadata: const {'type': 'stock', 'assetClass': 'MUTUAL_FUND'},
          );

      final equity = HeatmapTileData(
        id: 'sector_mf_broad_equity',
        name: 'Equity',
        displayName: 'Equity',
        weightage: 70,
        performance: -0.8,
        value: 70000,
        metadata: const {
          'type': 'sector',
          'mfBroadGroup': 'equity',
        },
        children: [
          HeatmapTileData(
            id: 'sector_mf_flexiCap',
            name: 'Flexi Cap',
            displayName: 'Flexi Cap',
            weightage: 60,
            performance: -1.2,
            value: 42000,
            metadata: const {
              'type': 'sector',
              'mfCategory': 'flexiCap',
              'schemeCategory': 'Flexi Cap',
            },
            children: [
              scheme('INF1', 'Franklin India Flexi Cap Fund', 25000),
              scheme('INF2', 'Parag Parikh Flexi Cap Fund', 17000),
            ],
          ),
          HeatmapTileData(
            id: 'sector_mf_smallCap',
            name: 'Small Cap',
            displayName: 'Small Cap',
            weightage: 40,
            performance: -0.7,
            value: 28000,
            metadata: const {
              'type': 'sector',
              'mfCategory': 'smallCap',
              'schemeCategory': 'Small Cap',
            },
            children: [
              scheme('INF3', 'Motilal Oswal Small Cap Fund', 28000),
            ],
          ),
        ],
      );

      final budgeted = SectorHeatmapConverter.applyCompactTreemapBudget(
        [equity],
        maxStocksPerSector: 2,
      );
      expect(budgeted, hasLength(1));
      final cats = budgeted.single.children!;
      expect(cats.map((c) => c.displayName), ['Flexi Cap', 'Small Cap']);
      expect(cats.first.children!.map((c) => c.displayName), [
        'Franklin India Flexi Cap Fund',
        'Parag Parikh Flexi Cap Fund',
      ]);
      expect(cats.last.children!.single.displayName,
          'Motilal Oswal Small Cap Fund');
    });

    test('treemap merge folds sub-3% sectors into Other (<3%)', () {
      final tiles = [
        HeatmapTileData(
          id: 'a',
          name: 'Financial Services',
          displayName: 'Finance',
          weightage: 40,
          performance: 1.0,
          value: 40000,
        ),
        HeatmapTileData(
          id: 'b',
          name: 'Energy',
          displayName: 'Energy',
          weightage: 35,
          performance: 0.5,
          value: 35000,
        ),
        HeatmapTileData(
          id: 'c',
          name: 'Utilities',
          displayName: 'Utilities',
          weightage: 2,
          performance: -1.0,
          value: 2000,
        ),
        HeatmapTileData(
          id: 'd',
          name: 'Services',
          displayName: 'Services',
          weightage: 1.5,
          performance: 0.2,
          value: 1500,
        ),
      ];
      final merged =
          SectorHeatmapConverter.mergeSmallWeightTilesForTreemap(tiles);
      final names = merged.map((t) => t.name).toSet();
      expect(names.contains('Other (<3%)'), isTrue);
      expect(names.contains('Utilities'), isFalse);
      expect(names.contains('Services'), isFalse);
      expect(names.contains('Financial Services'), isTrue);
    });

    test('Other (<3%) keeps sector holdings for drill-in', () {
      final tiles = [
        HeatmapTileData(
          id: 'sector_big',
          name: 'Financial Services',
          displayName: 'Finance',
          weightage: 40,
          performance: 1.0,
          value: 40000,
          metadata: const {'type': 'sector'},
          children: [
            HeatmapTileData(
              id: 's1',
              name: 'HDFCBANK',
              displayName: 'HDFC Bank',
              weightage: 40,
              performance: 1.0,
              value: 40000,
              metadata: const {'type': 'stock'},
            ),
          ],
        ),
        HeatmapTileData(
          id: 'sector_tiny',
          name: 'Utilities',
          displayName: 'Utilities',
          weightage: 2,
          performance: -1.0,
          value: 2000,
          metadata: const {'type': 'sector'},
          children: [
            HeatmapTileData(
              id: 'u1',
              name: 'NTPC',
              displayName: 'NTPC',
              weightage: 2,
              performance: -1.0,
              value: 2000,
              metadata: const {'type': 'stock'},
            ),
          ],
        ),
      ];
      final merged =
          SectorHeatmapConverter.mergeSmallWeightTilesForTreemap(tiles);
      final other = merged.firstWhere(
        (t) => t.name == SectorHeatmapConverter.otherSmallWeightName,
      );
      expect(other.children, isNotNull);
      expect(other.children!.length, 1);
      final util = other.children!.first;
      expect(util.name, 'Utilities');
      expect(util.metadata?['type'], 'sector');
      expect(util.children, isNotNull);
      expect(util.children!.single.name, 'NTPC');
    });

    test('compact budget merges small sectors and caps stocks per sector', () {
      final stockChildren = List.generate(
        20,
        (i) => HeatmapTileData(
          id: 's$i',
          name: 'SYM$i',
          displayName: 'SYM$i',
          weightage: 20.0 - i,
          performance: 0.1 * i,
          value: 1000.0 * (20 - i),
          metadata: const {'type': 'stock'},
        ),
      );
      final tiles = [
        HeatmapTileData(
          id: 'fin',
          name: 'Financial Services',
          displayName: 'Finance',
          weightage: 50,
          performance: 1.0,
          value: 50000,
          children: stockChildren,
        ),
        HeatmapTileData(
          id: 'tiny',
          name: 'Utilities',
          displayName: 'Utilities',
          weightage: 2,
          performance: -1.0,
          value: 2000,
          children: [
            HeatmapTileData(
              id: 'u1',
              name: 'UTIL1',
              displayName: 'UTIL1',
              weightage: 2,
              performance: -1.0,
              value: 2000,
              metadata: const {'type': 'stock'},
            ),
          ],
        ),
      ];

      final budgeted =
          SectorHeatmapConverter.applyCompactTreemapBudget(tiles);
      final names = budgeted.map((t) => t.name).toSet();
      expect(names.contains('Other (<3%)'), isTrue);
      expect(names.contains('Utilities'), isFalse);

      final finance =
          budgeted.firstWhere((t) => t.name == 'Financial Services');
      final kids = finance.children!;
      expect(kids.length, 16); // top 15 + Other leaf
      expect(kids.last.name, SectorHeatmapConverter.otherStocksName);
      expect(kids.last.children, isNull);
      expect(kids.last.metadata?['mergedStockTail'], isTrue);
      expect(kids.last.metadata?['stockCount'], 5);

      final fatSector = [
        HeatmapTileData(
          id: 'fin2',
          name: 'Financial Services',
          displayName: 'Finance',
          weightage: 50,
          performance: 1.0,
          value: 50000,
          children: List.generate(
            28,
            (i) => HeatmapTileData(
              id: 'w$i',
              name: 'WEB$i',
              displayName: 'WEB$i',
              weightage: 28.0 - i,
              performance: 0.1,
              value: 1000,
              metadata: const {'type': 'stock'},
            ),
          ),
        ),
      ];
      final webBudgeted = SectorHeatmapConverter.applyCompactTreemapBudget(
        fatSector,
        maxStocksPerSector: SectorHeatmapConverter.webMaxStocksPerSector,
      );
      final webKids = webBudgeted.first.children!;
      expect(webKids.length, 21); // top 20 + Other leaf
      expect(webKids.last.name, SectorHeatmapConverter.otherStocksName);
      expect(webKids.last.metadata?['stockCount'], 8);
    });

    test('Top/Weakest ignore flat sectors when non-flat exist', () {
      final tiles = [
        HeatmapTileData(
          id: 'a',
          name: 'Financial Services',
          displayName: 'Finance',
          weightage: 40,
          performance: 1.5,
          value: 40000,
        ),
        HeatmapTileData(
          id: 'b',
          name: 'Telecommunication',
          displayName: 'Telecom',
          weightage: 5,
          performance: 0.0,
          value: 5000,
        ),
        HeatmapTileData(
          id: 'c',
          name: 'Energy',
          displayName: 'Energy',
          weightage: 30,
          performance: -2.0,
          value: 30000,
        ),
      ];
      final summary = SectorHeatmapConverter.resolveSectorSummary(tiles: tiles);
      expect(summary.topSector, 'Financial Services');
      expect(summary.worstSector, 'Energy');
    });

    test('INF scheme tiles prefer companyName over truncated ISIN', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Mutual Funds',
            changePercent: 0.38,
            totalValue: 100000,
            stocks: [
              Stock(
                symbol: 'INF247L01999',
                companyName: 'Motilal Oswal Large and Midcap Fund',
                lastPrice: 40.67,
                changeAmount: 0.15,
                changePercent: 0.38,
                sector: 'Mutual Funds',
                marketValue: 100000,
                quantity: 2460,
                previousClose: 40.52,
              ),
            ],
          ),
        ],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        showSubCards: true,
      );
      final mf = data.tiles.firstWhere((t) => t.name == 'Mutual Funds');
      final child = mf.children!.first;
      expect(
        child.displayName,
        'Motilal Oswal Large and Midcap Fund',
      );
      expect(child.displayName.contains('INF247'), isFalse);
      expect(child.displayName.contains('…'), isFalse);
      expect(child.performance, closeTo(0.38, 0.001));
    });

    test('equity and ETF tiles use trading symbols not legal names', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Information Technology',
            changePercent: 1.4,
            totalValue: 100000,
            stocks: [
              Stock(
                symbol: 'TCS',
                companyName:
                    'TATA CONSULTANCY SERVICES LIMITED EQUITY SHARES WITH FACE VALUE RS. 1/- AFTER SUB-DIVISION',
                lastPrice: 2400,
                changeAmount: 30,
                changePercent: 1.4,
                sector: 'Information Technology',
                marketValue: 88000,
                quantity: 413,
              ),
            ],
          ),
          _sector(
            name: 'Exchange Traded Funds (ETFs)',
            changePercent: 0.4,
            totalValue: 50000,
            stocks: [
              Stock(
                symbol: 'NIFTYBEES',
                companyName: 'NIPPON INDIA ETF NIFTY BEES',
                lastPrice: 288,
                changeAmount: 1,
                changePercent: 0.4,
                sector: 'Exchange Traded Funds (ETFs)',
                marketValue: 50000,
                quantity: 4497,
              ),
            ],
          ),
        ],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        showSubCards: true,
      );
      final it = data.tiles.firstWhere((t) => t.name == 'Information Technology');
      final etf = data.tiles.firstWhere(
        (t) => t.name.contains('Exchange Traded Funds'),
      );
      expect(it.children!.first.displayName, 'TCS');
      expect(etf.children!.first.displayName, 'NIFTYBEES');
    });

    test('keeps full Consumer Discretionary label and sector holdings meta', () {
      final heatmap = Heatmap(
        sectors: [
          _sector(
            name: 'Consumer Discretionary',
            changePercent: 1.2,
            totalValue: 250000,
            stocks: [
              Stock(
                symbol: 'TITAN',
                companyName: 'Titan',
                lastPrice: 100,
                changeAmount: 1,
                changePercent: 1.2,
                sector: 'Consumer Discretionary',
                marketValue: 150000,
                quantity: 10,
              ),
              Stock(
                symbol: 'ASIANPAINT',
                companyName: 'Asian Paints',
                lastPrice: 100,
                changeAmount: 0.5,
                changePercent: 0.5,
                sector: 'Consumer Discretionary',
                marketValue: 100000,
                quantity: 5,
              ),
            ],
          ),
          _sector(
            name: 'Energy',
            changePercent: -0.5,
            totalValue: 50000,
            stocks: [
              _stock(
                symbol: 'ONGC',
                sector: 'Energy',
                changePercent: -0.5,
                marketValue: 50000,
              ),
            ],
          ),
        ],
      );

      final data = SectorHeatmapConverter.convertToHeatmapData(
        heatmap: heatmap,
        showSubCards: false,
      );
      final consumer = data.tiles
          .firstWhere((t) => t.name == 'Consumer Discretionary');

      expect(consumer.displayName, 'Consumer Discretionary');
      expect(consumer.displayName.contains('...'), isFalse);
      expect(consumer.value, closeTo(250000, 0.01));
      expect(consumer.metadata?['holdingsCount'], 2);
      expect(consumer.metadata?['totalQuantity'], closeTo(15, 0.01));
    });
  });
}
