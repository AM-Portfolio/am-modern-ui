import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Surfaces that can show Buy/Sell affordances.
enum PaperBuySellSurface { chartChrome, watchlist, portfolio, positions }

/// When watchlist B/S is allowed relative to the desk mid-tab.
enum WatchlistBuySellMidTabPolicy { chart, always, never }

/// Typed config for paper chart B/S placement + trade lines (asset-driven).
@immutable
class PaperChartTradeUiConfig {
  const PaperChartTradeUiConfig({
    required this.showOnChartChrome,
    required this.showOnWatchlist,
    required this.watchlistOnlyWhenMidTab,
    required this.showOnPortfolio,
    required this.showOnPositions,
    required this.tradeLinesEnabled,
    required this.defaultOrderType,
    required this.defaultQuantity,
    required this.enabledOrderTypes,
    required this.placeFromWatchlistBuySell,
    required this.cancelOrderOnLineDelete,
    required this.replaceOnDrag,
    required this.marketKeepsLine,
  });

  factory PaperChartTradeUiConfig.defaults() => const PaperChartTradeUiConfig(
        showOnChartChrome: false,
        showOnWatchlist: true,
        watchlistOnlyWhenMidTab: WatchlistBuySellMidTabPolicy.chart,
        showOnPortfolio: false,
        showOnPositions: true,
        tradeLinesEnabled: true,
        defaultOrderType: 'LIMIT',
        defaultQuantity: '1',
        enabledOrderTypes: ['MARKET', 'LIMIT', 'STOP', 'SUPER', 'TRAIL'],
        placeFromWatchlistBuySell: true,
        cancelOrderOnLineDelete: true,
        replaceOnDrag: true,
        marketKeepsLine: false,
      );

  factory PaperChartTradeUiConfig.fromJson(Map<String, dynamic> json) {
    final buy = Map<String, dynamic>.from(json['buySell'] as Map? ?? const {});
    final lines =
        Map<String, dynamic>.from(json['tradeLines'] as Map? ?? const {});
    final types = (lines['enabledOrderTypes'] as List?)
            ?.map((e) => '$e'.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toList() ??
        PaperChartTradeUiConfig.defaults().enabledOrderTypes;
    return PaperChartTradeUiConfig(
      showOnChartChrome: buy['showOnChartChrome'] as bool? ?? false,
      showOnWatchlist: buy['showOnWatchlist'] as bool? ?? true,
      watchlistOnlyWhenMidTab: _parseMidTabPolicy(
        buy['watchlistOnlyWhenMidTab'] as String?,
      ),
      showOnPortfolio: buy['showOnPortfolio'] as bool? ?? false,
      showOnPositions: buy['showOnPositions'] as bool? ?? true,
      tradeLinesEnabled: lines['enabled'] as bool? ?? true,
      defaultOrderType:
          (lines['defaultOrderType'] as String? ?? 'LIMIT').toUpperCase(),
      defaultQuantity: _parseQty(lines['defaultQuantity']),
      enabledOrderTypes: types,
      placeFromWatchlistBuySell:
          lines['placeFromWatchlistBuySell'] as bool? ?? true,
      cancelOrderOnLineDelete:
          lines['cancelOrderOnLineDelete'] as bool? ?? true,
      replaceOnDrag: lines['replaceOnDrag'] as bool? ?? true,
      marketKeepsLine: lines['marketKeepsLine'] as bool? ?? false,
    );
  }

  static WatchlistBuySellMidTabPolicy _parseMidTabPolicy(String? raw) {
    switch ((raw ?? 'chart').trim().toLowerCase()) {
      case 'always':
        return WatchlistBuySellMidTabPolicy.always;
      case 'never':
        return WatchlistBuySellMidTabPolicy.never;
      case 'chart':
      default:
        return WatchlistBuySellMidTabPolicy.chart;
    }
  }

  static String _parseQty(Object? raw) {
    final s = '$raw'.trim();
    if (s.isEmpty || s == 'null') return '1';
    final n = num.tryParse(s);
    if (n == null || n <= 0) return '1';
    return n == n.roundToDouble() ? '${n.round()}' : '$n';
  }

  /// Load from Flutter asset; falls back to [defaults] on failure.
  static Future<PaperChartTradeUiConfig> loadAsset({
    String assetPath = 'packages/am_paper_ui/assets/config/paper_chart_trade_ui.json',
  }) async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final map = jsonDecode(raw);
      if (map is Map<String, dynamic>) {
        return PaperChartTradeUiConfig.fromJson(map);
      }
      if (map is Map) {
        return PaperChartTradeUiConfig.fromJson(
          Map<String, dynamic>.from(map),
        );
      }
    } catch (_) {
      try {
        final raw = await rootBundle.loadString(
          'assets/config/paper_chart_trade_ui.json',
        );
        final map = jsonDecode(raw);
        if (map is Map) {
          return PaperChartTradeUiConfig.fromJson(
            Map<String, dynamic>.from(map),
          );
        }
      } catch (_) {}
    }
    return PaperChartTradeUiConfig.defaults();
  }

  final bool showOnChartChrome;
  final bool showOnWatchlist;
  final WatchlistBuySellMidTabPolicy watchlistOnlyWhenMidTab;
  final bool showOnPortfolio;
  final bool showOnPositions;
  final bool tradeLinesEnabled;
  final String defaultOrderType;
  final String defaultQuantity;
  final List<String> enabledOrderTypes;
  final bool placeFromWatchlistBuySell;
  final bool cancelOrderOnLineDelete;
  final bool replaceOnDrag;
  final bool marketKeepsLine;

  /// Single interpreter for B/S visibility — keep product rules out of widgets.
  bool showBuySell(
    PaperBuySellSurface surface, {
    String? midTab,
  }) {
    switch (surface) {
      case PaperBuySellSurface.chartChrome:
        return showOnChartChrome;
      case PaperBuySellSurface.portfolio:
        return showOnPortfolio;
      case PaperBuySellSurface.positions:
        return showOnPositions;
      case PaperBuySellSurface.watchlist:
        if (!showOnWatchlist) return false;
        switch (watchlistOnlyWhenMidTab) {
          case WatchlistBuySellMidTabPolicy.always:
            return true;
          case WatchlistBuySellMidTabPolicy.never:
            return false;
          case WatchlistBuySellMidTabPolicy.chart:
            return (midTab ?? '').trim().toLowerCase() == 'chart';
        }
    }
  }

  String resolveDefaultOrderType() {
    final fav = defaultOrderType.toUpperCase();
    if (enabledOrderTypes.contains(fav)) return fav;
    return enabledOrderTypes.isNotEmpty ? enabledOrderTypes.first : 'LIMIT';
  }

  String resolveDefaultQuantity() {
    final q = defaultQuantity.trim();
    if (q.isEmpty) return '1';
    final n = num.tryParse(q);
    if (n == null || n <= 0) return '1';
    return q;
  }
}

/// Injects [PaperChartTradeUiConfig] for the paper desk subtree.
class PaperChartTradeUiScope extends InheritedWidget {
  const PaperChartTradeUiScope({
    super.key,
    required this.config,
    required super.child,
  });

  final PaperChartTradeUiConfig config;

  static PaperChartTradeUiConfig of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PaperChartTradeUiScope>();
    return scope?.config ?? PaperChartTradeUiConfig.defaults();
  }

  static PaperChartTradeUiConfig? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<PaperChartTradeUiScope>()
        ?.config;
  }

  @override
  bool updateShouldNotify(PaperChartTradeUiScope oldWidget) =>
      oldWidget.config != config;
}
