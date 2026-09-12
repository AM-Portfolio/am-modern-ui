import 'dart:async';

import 'package:am_market_ui/features/watchlists/data/watchlist_api_client.dart';
import 'package:flutter/foundation.dart';

import '../../../data/paper_market_client.dart';
import '../../../data/quote_models.dart';
import '../../../data/watchlist_models.dart';

const kNifty50Id = 'nifty-50';
const kWatchlistPageSize = 20;

class WatchlistSource {
  const WatchlistSource({required this.id, required this.name});
  final String id;
  final String name;
}

class WatchlistController extends ChangeNotifier {
  WatchlistController({
    required this.onSelectSymbol,
    PaperMarketClient? client,
    WatchlistApiClient? watchlistApi,
  })  : _client = client ?? PaperMarketClient(),
        _watchlistApi = watchlistApi ?? WatchlistApiClient();

  final ValueChanged<String> onSelectSymbol;
  final PaperMarketClient _client;
  final WatchlistApiClient _watchlistApi;

  final List<WatchlistSource> sources = [
    const WatchlistSource(id: kNifty50Id, name: 'Nifty 50'),
  ];
  String selectedSourceId = kNifty50Id;
  List<WatchlistStock> allRows = [];
  int pageIndex = 0;
  String? hoveredSymbol;
  String? expandedDepthSymbol;
  String? actionSymbol;
  QuoteDetail? depthQuote;
  bool depthLoading = false;
  bool refreshing = false;
  int _quoteGen = 0;
  int? _inflightPage;
  bool loadingList = false;
  String? listError;
  bool quotesUnavailable = false;
  bool _disposed = false;

  bool get isNifty => selectedSourceId == kNifty50Id;

  bool get pageNeedsQuoteSpinner {
    final page = pageRows;
    return page.isNotEmpty && page.every((r) => r.ltp <= 0);
  }

  int get pageCount {
    if (allRows.isEmpty) return 1;
    return ((allRows.length - 1) ~/ kWatchlistPageSize) + 1;
  }

  List<WatchlistStock> get pageRows {
    if (allRows.isEmpty) return const [];
    final start = pageIndex * kWatchlistPageSize;
    if (start >= allRows.length) return const [];
    final end = (start + kWatchlistPageSize).clamp(0, allRows.length);
    return allRows.sublist(start, end);
  }

  WatchlistSource get selectedSource => sources.firstWhere(
        (s) => s.id == selectedSourceId,
        orElse: () => sources.first,
      );

  PaperMarketClient get client => _client;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> bootstrap() async {
    unawaited(loadSources());
    await selectSource(kNifty50Id);
  }

  Future<void> loadSources() async {
    try {
      final lists = await _watchlistApi.getWatchlists();
      if (_disposed) return;
      sources
        ..clear()
        ..add(const WatchlistSource(id: kNifty50Id, name: 'Nifty 50'));
      for (final w in lists) {
        if (w.id.isEmpty) continue;
        sources.add(WatchlistSource(id: w.id, name: w.name));
      }
      _notify();
    } catch (_) {
      if (_disposed) return;
      sources
        ..clear()
        ..add(const WatchlistSource(id: kNifty50Id, name: 'Nifty 50'));
      _notify();
    }
  }

  Future<void> selectSource(String id) async {
    _quoteGen++;
    _inflightPage = null;
    selectedSourceId = id;
    allRows = [];
    pageIndex = 0;
    loadingList = true;
    listError = null;
    hoveredSymbol = null;
    expandedDepthSymbol = null;
    actionSymbol = null;
    depthQuote = null;
    refreshing = false;
    quotesUnavailable = false;
    _notify();

    try {
      List<WatchlistStock> rows;
      if (id == kNifty50Id) {
        rows = await _client.fetchNifty50Constituents();
        if (rows.isEmpty) {
          throw Exception('Could not load Nifty 50 constituents');
        }
      } else {
        final items = await _watchlistApi.getWatchlistItems(id);
        rows = items
            .map((i) => _client.stockFromSymbol(i.symbol))
            .where((s) => s.symbol.isNotEmpty)
            .toList();
      }
      if (_disposed) return;
      allRows = rows;
      loadingList = false;
      listError = null;
      pageIndex = 0;
      _notify();
      await refreshVisibleQuotes();
    } catch (e) {
      if (_disposed) return;
      allRows = [];
      loadingList = false;
      listError = e.toString();
      _notify();
    }
  }

