import 'package:am_design_system/shared/models/heatmap/heatmap_tile_data.dart';
import 'package:flutter/material.dart';

/// Heatmap mosaic scope: equity stocks, mutual-fund schemes, or both.
enum HeatmapAssetFilter {
  equity,
  mutualFunds,
  allAssets,
}

/// SEBI broad groups (Mutual Funds mosaic top level).
/// Matches backend [MutualFundSchemeCategory.broadGroup].
enum HeatmapMfBroadGroup {
  equity,
  debt,
  hybrid,
  other,
}

/// SEBI-style MF scheme categories (heatmap parents + dropdown).
/// Display names must match backend [MutualFundSchemeCategory].
enum HeatmapMfCategory {
  all,
  multiCap,
  largeCap,
  largeAndMidCap,
  midCap,
  smallCap,
  flexiCap,
  dividendYield,
  value,
  contra,
  focused,
  sectoral,
  thematic,
  elss,
  overnight,
  liquid,
  ultraShortDuration,
  lowDuration,
  moneyMarket,
  shortDuration,
  mediumDuration,
  mediumToLongDuration,
  longDuration,
  dynamicBond,
  corporateBond,
  creditRisk,
  bankingAndPsu,
  gilt,
  floater,
  conservativeHybrid,
  balancedHybrid,
  aggressiveHybrid,
  dynamicAssetAllocation,
  multiAssetAllocation,
  arbitrage,
  equitySavings,
  indexFund,
  fofDomestic,
  fofOverseas,
  otherMf,
}

/// Day movers filter — overview sectors or drilled-in stocks/schemes.
enum HeatmapPerformanceFilter {
  all,
  gainers,
  losers,
}

extension HeatmapAssetFilterX on HeatmapAssetFilter {
  /// Backend advanced/heatmap {@code assetScope} query/body value.
  String get apiAssetScope {
    switch (this) {
      case HeatmapAssetFilter.equity:
        return 'EQUITY';
      case HeatmapAssetFilter.mutualFunds:
        return 'MUTUAL_FUND';
      case HeatmapAssetFilter.allAssets:
        return 'ALL';
    }
  }

  String get displayName {
    switch (this) {
      case HeatmapAssetFilter.equity:
        return 'Equity';
      case HeatmapAssetFilter.mutualFunds:
        return 'Mutual Funds';
      case HeatmapAssetFilter.allAssets:
        return 'All Assets';
    }
  }

  IconData get icon {
    switch (this) {
      case HeatmapAssetFilter.equity:
        return Icons.show_chart;
      case HeatmapAssetFilter.mutualFunds:
        return Icons.account_balance_outlined;
      case HeatmapAssetFilter.allAssets:
        return Icons.grid_view_outlined;
    }
  }

  /// Listed ETFs (NIFTYBEES, gold ETF, …) — equity-side, never open-end MF.
  ///
  /// Indian ETF ISINs also start with INF, so ISIN alone must not mark them MF.
  static bool isEtfTile({
    required String name,
    required String displayName,
    String? symbol,
    String? parentSector,
    String? sector,
    String? assetClass,
  }) {
    final cls = (assetClass ?? '')
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    if (cls == 'ETF' || cls.contains('EXCHANGE_TRADED')) return true;
    final hay =
        '$name $displayName ${sector ?? ''} ${parentSector ?? ''}'.toLowerCase();
    if (hay.contains('exchange traded')) return true;
    if (RegExp(r'\betfs?\b').hasMatch(hay)) return true;
    return false;
  }

  /// True when a leaf holding is an open-end mutual fund (not an ETF).
  ///
  /// Sector labels such as Information Technology are not instruments.
  /// Indian MF ISINs are `INF` plus 9 alphanumerics. A name that merely
  /// starts with "INF" (Information Technology) is not a scheme.
  static bool isMutualFundTile({
    required String name,
    required String displayName,
    String? symbol,
    String? parentSector,
    String? sector,
    String? assetClass,
  }) {
    if (isEtfTile(
      name: name,
      displayName: displayName,
      symbol: symbol,
      parentSector: parentSector,
      sector: sector,
      assetClass: assetClass,
    )) {
      return false;
    }
    final cls = (assetClass ?? '')
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[\s-]+'), '_');
    if (cls.isNotEmpty) {
      return cls == 'MF' || cls.contains('MUTUAL');
    }
    if (_isIndianMfIsin(symbol) || _isIndianMfIsin(name)) return true;
    final hay = '$name $displayName'.toLowerCase();
    return hay.contains('mutual fund');
  }
}

