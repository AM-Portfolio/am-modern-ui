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
  });
}
