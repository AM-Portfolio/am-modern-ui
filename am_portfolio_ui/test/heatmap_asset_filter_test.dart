import 'package:am_design_system/shared/models/heatmap/heatmap_tile_data.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/mappers/sector_heatmap_converter.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/models/heatmap_asset_filter.dart';
import 'package:flutter_test/flutter_test.dart';

HeatmapTileData _leaf({
  required String name,
  required String symbol,
  required double value,
  String? assetClass,
  String? sector,
  String? displayName,
  double performance = 1,
}) {
  return HeatmapTileData(
    id: 'stock_$symbol',
    name: name,
    displayName: displayName ?? name,
    weightage: 100,
    performance: performance,
    value: value,
    metadata: {
      'type': 'stock',
      'symbol': symbol,
      if (assetClass != null) 'assetClass': assetClass,
      if (sector != null) 'sector': sector,
      if (sector != null) 'parentSector': sector,
    },
  );
}

HeatmapTileData _sector({
  required String name,
  required double value,
  List<HeatmapTileData>? children,
}) {
  return HeatmapTileData(
    id: 'sector_$name',
    name: name,
    displayName: name,
    weightage: value,
    performance: 1,
    value: value,
    metadata: const {'type': 'sector'},
    children: children,
  );
}

void main() {
  group('HeatmapAssetFilter', () {
    test('detects Mutual Funds sector and INF scheme symbols', () {
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'Mutual Funds',
          displayName: 'Mutual Funds',
        ),
        isTrue,
      );
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'INF247L01999',
          displayName: 'Motilal Oswal',
          symbol: 'INF247L01999',
        ),
        isTrue,
      );
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'TCS',
          displayName: 'TCS',
          symbol: 'TCS',
          sector: 'Information Technology',
        ),
        isFalse,
      );
    });

    test('display names match product chrome', () {
      expect(HeatmapAssetFilter.equity.displayName, 'Equity');
      expect(HeatmapAssetFilter.etfs.displayName, 'ETFs');
      expect(HeatmapAssetFilter.mutualFunds.displayName, 'Mutual Funds');
      expect(HeatmapAssetFilter.allAssets.displayName, 'All Assets');
      expect(HeatmapAssetFilter.etfs.apiAssetScope, 'ETF');
      expect(HeatmapAssetFilter.equity.apiAssetScope, 'EQUITY');
    });

    test('asset class marks a scheme even without an INF isin', () {
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'HDFC Flexi Cap',
          displayName: 'HDFC Flexi Cap',
          symbol: 'HDFCFLEXI',
          assetClass: 'MUTUAL_FUND',
        ),
        isTrue,
      );
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'TCS',
          displayName: 'TCS',
          symbol: 'TCS',
          assetClass: 'EQUITY',
        ),
        isFalse,
      );
    });

    test('All Assets nests Mutual Funds | Stocks with categories and sectors', () {
      final tiles = filterHeatmapTilesByAsset(
        [
          _sector(
            name: 'Information Technology',
            value: 500,
            children: [
              _leaf(name: 'TCS', symbol: 'TCS', value: 500, assetClass: 'EQUITY'),
            ],
          ),
          _sector(
            name: 'Mutual Funds',
            value: 1500,
            children: [
              _leaf(
                name: 'INF247L01999',
                symbol: 'INF247L01999',
                displayName: 'Motilal Oswal Large Cap Fund',
                value: 600,
                assetClass: 'MUTUAL_FUND',
              ),
              _leaf(
                name: 'INF966L01689',
                symbol: 'INF966L01689',
                displayName: 'Quant Small Cap Fund',
                value: 400,
                assetClass: 'MUTUAL_FUND',
              ),
              _leaf(
                name: 'INF179K01VI0',
                symbol: 'INF179K01VI0',
                displayName: 'HDFC Liquid Fund',
                value: 500,
                assetClass: 'MUTUAL_FUND',
              ),
            ],
          ),
        ],
        HeatmapAssetFilter.allAssets,
      );

      expect(tiles.map((t) => t.displayName), ['Mutual Funds', 'Stocks']);
      final mf = tiles.firstWhere((t) => t.displayName == 'Mutual Funds');
      final stocks = tiles.firstWhere((t) => t.displayName == 'Stocks');
      expect(mf.weightage, closeTo(75, 0.01));
      expect(stocks.weightage, closeTo(25, 0.01));
      expect(mf.children!.map((c) => c.displayName), ['Equity', 'Debt']);
      expect(stocks.children!.single.displayName, 'Information Technology');
      final equity = mf.children!.firstWhere((t) => t.displayName == 'Equity');
      expect(equity.metadata?['mfBroadGroup'], 'equity');
      // Equity bucket = Large Cap 600 + Small Cap 400 = 1000 of 1500 MF.
      expect(equity.weightage, closeTo(1000 / 1500 * 100, 0.01));
      final largeCap =
          equity.children!.firstWhere((t) => t.displayName == 'Large Cap');
      // Nested category weight vs Equity bucket.
      expect(largeCap.weightage, closeTo(60, 0.01));
      expect(largeCap.children!.single.displayName, 'Motilal Oswal Large Cap Fund');
      final debt = mf.children!.firstWhere((t) => t.displayName == 'Debt');
      expect(debt.children!.single.displayName, 'Liquid');
    });

    test('All Assets peels NIFTYBEES out of Financial Services into ETFs', () {
      final tiles = filterHeatmapTilesByAsset(
        [
          _sector(
            name: 'Financial Services',
            value: 1620000,
            children: [
              _leaf(
                name: 'NIFTYBEES',
                symbol: 'NIFTYBEES',
                displayName: 'NIPPON INDIA ETF NIFTY BEES',
                value: 1299408,
                sector: 'Financial Services',
                assetClass: 'EQUITY',
              ),
              _leaf(
                name: 'HDFCBANK',
                symbol: 'HDFCBANK',
                value: 320592,
                sector: 'Financial Services',
                assetClass: 'EQUITY',
              ),
            ],
          ),
          _sector(
            name: 'Exchange Traded Funds (ETFs)',
            value: 1307435,
            children: [
              _leaf(
                name: 'MOSMALL250',
                symbol: 'MOSMALL250',
                value: 562221,
                sector: 'Exchange Traded Funds (ETFs)',
                assetClass: 'ETF',
              ),
              _leaf(
                name: 'MIDCAPETF',
                symbol: 'MIDCAPETF',
                value: 745214,
                sector: 'Exchange Traded Funds (ETFs)',
                assetClass: 'ETF',
              ),
            ],
          ),
          _sector(
            name: 'Mutual Funds',
            value: 8928576,
            children: [
              _leaf(
                name: 'INF247L01999',
                symbol: 'INF247L01999',
                displayName: 'Motilal Oswal Large Cap Fund',
                value: 8928576,
                assetClass: 'MUTUAL_FUND',
              ),
            ],
          ),
        ],
        HeatmapAssetFilter.allAssets,
      );

      expect(tiles.map((t) => t.displayName), ['Mutual Funds', 'Stocks', 'ETFs']);
      final stocks = tiles.firstWhere((t) => t.displayName == 'Stocks');
      final etfs = tiles.firstWhere((t) => t.displayName == 'ETFs');
      expect(stocks.value, closeTo(320592, 0.01));
      expect(etfs.value, closeTo(1299408 + 1307435, 0.01));
      expect(stocks.weightage, closeTo(320592 / (320592 + 1299408 + 1307435 + 8928576) * 100, 0.05));
      expect(etfs.weightage, closeTo((1299408 + 1307435) / (320592 + 1299408 + 1307435 + 8928576) * 100, 0.05));
      final stockSector = stocks.children!.single;
      expect(stockSector.displayName, 'Financial Services');
      expect(
        stockSector.children!.map((c) => c.name),
        ['HDFCBANK'],
      );
      final etfNames = etfs.children!
          .expand((c) => c.children ?? const [])
          .map((c) => c.name)
          .toList();
      expect(etfNames, containsAll(['NIFTYBEES', 'MOSMALL250', 'MIDCAPETF']));
      expect(etfNames, isNot(contains('HDFCBANK')));
    });

    test('All Assets lifts ETFs beside Stocks and Mutual Funds', () {
      final tiles = filterHeatmapTilesByAsset(
        [
          _sector(
            name: 'Information Technology',
            value: 500,
            children: [
              _leaf(name: 'TCS', symbol: 'TCS', value: 500, assetClass: 'EQUITY'),
            ],
          ),
          _sector(
            name: 'Exchange Traded Funds (ETFs)',
            value: 300,
            children: [
              _leaf(
                name: 'NIFTYBEES',
                symbol: 'NIFTYBEES',
                value: 300,
                sector: 'Exchange Traded Funds (ETFs)',
                assetClass: 'ETF',
              ),
            ],
          ),
          _sector(
            name: 'Mutual Funds',
            value: 200,
            children: [
              _leaf(
                name: 'INF247L01999',
                symbol: 'INF247L01999',
                displayName: 'Motilal Oswal Large Cap Fund',
                value: 200,
                assetClass: 'MUTUAL_FUND',
              ),
            ],
          ),
        ],
        HeatmapAssetFilter.allAssets,
      );

      expect(tiles.map((t) => t.displayName), ['Mutual Funds', 'Stocks', 'ETFs']);
      final mf = tiles.firstWhere((t) => t.displayName == 'Mutual Funds');
      final stocks = tiles.firstWhere((t) => t.displayName == 'Stocks');
      final etfs = tiles.firstWhere((t) => t.displayName == 'ETFs');
      expect(mf.weightage, closeTo(20, 0.01));
      expect(stocks.weightage, closeTo(50, 0.01));
      expect(etfs.weightage, closeTo(30, 0.01));
      expect(stocks.children!.single.displayName, 'Information Technology');
      expect(etfs.children!.single.displayName, 'Exchange Traded Funds (ETFs)');
      expect(
        stocks.children!
            .any((c) => c.displayName.contains('Exchange Traded')),
        isFalse,
      );
    });

    test('Mutual Funds filter nests Equity|Debt|Hybrid then SEBI categories', () {
      final tiles = filterHeatmapTilesByAsset(
        [
          _sector(
            name: 'Information Technology',
            value: 400,
            children: [
              _leaf(name: 'TCS', symbol: 'TCS', value: 400, assetClass: 'EQUITY'),
            ],
          ),
          _sector(
            name: 'Mutual Funds',
            value: 1500,
            children: [
              _leaf(
                name: 'INF247L01999',
                symbol: 'INF247L01999',
                displayName: 'Motilal Oswal Large Cap Fund',
                value: 600,
                assetClass: 'MUTUAL_FUND',
                performance: 1.0,
              ),
              _leaf(
                name: 'INF879O01027',
                symbol: 'INF879O01027',
                displayName: 'Edelweiss Mid Cap Fund',
                value: 300,
                assetClass: 'MUTUAL_FUND',
                performance: -0.5,
              ),
              _leaf(
                name: 'INF966L01689',
                symbol: 'INF966L01689',
                displayName: 'Quant Small Cap Fund',
                value: 300,
                assetClass: 'MUTUAL_FUND',
                performance: -2.0,
              ),
              _leaf(
                name: 'INF179K01VI0',
                symbol: 'INF179K01VI0',
                displayName: 'HDFC Liquid Fund',
                value: 200,
                assetClass: 'MUTUAL_FUND',
                performance: 0.5,
              ),
              _leaf(
                name: 'INF109KC1AH2',
                symbol: 'INF109KC1AH2',
                displayName: 'ICICI Prudential Equity & Debt Aggressive Hybrid Fund',
                value: 100,
                assetClass: 'MUTUAL_FUND',
                performance: 0.2,
              ),
            ],
          ),
          _sector(name: 'Information Technology', value: 100),
        ],
        HeatmapAssetFilter.mutualFunds,
      );

      expect(tiles.map((t) => t.displayName), ['Equity', 'Debt', 'Hybrid']);
      expect(tiles.every((t) => t.id.startsWith('sector_mf_broad_')), isTrue);
      expect(tiles.every((t) => t.metadata?['mfBroadGroup'] != null), isTrue);
      final equity = tiles.firstWhere((t) => t.displayName == 'Equity');
      expect(equity.children!.map((c) => c.displayName), [
        'Large Cap',
        'Mid Cap',
        'Small Cap',
      ]);
      expect(equity.children!.first.children!.single.displayName,
          'Motilal Oswal Large Cap Fund');
      final hybrid = tiles.firstWhere((t) => t.displayName == 'Hybrid');
      expect(hybrid.children!.single.displayName, 'Aggressive Hybrid');
      expect(hybrid.children!.single.children!.single.displayName,
          'ICICI Prudential Equity & Debt Aggressive Hybrid Fund');
    });

    test('inferFromLabel covers ELSS Index FoF Overnight', () {
      expect(
        HeatmapMfCategoryX.inferFromLabel('HDFC ELSS Tax Saver'),
        HeatmapMfCategory.elss,
      );
      expect(
        HeatmapMfCategoryX.inferFromLabel('Motilal Oswal Nifty 50 Index Fund'),
        HeatmapMfCategory.indexFund,
      );
      expect(
        HeatmapMfCategoryX.inferFromLabel(
          'Franklin U.S. Opportunities Equity Active Fund of Funds',
        ),
        HeatmapMfCategory.fofOverseas,
      );
      expect(
        HeatmapMfCategoryX.inferFromLabel('UTI Overnight Fund'),
        HeatmapMfCategory.overnight,
      );
    });

    test('IT / TCS is equity not mutual fund', () {
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'Information Technology',
          displayName: 'Information Technology',
        ),
        isFalse,
      );
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'TCS',
          displayName: 'TCS',
          symbol: 'TCS',
          parentSector: 'Information Technology',
          sector: 'Information Technology',
        ),
        isFalse,
      );
    });

    test('ETFs are equity-side even when symbol is an INF ISIN', () {
      expect(
        HeatmapAssetFilterX.isEtfTile(
          name: 'INF204KB17I5',
          displayName: 'NIPPON INDIA ETF NIFTY BEES',
          symbol: 'INF204KB17I5',
          sector: 'Exchange Traded Funds (ETFs)',
        ),
        isTrue,
      );
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'INF204KB17I5',
          displayName: 'NIPPON INDIA ETF NIFTY BEES',
          symbol: 'INF204KB17I5',
          sector: 'Exchange Traded Funds (ETFs)',
        ),
        isFalse,
      );
      expect(
        HeatmapAssetFilterX.isMutualFundTile(
          name: 'NIFTYBEES',
          displayName: 'NIFTYBEES',
          symbol: 'NIFTYBEES',
          sector: 'Exchange Traded Funds (ETFs)',
        ),
        isFalse,
      );
    });

    test('performance filter keeps only gainers or losers', () {
      final mixed = [
        HeatmapTileData(
          id: 'g',
          name: 'Gainer',
          displayName: 'Gainer',
          weightage: 60,
          performance: 1.2,
          value: 600,
        ),
        HeatmapTileData(
          id: 'l',
          name: 'Loser',
          displayName: 'Loser',
          weightage: 40,
          performance: -0.8,
          value: 400,
        ),
        HeatmapTileData(
          id: 'f',
          name: 'Flat',
          displayName: 'Flat',
          weightage: 10,
          performance: 0,
          value: 100,
        ),
      ];

      final gainers = filterHeatmapTilesByPerformance(
        mixed,
        HeatmapPerformanceFilter.gainers,
      );
      final losers = filterHeatmapTilesByPerformance(
        mixed,
        HeatmapPerformanceFilter.losers,
      );

      expect(gainers.map((t) => t.name), ['Gainer']);
      expect(gainers.single.weightage, closeTo(100, 0.01));
      expect(losers.map((t) => t.name), ['Loser']);
      expect(losers.single.weightage, closeTo(100, 0.01));
    });

    test('performance filter strips loser stocks inside gainer sectors', () {
      final sector = HeatmapTileData(
        id: 'sector_Consumer',
        name: 'Consumer Discretionary',
        displayName: 'Consumer Discretionary',
        weightage: 100,
        performance: 0.5,
        value: 1000,
        metadata: const {'type': 'sector'},
        children: [
          HeatmapTileData(
            id: 'vbl',
            name: 'VBL',
            displayName: 'VBL',
            weightage: 70,
            performance: 1.66,
            value: 700,
          ),
          HeatmapTileData(
            id: 'arem',
            name: 'ARE&M',
            displayName: 'ARE&M',
            weightage: 30,
            performance: -1.44,
            value: 300,
          ),
        ],
      );

      final gainers = filterHeatmapTilesByPerformance(
        [sector],
        HeatmapPerformanceFilter.gainers,
      );

      expect(gainers, hasLength(1));
      expect(gainers.single.children, hasLength(1));
      expect(gainers.single.children!.single.name, 'VBL');
      expect(gainers.single.value, closeTo(700, 0.01));
    });

    test('Equity drops ETF sector; ETFs filter keeps NIFTYBEES mosaic', () {
      final etfSector = _sector(
        name: 'Exchange Traded Funds (ETFs)',
        value: 1300000,
        children: [
          _leaf(
            name: 'NIFTYBEES',
            symbol: 'NIFTYBEES',
            value: 1254626,
            sector: 'Exchange Traded Funds (ETFs)',
            assetClass: 'ETF',
          ),
          _leaf(
            name: 'GOLDBEES',
            symbol: 'GOLDBEES',
            displayName: 'Nippon India ETF Gold BeES',
            value: 42533,
            sector: 'Exchange Traded Funds (ETFs)',
            assetClass: 'ETF',
          ),
        ],
      );
      final itSector = _sector(
        name: 'Information Technology',
        value: 1000000,
        children: [
          _leaf(
            name: 'TCS',
            symbol: 'TCS',
            value: 1000000,
            sector: 'Information Technology',
            assetClass: 'EQUITY',
          ),
        ],
      );

      final equity = filterHeatmapTilesByAsset(
        [etfSector, itSector],
        HeatmapAssetFilter.equity,
      );
      final etfs = filterHeatmapTilesByAsset(
        [etfSector, itSector],
        HeatmapAssetFilter.etfs,
      );
      final mf = filterHeatmapTilesByAsset(
        [etfSector],
        HeatmapAssetFilter.mutualFunds,
      );

      expect(mf, isEmpty);
      expect(equity, hasLength(1));
      expect(equity.single.name, 'Information Technology');
      expect(equity.single.children!.single.name, 'TCS');
      expect(etfs, isNotEmpty);
      final etfNames = etfs
          .expand((s) => s.children ?? const <HeatmapTileData>[])
          .map((c) => c.name)
          .toList();
      if (etfNames.isEmpty) {
        expect(etfs.map((t) => t.name), anyOf(contains('NIFTYBEES'), contains('ETFs'),
            contains('Exchange Traded Funds (ETFs)')));
      } else {
        expect(etfNames, containsAll(['NIFTYBEES', 'GOLDBEES']));
        expect(etfNames, isNot(contains('TCS')));
      }
    });

    test('Equity filter reweights to sleeve so Other(<3%) is not full-book NAV',
        () {
      // MF-heavy book: equity sectors are tiny % of total but large % of equity.
      final mfSector = _sector(
        name: 'Mutual Funds',
        value: 9000000,
        children: [
          _leaf(
            name: 'HDFC Flexi Cap',
            symbol: 'INF179K01BE2',
            value: 9000000,
            assetClass: 'MUTUAL_FUND',
            sector: 'Mutual Funds',
          ),
        ],
      );
      final it = _sector(
        name: 'Information Technology',
        value: 400000,
        children: [
          _leaf(
            name: 'TCS',
            symbol: 'TCS',
            value: 400000,
            assetClass: 'EQUITY',
            sector: 'Information Technology',
          ),
        ],
      );
      final banks = _sector(
        name: 'Financial Services',
        value: 350000,
        children: [
          _leaf(
            name: 'HDFCBANK',
            symbol: 'HDFCBANK',
            value: 350000,
            assetClass: 'EQUITY',
            sector: 'Financial Services',
          ),
        ],
      );
      final energy = _sector(
        name: 'Energy',
        value: 200000,
        children: [
          _leaf(
            name: 'RELIANCE',
            symbol: 'RELIANCE',
            value: 200000,
            assetClass: 'EQUITY',
            sector: 'Energy',
          ),
        ],
      );
      final tiny = _sector(
        name: 'Utilities',
        value: 10000,
        children: [
          _leaf(
            name: 'NTPC',
            symbol: 'NTPC',
            value: 10000,
            assetClass: 'EQUITY',
            sector: 'Utilities',
          ),
        ],
      );

      final equity = filterHeatmapTilesByAsset(
        [mfSector, it, banks, energy, tiny],
        HeatmapAssetFilter.equity,
      );
      expect(equity.map((t) => t.name), isNot(contains('Mutual Funds')));

      // Sleeve total = 960k → banks ~36%, energy ~21%, utilities ~1%.
      final banksTile = equity.firstWhere((t) => t.name == 'Financial Services');
      expect(banksTile.weightage, greaterThan(30));
      expect(banksTile.weightage, lessThan(40));

      final merged =
          SectorHeatmapConverter.mergeSmallWeightTilesForTreemap(equity);
      final names = merged.map((t) => t.name).toSet();
      expect(names, contains('Financial Services'));
      expect(names, contains('Energy'));
      expect(names, contains('Information Technology'));
      expect(names, contains('Other (<3%)'));
      expect(names, isNot(contains('Utilities')));
    });
  });
}