bool _isIndianMfIsin(String? raw) {
  if (raw == null) return false;
  return RegExp(r'^INF[A-Z0-9]{8,10}$').hasMatch(raw.trim().toUpperCase());
}

bool _tileIsMutualFund(HeatmapTileData tile) {
  final symbol = tile.metadata?['symbol']?.toString();
  final assetClass = tile.metadata?['assetClass']?.toString() ??
      tile.metadata?['instrument']?.toString();
  final sector = tile.metadata?['sector']?.toString();
  final parentSector = tile.metadata?['parentSector']?.toString();
  return HeatmapAssetFilterX.isMutualFundTile(
    name: tile.name,
    displayName: tile.displayName,
    symbol: symbol == null || symbol.trim().isEmpty ? null : symbol,
    sector: sector,
    parentSector: parentSector,
    assetClass: assetClass,
  );
}

bool _isSectorShell(HeatmapTileData tile) {
  final type = tile.metadata?['type']?.toString();
  return type == 'sector' || tile.id.startsWith('sector_');
}

HeatmapTileData _reweightSector(
  HeatmapTileData tile,
  List<HeatmapTileData> children,
  double portfolioTotal,
) {
  final newValue = children.fold<double>(
    0,
    (sum, child) => sum + (child.value ?? 0),
  );
  return tile.copyWith(
    children: children,
    value: newValue,
    weightage:
        portfolioTotal > 0 ? (newValue / portfolioTotal) * 100 : tile.weightage,
  );
}

double _valueWeightedPerformance(List<HeatmapTileData> children) {
  final total = children.fold<double>(0, (sum, c) => sum + (c.value ?? 0));
  if (total <= 0) return 0;
  return children.fold<double>(
        0,
        (sum, c) => sum + c.performance * (c.value ?? 0),
      ) /
      total;
}

/// Mosaic parent order (excludes [HeatmapMfCategory.all]).
const _mfCategoryOrder = <HeatmapMfCategory>[
  HeatmapMfCategory.multiCap,
  HeatmapMfCategory.largeCap,
  HeatmapMfCategory.largeAndMidCap,
  HeatmapMfCategory.midCap,
  HeatmapMfCategory.smallCap,
  HeatmapMfCategory.flexiCap,
  HeatmapMfCategory.dividendYield,
  HeatmapMfCategory.value,
  HeatmapMfCategory.contra,
  HeatmapMfCategory.focused,
  HeatmapMfCategory.sectoral,
  HeatmapMfCategory.thematic,
  HeatmapMfCategory.elss,
  HeatmapMfCategory.overnight,
  HeatmapMfCategory.liquid,
  HeatmapMfCategory.ultraShortDuration,
  HeatmapMfCategory.lowDuration,
  HeatmapMfCategory.moneyMarket,
  HeatmapMfCategory.shortDuration,
  HeatmapMfCategory.mediumDuration,
  HeatmapMfCategory.mediumToLongDuration,
  HeatmapMfCategory.longDuration,
  HeatmapMfCategory.dynamicBond,
  HeatmapMfCategory.corporateBond,
  HeatmapMfCategory.creditRisk,
  HeatmapMfCategory.bankingAndPsu,
  HeatmapMfCategory.gilt,
  HeatmapMfCategory.floater,
  HeatmapMfCategory.conservativeHybrid,
  HeatmapMfCategory.balancedHybrid,
  HeatmapMfCategory.aggressiveHybrid,
  HeatmapMfCategory.dynamicAssetAllocation,
  HeatmapMfCategory.multiAssetAllocation,
  HeatmapMfCategory.arbitrage,
  HeatmapMfCategory.equitySavings,
  HeatmapMfCategory.indexFund,
  HeatmapMfCategory.fofDomestic,
  HeatmapMfCategory.fofOverseas,
  HeatmapMfCategory.otherMf,
];

const _mfBroadGroupOrder = <HeatmapMfBroadGroup>[
  HeatmapMfBroadGroup.equity,
  HeatmapMfBroadGroup.debt,
  HeatmapMfBroadGroup.hybrid,
  HeatmapMfBroadGroup.other,
];

bool _isMutualFundsBucketName(String? raw) {
  final u = (raw ?? '').trim().toLowerCase();
  return u == 'mutual funds' || u == 'mutual fund' || u == 'mf';
}

bool _isKnownMfCategoryShell(HeatmapTileData tile) {
  if (tile.metadata?['mfBroadGroup'] != null) return false;
  if (tile.id.startsWith('sector_mf_broad_')) return false;
  final label = tile.displayName.trim().isNotEmpty ? tile.displayName : tile.name;
  if (_isMutualFundsBucketName(label)) return false;
  return HeatmapMfCategoryX.fromDisplayName(label) != null;
}

