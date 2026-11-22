import 'package:am_design_system/shared/models/heatmap/heatmap_tile_data.dart';
import 'package:flutter/material.dart';

/// Heatmap mosaic scope: equity stocks, mutual-fund schemes, or both.
enum HeatmapAssetFilter {
  equity,
  mutualFunds,
  allAssets,
}

/// MF scheme category filter (shown only when [HeatmapAssetFilter.mutualFunds]).
enum HeatmapMfCategory {
  all,
  equity,
  debt,
  hybrid,
  other,
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

/// Keep leaves that match [filter]. A sector with no matching leaves is dropped,
/// including equity shells such as IT when the filter is Mutual Funds.
///
/// Mutual Funds tab flattens schemes to top-level tiles (no "Mutual Funds"
/// sector shell) so treemap/grid/list show funds directly.
List<HeatmapTileData> filterHeatmapTilesByAsset(
  List<HeatmapTileData> tiles,
  HeatmapAssetFilter filter,
) {
  if (filter == HeatmapAssetFilter.allAssets) return tiles;

  final wantMf = filter == HeatmapAssetFilter.mutualFunds;
  final portfolioTotal = tiles.fold<double>(
    0,
    (sum, tile) => sum + (tile.value ?? 0),
  );

  if (wantMf) {
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
    final mfTotal = schemes.fold<double>(
      0,
      (sum, tile) => sum + (tile.value ?? 0),
    );
    return schemes
        .map(
          (leaf) {
            final value = leaf.value ?? 0;
            return leaf.copyWith(
              weightage: mfTotal > 0 ? (value / mfTotal) * 100 : leaf.weightage,
            );
          },
        )
        .toList();
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

extension HeatmapMfCategoryX on HeatmapMfCategory {
  String get displayName {
    switch (this) {
      case HeatmapMfCategory.all:
        return 'All Categories';
      case HeatmapMfCategory.equity:
        return 'Equity';
      case HeatmapMfCategory.debt:
        return 'Debt';
      case HeatmapMfCategory.hybrid:
        return 'Hybrid';
      case HeatmapMfCategory.other:
        return 'Other';
    }
  }

  IconData get icon => Icons.account_tree_outlined;

  /// Best-effort category from scheme / tile label until API category exists.
  static HeatmapMfCategory inferFromLabel(String label) {
    final s = label.toLowerCase();
    if (s.contains('debt') ||
        s.contains('liquid') ||
        s.contains('overnight') ||
        s.contains('gilt') ||
        s.contains('bond') ||
        s.contains('income') ||
        s.contains('money market')) {
      return HeatmapMfCategory.debt;
    }
    if (s.contains('hybrid') ||
        s.contains('balanced') ||
        s.contains('arbitrage') ||
        s.contains('multi asset')) {
      return HeatmapMfCategory.hybrid;
    }
    if (s.contains('equity') ||
        s.contains('large') ||
        s.contains('mid') ||
        s.contains('small') ||
        s.contains('flexi') ||
        s.contains('multi cap') ||
        s.contains('focused') ||
        s.contains('elss') ||
        s.contains('index') ||
        s.contains('value') ||
        s.contains('growth') ||
        s.contains('fund')) {
      return HeatmapMfCategory.equity;
    }
    return HeatmapMfCategory.other;
  }

  bool matchesLabel(String label) {
    if (this == HeatmapMfCategory.all) return true;
    return HeatmapMfCategoryX.inferFromLabel(label) == this;
  }
}