  Future<void> refreshVisibleQuotes() async {
    final currentPageIndex = pageIndex;
    final page = pageRows;
    if (page.isEmpty) return;
    if (_inflightPage == currentPageIndex) return;

    final gen = ++_quoteGen;
    _inflightPage = currentPageIndex;
    final needSpinner = pageNeedsQuoteSpinner;
    refreshing = needSpinner;
    quotesUnavailable = false;
    _notify();

    await for (final chunk in _client.enrichQuotesChunked(List.of(page))) {
      if (_disposed || gen != _quoteGen) {
        if (_inflightPage == currentPageIndex) _inflightPage = null;
        return;
      }
      final bySymbol = {for (final r in chunk) r.symbol: r};
      allRows = [
        for (final r in allRows) mergeQuoteRow(r, bySymbol[r.symbol]),
      ];
      refreshing = false;
      _notify();
    }

    if (_disposed || gen != _quoteGen) {
      if (_inflightPage == currentPageIndex) _inflightPage = null;
      return;
    }

    _inflightPage = null;
    final visible = pageRows;
    quotesUnavailable = visible.isNotEmpty && visible.every((r) => r.ltp <= 0);
    _notify();

    final next = currentPageIndex + 1;
    if (next < pageCount && gen == _quoteGen) {
      unawaited(_prefetchPage(next, gen));
    }
  }

  Future<void> _prefetchPage(int prefetchPageIndex, int gen) async {
    if (allRows.isEmpty) return;
    final start = prefetchPageIndex * kWatchlistPageSize;
    if (start >= allRows.length) return;
    final end = (start + kWatchlistPageSize).clamp(0, allRows.length);
    final page = allRows.sublist(start, end);
    if (page.every((r) => r.ltp > 0)) return;
    final enriched = await _client.enrichQuotes(List.of(page));
    if (_disposed || gen != _quoteGen) return;
    final bySymbol = {for (final r in enriched) r.symbol: r};
    allRows = [
      for (final r in allRows) mergeQuoteRow(r, bySymbol[r.symbol]),
    ];
    _notify();
  }

  WatchlistStock mergeQuoteRow(WatchlistStock current, WatchlistStock? next) {
    if (next == null) return current;
    if (next.ltp <= 0 && current.ltp > 0) return current;
    return next;
  }

  Future<void> setPage(int index) async {
    final clamped = index.clamp(0, pageCount - 1);
    if (clamped == pageIndex) return;
    pageIndex = clamped;
    expandedDepthSymbol = null;
    depthQuote = null;
    refreshing =
        pageRows.every((r) => r.ltp <= 0) && pageRows.isNotEmpty;
    quotesUnavailable = false;
    _notify();
    await refreshVisibleQuotes();
  }

  Future<void> addSymbol(String raw) async {
    final symbol = raw.trim().toUpperCase();
    if (symbol.isEmpty) return;

    WatchlistStock? existing;
    for (final r in allRows) {
      if (r.symbol == symbol) {
        existing = r;
        break;
      }
    }
    if (existing != null) {
      onSelectSymbol(symbol);
      final idx = allRows.indexWhere((r) => r.symbol == symbol);
      if (idx >= 0) await setPage(idx ~/ kWatchlistPageSize);
      return;
    }

    final docs = await _client.search(symbol, limit: 1);
    WatchlistStock row;
    if (docs != null && docs.isNotEmpty) {
      final match = docs.firstWhere(
        (d) => (d.key?.symbol ?? '').toUpperCase() == symbol,
        orElse: () => docs.first,
      );
      row = _client.stockFromDocument(match);
      if (row.symbol.isEmpty) {
        row = _client.stockFromSymbol(symbol);
      }
    } else {
      row = _client.stockFromSymbol(symbol);
    }

    if (!isNifty) {
      try {
        await _watchlistApi.addStock(selectedSourceId, row.symbol);
      } catch (_) {
        // Still show in session if persist fails.
      }
    }

    allRows.insert(0, row);
    pageIndex = 0;
    _notify();
    onSelectSymbol(row.symbol);
    await refreshVisibleQuotes();
  }

  void remove(String symbol) {
    allRows.removeWhere((r) => r.symbol == symbol);
    if (hoveredSymbol == symbol) hoveredSymbol = null;
    if (actionSymbol == symbol) actionSymbol = null;
    if (expandedDepthSymbol == symbol) {
      expandedDepthSymbol = null;
      depthQuote = null;
    }
    if (pageIndex >= pageCount) {
      pageIndex = (pageCount - 1).clamp(0, 9999);
    }
    _notify();
    if (!isNifty) {
      unawaited(_watchlistApi.removeStock(selectedSourceId, symbol));
    }
  }

  Future<void> onCardTap(WatchlistStock stock) async {
    actionSymbol = stock.symbol;
    _notify();
    onSelectSymbol(stock.symbol);
    if (expandedDepthSymbol == stock.symbol) {
      return;
    }
    await openDepth(stock);
  }

  Future<void> openDepth(WatchlistStock stock) async {
    expandedDepthSymbol = stock.symbol;
    depthQuote = null;
    depthLoading = true;
    _notify();
    final detail = await _client.fetchQuoteDetail(
      stock.symbol,
      name: stock.name,
    );
    if (_disposed) return;
    if (expandedDepthSymbol != stock.symbol) return;
    depthQuote = detail;
    depthLoading = false;
    _notify();
  }

  Future<void> pullToRefresh() async {
    await selectSource(selectedSourceId);
  }

  void setHoveredSymbol(String? symbol) {
    hoveredSymbol = symbol;
    _notify();
  }
}