HeatmapMfBroadGroup _broadGroupForCategoryTile(HeatmapTileData tile) {
  final raw = tile.metadata?['mfCategory']?.toString();
  if (raw != null && raw.isNotEmpty) {
    for (final c in HeatmapMfCategory.values) {
      if (c == HeatmapMfCategory.all) continue;
      if (c.name == raw) return c.broadGroup;
    }
  }
  final label =
      tile.displayName.trim().isNotEmpty ? tile.displayName : tile.name;
  final fromName = HeatmapMfCategoryX.fromDisplayName(label);
  if (fromName != null) return fromName.broadGroup;
  return HeatmapMfBroadGroup.other;
}

/// Nest SEBI category shells under Equity | Debt | Hybrid | Other.
///
/// [weightBase] defaults to the categories' total. Category tiles are reweighted
/// vs their broad-group value for nested mosaic labels.
@visibleForTesting
List<HeatmapTileData> nestMfCategoriesUnderBroadGroups(
  List<HeatmapTileData> categoryParents, {
  double? weightBase,
}) {
  if (categoryParents.isEmpty) return const [];

  final mfTotal =
      categoryParents.fold<double>(0, (sum, t) => sum + (t.value ?? 0));
  final base = (weightBase != null && weightBase > 0) ? weightBase : mfTotal;
  final buckets = <HeatmapMfBroadGroup, List<HeatmapTileData>>{
    for (final g in _mfBroadGroupOrder) g: <HeatmapTileData>[],
  };

  for (final cat in categoryParents) {
    buckets
        .putIfAbsent(_broadGroupForCategoryTile(cat), () => <HeatmapTileData>[])
        .add(cat);
  }

  final parents = <HeatmapTileData>[];
  for (final group in _mfBroadGroupOrder) {
    final kids = buckets[group];
    if (kids == null || kids.isEmpty) continue;
    kids.sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

    final groupValue = kids.fold<double>(0, (sum, c) => sum + (c.value ?? 0));
    final nestedKids = kids
        .map(
          (cat) {
            final value = cat.value ?? 0;
            return cat.copyWith(
              weightage:
                  groupValue > 0 ? (value / groupValue) * 100 : cat.weightage,
            );
          },
        )
        .toList();

    final label = group.displayName;
    parents.add(
      HeatmapTileData(
        id: 'sector_mf_broad_${group.name}',
        name: label,
        displayName: label,
        weightage: base > 0 ? (groupValue / base) * 100 : 0,
        performance: _valueWeightedPerformance(nestedKids),
        value: groupValue,
        children: nestedKids,
        metadata: {
          'type': 'sector',
          'sectorName': label,
          'mfBroadGroup': group.name,
          'stockCount': nestedKids.length,
          'holdingsCount': nestedKids.length,
        },
      ),
    );
  }
  return parents;
}

/// Nest MF schemes under SEBI category parents (Mutual Funds tab / All Assets).
///
/// [weightBase] defaults to the schemes' total (MF-only mosaic). Pass the
/// full-book total for All Assets so category tiles size like equity sectors.
@visibleForTesting
List<HeatmapTileData> groupMfSchemesByCategory(
  List<HeatmapTileData> schemes, {
  double? weightBase,
}) {
  if (schemes.isEmpty) return const [];

  final mfTotal = schemes.fold<double>(0, (sum, t) => sum + (t.value ?? 0));
  final base = (weightBase != null && weightBase > 0) ? weightBase : mfTotal;
  final buckets = <HeatmapMfCategory, List<HeatmapTileData>>{
    for (final c in _mfCategoryOrder) c: <HeatmapTileData>[],
  };

  for (final leaf in schemes) {
    final stored = leaf.metadata?['schemeCategory']?.toString() ??
        leaf.metadata?['schemeClass']?.toString() ??
        leaf.metadata?['parentSector']?.toString() ??
        leaf.metadata?['sector']?.toString();
    final fromStored = HeatmapMfCategoryX.fromDisplayName(stored);
    final category = fromStored ??
        HeatmapMfCategoryX.inferFromLabel('${leaf.displayName} ${leaf.name}');
    final bucket =
        category == HeatmapMfCategory.all ? HeatmapMfCategory.otherMf : category;
    buckets.putIfAbsent(bucket, () => <HeatmapTileData>[]).add(leaf);
  }

  final parents = <HeatmapTileData>[];
  for (final category in _mfCategoryOrder) {
    final kids = buckets[category];
    if (kids == null || kids.isEmpty) continue;
    kids.sort((a, b) => (b.value ?? 0).compareTo(a.value ?? 0));

    final categoryValue =
        kids.fold<double>(0, (sum, c) => sum + (c.value ?? 0));
    final weightedKids = kids
        .map(
          (leaf) {
            final value = leaf.value ?? 0;
            return leaf.copyWith(
              weightage: base > 0 ? (value / base) * 100 : leaf.weightage,
            );
          },
        )
        .toList();

    final label = category.displayName;
    parents.add(
      HeatmapTileData(
        id: 'sector_mf_${category.name}',
        name: label,
        displayName: label,
        weightage: base > 0 ? (categoryValue / base) * 100 : 0,
        performance: _valueWeightedPerformance(weightedKids),
        value: categoryValue,
        children: weightedKids,
        metadata: {
          'type': 'sector',
          'sectorName': label,
          'mfCategory': category.name,
          'schemeCategory': label,
          'stockCount': weightedKids.length,
          'holdingsCount': weightedKids.length,
        },
      ),
    );
  }
  return parents;
}

