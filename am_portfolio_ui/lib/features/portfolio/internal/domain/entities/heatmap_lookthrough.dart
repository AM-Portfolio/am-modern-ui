import 'package:am_design_system/am_design_system.dart';

/// Response from GET .../heatmap/lookthrough.
class HeatmapLookthrough {
  const HeatmapLookthrough({
    required this.available,
    required this.sectors,
    this.schemeIsin,
    this.schemeName,
    this.schemeSymbol,
    this.source,
    this.schemeValue,
  });

  factory HeatmapLookthrough.fromJson(Map<String, dynamic> json) {
    final sectorsRaw = json['sectors'];
    final sectors = <LookthroughSector>[];
    if (sectorsRaw is List) {
      for (final item in sectorsRaw) {
        if (item is Map) {
          sectors.add(
            LookthroughSector.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return HeatmapLookthrough(
      available: json['available'] == true,
      schemeIsin: json['schemeIsin'] as String?,
      schemeName: json['schemeName'] as String?,
      schemeSymbol: json['schemeSymbol'] as String?,
      source: json['source'] as String?,
      schemeValue: (json['schemeValue'] as num?)?.toDouble(),
      sectors: sectors,
    );
  }

  final bool available;
  final String? schemeIsin;
  final String? schemeName;
  final String? schemeSymbol;
  final String? source;
  final double? schemeValue;
  final List<LookthroughSector> sectors;

  /// Build a drill parent tile (sector shells → stock leaves).
  HeatmapTileData toDrillTile(HeatmapTileData from) {
    final title = (schemeName != null && schemeName!.trim().isNotEmpty)
        ? schemeName!.trim()
        : (from.displayName.isNotEmpty ? from.displayName : from.name);
    final sectorTiles = <HeatmapTileData>[];
    for (final sector in sectors) {
      final holdings = <HeatmapTileData>[];
      for (final h in sector.holdings) {
        holdings.add(
          HeatmapTileData(
            id: 'lt_${schemeIsin ?? from.id}_${h.isin ?? h.symbol ?? h.name}',
            name: (h.symbol != null && h.symbol!.isNotEmpty)
                ? h.symbol!
                : h.name,
            displayName: h.name,
            weightage: h.weightPct,
            performance: 0,
            value: h.value,
            metadata: {
              'type': 'stock',
              if (h.isin != null) 'isin': h.isin,
              if (h.symbol != null) 'symbol': h.symbol,
              'parentSector': sector.sector,
              'lookthroughLeaf': true,
            },
          ),
        );
      }
      sectorTiles.add(
        HeatmapTileData(
          id: 'lt_sector_${schemeIsin ?? from.id}_${sector.sector}',
          name: sector.sector,
          displayName: sector.sector,
          weightage: sector.weightPct,
          performance: 0,
          value: sector.value,
          metadata: {
            'type': 'sector',
            'sectorName': sector.sector,
            'lookthrough': true,
            'holdingsCount': holdings.length,
          },
          children: holdings,
        ),
      );
    }
    return HeatmapTileData(
      id: 'lt_fund_${schemeIsin ?? from.id}',
      name: title,
      displayName: title,
      weightage: from.weightage,
      performance: from.performance,
      value: schemeValue ?? from.value,
      metadata: {
        'type': 'sector',
        'lookthrough': true,
        'schemeIsin': schemeIsin,
        'source': source,
        'holdingsCount': sectorTiles.fold<int>(
          0,
          (n, s) => n + (s.children?.length ?? 0),
        ),
      },
      children: sectorTiles,
    );
  }
}

class LookthroughSector {
  const LookthroughSector({
    required this.sector,
    required this.weightPct,
    required this.holdings,
    this.value,
  });

  factory LookthroughSector.fromJson(Map<String, dynamic> json) {
    final holdingsRaw = json['holdings'];
    final holdings = <LookthroughHolding>[];
    if (holdingsRaw is List) {
      for (final item in holdingsRaw) {
        if (item is Map) {
          holdings.add(
            LookthroughHolding.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return LookthroughSector(
      sector: (json['sector'] as String?)?.trim().isNotEmpty == true
          ? json['sector'] as String
          : 'Unknown',
      weightPct: (json['weightPct'] as num?)?.toDouble() ?? 0,
      value: (json['value'] as num?)?.toDouble(),
      holdings: holdings,
    );
  }

  final String sector;
  final double weightPct;
  final double? value;
  final List<LookthroughHolding> holdings;
}

class LookthroughHolding {
  const LookthroughHolding({
    required this.name,
    required this.weightPct,
    this.isin,
    this.symbol,
    this.value,
  });

  factory LookthroughHolding.fromJson(Map<String, dynamic> json) {
    final name = (json['name'] as String?)?.trim();
    final symbol = (json['symbol'] as String?)?.trim();
    return LookthroughHolding(
      name: (name != null && name.isNotEmpty)
          ? name
          : (symbol != null && symbol.isNotEmpty ? symbol : 'Holding'),
      weightPct: (json['weightPct'] as num?)?.toDouble() ?? 0,
      isin: (json['isin'] as String?)?.trim(),
      symbol: symbol,
      value: (json['value'] as num?)?.toDouble(),
    );
  }

  final String name;
  final double weightPct;
  final String? isin;
  final String? symbol;
  final double? value;
}