/// SEBI leaves under Equity | Debt | Hybrid | Other.
List<HeatmapTileData> _mfMosaicFromSchemes(
  List<HeatmapTileData> schemes, {
  double? weightBase,
}) {
  return nestMfCategoriesUnderBroadGroups(
    groupMfSchemesByCategory(schemes, weightBase: weightBase),
    weightBase: weightBase,
  );
}

/// All Assets top level: Mutual Funds | Stocks.
/// MF children = Equity|Debt|Hybrid|Other → SEBI categories; Stocks = sectors.
List<HeatmapTileData> _nestAllAssetsByAssetClass(List<HeatmapTileData> tiles) {
  final portfolioTotal = tiles.fold<double>(
    0,
    (sum, tile) => sum + (tile.value ?? 0),
  );

  final schemes = <HeatmapTileData>[];
  final stockSectors = <HeatmapTileData>[];

  for (final tile in tiles) {
    final children = tile.children;
    final isMfBucket = _isMutualFundsBucketName(tile.name) ||
        _isMutualFundsBucketName(tile.displayName);

    if (isMfBucket && children != null && children.isNotEmpty) {
      for (final child in children) {
        final leaf =
            child is HeatmapTileData ? child : HeatmapTileData.fromEntity(child);
        if (_tileIsMutualFund(leaf)) schemes.add(leaf);
      }
      continue;
    }

    if (_isKnownMfCategoryShell(tile)) {
      // SEBI category parents from backend — flatten leaves then regroup.
      final kids = tile.children;
      if (kids != null && kids.isNotEmpty) {
        for (final child in kids) {
          final leaf = child is HeatmapTileData
              ? child
              : HeatmapTileData.fromEntity(child);
          if (_tileIsMutualFund(leaf)) schemes.add(leaf);
        }
      }
      continue;
    }

    // Equity / ETF / Other sectors stay under Stocks.
    stockSectors.add(tile);
  }

  final mfTotal = schemes.fold<double>(0, (s, t) => s + (t.value ?? 0));
  final mfCategories = schemes.isEmpty
      ? const <HeatmapTileData>[]
      : _mfMosaicFromSchemes(schemes, weightBase: mfTotal);

  final out = <HeatmapTileData>[];

  if (mfCategories.isNotEmpty) {
    final mfValue =
        mfCategories.fold<double>(0, (s, t) => s + (t.value ?? 0));
    out.add(
      HeatmapTileData(
        id: 'asset_mutual_funds',
        name: 'Mutual Funds',
        displayName: 'Mutual Funds',
        weightage:
            portfolioTotal > 0 ? (mfValue / portfolioTotal) * 100 : 0,
        performance: _valueWeightedPerformance(mfCategories),
        value: mfValue,
        children: mfCategories,
        metadata: {
          'type': 'sector',
          'sectorName': 'Mutual Funds',
          'assetClassRoot': 'MUTUAL_FUND',
          'stockCount': mfCategories.length,
          'holdingsCount': mfCategories.length,
        },
      ),
    );
  }

  if (stockSectors.isNotEmpty) {
    final stockValue =
        stockSectors.fold<double>(0, (s, t) => s + (t.value ?? 0));
    // Reweight sector shells vs stocks bucket for nested mosaic labels.
    final nestedStocks = stockSectors
        .map(
          (s) => s.copyWith(
            weightage:
                stockValue > 0 ? ((s.value ?? 0) / stockValue) * 100 : s.weightage,
          ),
        )
        .toList();
    out.add(
      HeatmapTileData(
        id: 'asset_stocks',
        name: 'Stocks',
        displayName: 'Stocks',
        weightage:
            portfolioTotal > 0 ? (stockValue / portfolioTotal) * 100 : 0,
        performance: _valueWeightedPerformance(nestedStocks),
        value: stockValue,
        children: nestedStocks,
        metadata: {
          'type': 'sector',
          'sectorName': 'Stocks',
          'assetClassRoot': 'EQUITY',
          'stockCount': nestedStocks.length,
          'holdingsCount': nestedStocks.length,
        },
      ),
    );
  }

  return out;
}

/// Keep leaves that match [filter]. A sector with no matching leaves is dropped,
/// including equity shells such as IT when the filter is Mutual Funds.
///
/// All Assets: Mutual Funds | Stocks at the top; broad groups / sectors nested.
/// Mutual Funds tab: Equity | Debt | Hybrid | Other → SEBI categories.
List<HeatmapTileData> filterHeatmapTilesByAsset(
  List<HeatmapTileData> tiles,
  HeatmapAssetFilter filter,
) {
  if (filter == HeatmapAssetFilter.allAssets) {
    return _nestAllAssetsByAssetClass(tiles);
  }

  final wantMf = filter == HeatmapAssetFilter.mutualFunds;
  final portfolioTotal = tiles.fold<double>(
    0,
    (sum, tile) => sum + (tile.value ?? 0),
  );

  if (wantMf) {
    final hasBackendCategoryShells = tiles.any(_isKnownMfCategoryShell);
    if (hasBackendCategoryShells) {
      final filtered = <HeatmapTileData>[];
      for (final tile in tiles) {
        final children = tile.children;
        if (children != null && children.isNotEmpty) {
          final kept = <HeatmapTileData>[];
          for (final child in children) {
            final leaf = child is HeatmapTileData
                ? child
                : HeatmapTileData.fromEntity(child);
            if (_tileIsMutualFund(leaf)) kept.add(leaf);
          }
          if (kept.isEmpty) continue;
          if (_isMutualFundsBucketName(tile.name) ||
              _isMutualFundsBucketName(tile.displayName)) {
            filtered.addAll(groupMfSchemesByCategory(kept));
          } else {
            filtered.add(_reweightSector(tile, kept, portfolioTotal));
          }
          continue;
        }
        if (_isSectorShell(tile)) continue;
        if (_tileIsMutualFund(tile)) {
          filtered.addAll(groupMfSchemesByCategory([tile]));
        }
      }
      return nestMfCategoriesUnderBroadGroups(filtered);
    }

    final schemes = <HeatmapTileData>[];
    for (final tile in tiles) {
      final children = tile.children;
      if (children != null && children.isNotEmpty) {
        for (final child in children) {
          final leaf = child is HeatmapTileData
              ? child
              : HeatmapTileData.fromEntity(child);
          if (_tileIsMutualFund(leaf)) schemes.add(leaf);
        }
        continue;
      }
      if (_isSectorShell(tile)) continue;
      if (_tileIsMutualFund(tile)) schemes.add(tile);
    }
    return _mfMosaicFromSchemes(schemes);
  }

  final filtered = <HeatmapTileData>[];

  for (final tile in tiles) {
    final children = tile.children;
    if (children != null && children.isNotEmpty) {
      final kept = <HeatmapTileData>[];
      for (final child in children) {
        final leaf = child is HeatmapTileData
            ? child
            : HeatmapTileData.fromEntity(child);
        if (!_tileIsMutualFund(leaf)) kept.add(leaf);
      }
      if (kept.isEmpty) continue;
      filtered.add(_reweightSector(tile, kept, portfolioTotal));
      continue;
    }

    if (!_tileIsMutualFund(tile)) filtered.add(tile);
  }

  return filtered;
}

extension HeatmapPerformanceFilterX on HeatmapPerformanceFilter {
  String get displayName {
    switch (this) {
      case HeatmapPerformanceFilter.all:
        return 'All';
      case HeatmapPerformanceFilter.gainers:
        return 'Gainers';
      case HeatmapPerformanceFilter.losers:
        return 'Losers';
    }
  }

  IconData get icon {
    switch (this) {
      case HeatmapPerformanceFilter.all:
        return Icons.filter_list_rounded;
      case HeatmapPerformanceFilter.gainers:
        return Icons.trending_up_rounded;
      case HeatmapPerformanceFilter.losers:
        return Icons.trending_down_rounded;
    }
  }

  bool matches(double performance) {
    switch (this) {
      case HeatmapPerformanceFilter.all:
        return true;
      case HeatmapPerformanceFilter.gainers:
        return performance > 0;
      case HeatmapPerformanceFilter.losers:
        return performance < 0;
    }
  }
}

/// Keep tiles whose day performance matches [filter].
///
/// Sector shells are kept only when they still have matching descendants;
/// nested losers are stripped under Gainers (and vice versa), then reweighted.
List<HeatmapTileData> filterHeatmapTilesByPerformance(
  List<HeatmapTileData> tiles,
  HeatmapPerformanceFilter filter,
) {
  if (filter == HeatmapPerformanceFilter.all) return tiles;

  HeatmapTileData? filterNode(HeatmapTileData tile) {
    final children = tile.children;
    if (children != null && children.isNotEmpty) {
      final keptChildren = <HeatmapTileData>[];
      for (final child in children) {
        final leaf = child is HeatmapTileData
            ? child
            : HeatmapTileData.fromEntity(child);
        final filtered = filterNode(leaf);
        if (filtered != null) keptChildren.add(filtered);
      }
      if (keptChildren.isEmpty) return null;

      final newValue = keptChildren.fold<double>(
        0,
        (sum, child) => sum + (child.value ?? 0),
      );
      final weightedPerf = newValue > 0
          ? keptChildren.fold<double>(
                0,
                (sum, child) =>
                    sum + child.performance * (child.value ?? 0),
              ) /
              newValue
          : tile.performance;

      return tile.copyWith(
        children: keptChildren,
        value: newValue,
        performance: weightedPerf,
      );
    }

    return filter.matches(tile.performance) ? tile : null;
  }

  final kept = <HeatmapTileData>[];
  for (final tile in tiles) {
    final filtered = filterNode(tile);
    if (filtered != null) kept.add(filtered);
  }
  if (kept.isEmpty) return kept;

  final total = kept.fold<double>(0, (sum, t) => sum + (t.value ?? 0));
  if (total <= 0) return kept;

  return kept
      .map(
        (tile) => tile.copyWith(
          weightage: ((tile.value ?? 0) / total) * 100,
        ),
      )
      .toList();
}

extension HeatmapMfBroadGroupX on HeatmapMfBroadGroup {
  String get displayName {
    switch (this) {
      case HeatmapMfBroadGroup.equity:
        return 'Equity';
      case HeatmapMfBroadGroup.debt:
        return 'Debt';
      case HeatmapMfBroadGroup.hybrid:
        return 'Hybrid';
      case HeatmapMfBroadGroup.other:
        return 'Other';
    }
  }
}

extension HeatmapMfCategoryX on HeatmapMfCategory {
  /// SEBI broad group for mosaic nesting (mirrors backend).
  HeatmapMfBroadGroup get broadGroup {
    switch (this) {
      case HeatmapMfCategory.multiCap:
      case HeatmapMfCategory.largeCap:
      case HeatmapMfCategory.largeAndMidCap:
      case HeatmapMfCategory.midCap:
      case HeatmapMfCategory.smallCap:
      case HeatmapMfCategory.flexiCap:
      case HeatmapMfCategory.dividendYield:
      case HeatmapMfCategory.value:
      case HeatmapMfCategory.contra:
      case HeatmapMfCategory.focused:
      case HeatmapMfCategory.sectoral:
      case HeatmapMfCategory.thematic:
      case HeatmapMfCategory.elss:
        return HeatmapMfBroadGroup.equity;
      case HeatmapMfCategory.overnight:
      case HeatmapMfCategory.liquid:
      case HeatmapMfCategory.ultraShortDuration:
      case HeatmapMfCategory.lowDuration:
      case HeatmapMfCategory.moneyMarket:
      case HeatmapMfCategory.shortDuration:
      case HeatmapMfCategory.mediumDuration:
      case HeatmapMfCategory.mediumToLongDuration:
      case HeatmapMfCategory.longDuration:
      case HeatmapMfCategory.dynamicBond:
      case HeatmapMfCategory.corporateBond:
      case HeatmapMfCategory.creditRisk:
      case HeatmapMfCategory.bankingAndPsu:
      case HeatmapMfCategory.gilt:
      case HeatmapMfCategory.floater:
        return HeatmapMfBroadGroup.debt;
      case HeatmapMfCategory.conservativeHybrid:
      case HeatmapMfCategory.balancedHybrid:
      case HeatmapMfCategory.aggressiveHybrid:
      case HeatmapMfCategory.dynamicAssetAllocation:
      case HeatmapMfCategory.multiAssetAllocation:
      case HeatmapMfCategory.arbitrage:
      case HeatmapMfCategory.equitySavings:
        return HeatmapMfBroadGroup.hybrid;
      case HeatmapMfCategory.all:
      case HeatmapMfCategory.indexFund:
      case HeatmapMfCategory.fofDomestic:
      case HeatmapMfCategory.fofOverseas:
      case HeatmapMfCategory.otherMf:
        return HeatmapMfBroadGroup.other;
    }
  }

  String get displayName {
    switch (this) {
      case HeatmapMfCategory.all:
        return 'All Categories';
      case HeatmapMfCategory.multiCap:
        return 'Multi Cap';
      case HeatmapMfCategory.largeCap:
        return 'Large Cap';
      case HeatmapMfCategory.largeAndMidCap:
        return 'Large & Mid Cap';
      case HeatmapMfCategory.midCap:
        return 'Mid Cap';
      case HeatmapMfCategory.smallCap:
        return 'Small Cap';
      case HeatmapMfCategory.flexiCap:
        return 'Flexi Cap';
      case HeatmapMfCategory.dividendYield:
        return 'Dividend Yield';
      case HeatmapMfCategory.value:
        return 'Value';
      case HeatmapMfCategory.contra:
        return 'Contra';
      case HeatmapMfCategory.focused:
        return 'Focused';
      case HeatmapMfCategory.sectoral:
        return 'Sectoral';
      case HeatmapMfCategory.thematic:
        return 'Thematic';
      case HeatmapMfCategory.elss:
        return 'ELSS';
      case HeatmapMfCategory.overnight:
        return 'Overnight';
      case HeatmapMfCategory.liquid:
        return 'Liquid';
      case HeatmapMfCategory.ultraShortDuration:
        return 'Ultra Short Duration';
      case HeatmapMfCategory.lowDuration:
        return 'Low Duration';
      case HeatmapMfCategory.moneyMarket:
        return 'Money Market';
      case HeatmapMfCategory.shortDuration:
        return 'Short Duration';
      case HeatmapMfCategory.mediumDuration:
        return 'Medium Duration';
      case HeatmapMfCategory.mediumToLongDuration:
        return 'Medium to Long Duration';
      case HeatmapMfCategory.longDuration:
        return 'Long Duration';
      case HeatmapMfCategory.dynamicBond:
        return 'Dynamic Bond';
      case HeatmapMfCategory.corporateBond:
        return 'Corporate Bond';
      case HeatmapMfCategory.creditRisk:
        return 'Credit Risk';
      case HeatmapMfCategory.bankingAndPsu:
        return 'Banking and PSU';
      case HeatmapMfCategory.gilt:
        return 'Gilt';
      case HeatmapMfCategory.floater:
        return 'Floater';
      case HeatmapMfCategory.conservativeHybrid:
        return 'Conservative Hybrid';
      case HeatmapMfCategory.balancedHybrid:
        return 'Balanced Hybrid';
      case HeatmapMfCategory.aggressiveHybrid:
        return 'Aggressive Hybrid';
      case HeatmapMfCategory.dynamicAssetAllocation:
        return 'Dynamic Asset Allocation';
      case HeatmapMfCategory.multiAssetAllocation:
        return 'Multi Asset Allocation';
      case HeatmapMfCategory.arbitrage:
        return 'Arbitrage';
      case HeatmapMfCategory.equitySavings:
        return 'Equity Savings';
      case HeatmapMfCategory.indexFund:
        return 'Index';
      case HeatmapMfCategory.fofDomestic:
        return 'FoF Domestic';
      case HeatmapMfCategory.fofOverseas:
        return 'FoF Overseas';
      case HeatmapMfCategory.otherMf:
        return 'Other MF';
    }
  }

  IconData get icon => Icons.account_tree_outlined;

  static HeatmapMfCategory? fromDisplayName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final n = raw.trim();
    for (final c in HeatmapMfCategory.values) {
      if (c == HeatmapMfCategory.all) continue;
      if (c.displayName.toLowerCase() == n.toLowerCase() ||
          c.name.toLowerCase() == n.toLowerCase()) {
        return c;
      }
    }
    return null;
  }

  /// Best-effort SEBI category from scheme / tile label (mirrors backend resolver).
  static HeatmapMfCategory inferFromLabel(String label) {
    final s = label.toLowerCase();
    if (s.contains('fund of fund') ||
        s.contains('fund of funds') ||
        s.contains(' fof') ||
        s.contains('feeder')) {
      if (s.contains('overseas') ||
          s.contains('u.s') ||
          s.contains('us ') ||
          s.contains('global') ||
          s.contains('international') ||
          s.contains('nasdaq')) {
        return HeatmapMfCategory.fofOverseas;
      }
      return HeatmapMfCategory.fofDomestic;
    }
    if (s.contains('overnight')) return HeatmapMfCategory.overnight;
    if (s.contains('liquid')) return HeatmapMfCategory.liquid;
    if (s.contains('money market')) return HeatmapMfCategory.moneyMarket;
    if (s.contains('ultra short')) return HeatmapMfCategory.ultraShortDuration;
    if (s.contains('low duration')) return HeatmapMfCategory.lowDuration;
    if (s.contains('short duration') || s.contains('short term debt')) {
      return HeatmapMfCategory.shortDuration;
    }
    if (s.contains('medium to long') || s.contains('medium long')) {
      return HeatmapMfCategory.mediumToLongDuration;
    }
    if (s.contains('medium duration') || s.contains('medium term debt')) {
      return HeatmapMfCategory.mediumDuration;
    }
    if (s.contains('long duration') || s.contains('long term debt')) {
      return HeatmapMfCategory.longDuration;
    }
    if (s.contains('dynamic bond')) return HeatmapMfCategory.dynamicBond;
    if (s.contains('corporate bond')) return HeatmapMfCategory.corporateBond;
    if (s.contains('credit risk')) return HeatmapMfCategory.creditRisk;
    if (s.contains('banking and psu') ||
        s.contains('banking & psu') ||
        s.contains('psu debt')) {
      return HeatmapMfCategory.bankingAndPsu;
    }
    if (s.contains('gilt')) return HeatmapMfCategory.gilt;
    if (s.contains('floater') || s.contains('floating rate')) {
      return HeatmapMfCategory.floater;
    }
    if (s.contains('conservative hybrid')) {
      return HeatmapMfCategory.conservativeHybrid;
    }
    if (s.contains('aggressive hybrid')) {
      return HeatmapMfCategory.aggressiveHybrid;
    }
    if (s.contains('balanced hybrid') ||
        (s.contains('balanced') && s.contains('hybrid'))) {
      return HeatmapMfCategory.balancedHybrid;
    }
    if (s.contains('balanced advantage') ||
        s.contains('dynamic asset allocation')) {
      return HeatmapMfCategory.dynamicAssetAllocation;
    }
    if (s.contains('multi asset')) return HeatmapMfCategory.multiAssetAllocation;
    if (s.contains('arbitrage')) return HeatmapMfCategory.arbitrage;
    if (s.contains('equity savings')) return HeatmapMfCategory.equitySavings;
    if (s.contains('hybrid')) return HeatmapMfCategory.aggressiveHybrid;
    if (s.contains('elss') || s.contains('tax saver')) {
      return HeatmapMfCategory.elss;
    }
    if (s.contains('index') ||
        s.contains('sensex') ||
        (s.contains('nifty') && s.contains('momentum'))) {
      return HeatmapMfCategory.indexFund;
    }
    if (s.contains('sectoral') ||
        s.contains('pharma') ||
        s.contains('infrastructure fund') ||
        s.contains('banking fund')) {
      return HeatmapMfCategory.sectoral;
    }
    if (s.contains('thematic') ||
        s.contains('esg') ||
        s.contains('consumption fund')) {
      return HeatmapMfCategory.thematic;
    }
    if (s.contains('dividend yield')) return HeatmapMfCategory.dividendYield;
    if (s.contains('contra')) return HeatmapMfCategory.contra;
    if (s.contains('value fund') || s.contains(' value ')) {
      return HeatmapMfCategory.value;
    }
    if (s.contains('focused')) return HeatmapMfCategory.focused;
    if (s.contains('large & mid') ||
        s.contains('large and mid') ||
        s.contains('large mid')) {
      return HeatmapMfCategory.largeAndMidCap;
    }
    if (s.contains('small cap') || s.contains('smallcap')) {
      return HeatmapMfCategory.smallCap;
    }
    if (s.contains('mid cap') ||
        s.contains('midcap') ||
        s.contains('emerging equity')) {
      return HeatmapMfCategory.midCap;
    }
    if (s.contains('flexi')) return HeatmapMfCategory.flexiCap;
    if (s.contains('multi cap') || s.contains('multicap')) {
      return HeatmapMfCategory.multiCap;
    }
    if (s.contains('large cap') ||
        s.contains('largecap') ||
        s.contains('bluechip') ||
        s.contains('blue chip')) {
      return HeatmapMfCategory.largeCap;
    }
    if (s.contains('bond') || s.contains('debt') || s.contains('income fund')) {
      return HeatmapMfCategory.dynamicBond;
    }
    return HeatmapMfCategory.otherMf;
  }

  bool matchesLabel(String label) {
    if (this == HeatmapMfCategory.all) return true;
    return HeatmapMfCategoryX.inferFromLabel(label) == this;
  }
}
