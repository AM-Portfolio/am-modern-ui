import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/watchlist_model.dart';
import '../data/watchlist_api_client.dart';
import '../../equity_insider/providers/equity_insider_provider.dart';

final watchlistApiClientProvider = Provider<WatchlistApiClient>((ref) {
  return WatchlistApiClient();
});

final watchlistsProvider = AsyncNotifierProvider<WatchlistsNotifier, List<Watchlist>>(
  WatchlistsNotifier.new,
);

class WatchlistsNotifier extends AsyncNotifier<List<Watchlist>> {
  @override
  Future<List<Watchlist>> build() async {
    return _fetchWatchlists();
  }

  Future<List<Watchlist>> _fetchWatchlists() async {
    final client = ref.read(watchlistApiClientProvider);
    final lists = await client.getWatchlists();
    
    // For each list, fetch items to get complete data and counts
    final populatedLists = await Future.wait(lists.map((list) async {
      try {
        final items = await client.getWatchlistItems(list.id);
        return list.copyWith(items: items);
      } catch (e) {
        return list;
      }
    }));
    return populatedLists;
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWatchlists());
  }

  Future<void> createWatchlist(String name) async {
    final client = ref.read(watchlistApiClientProvider);
    await client.createWatchlist(name);
    await refresh();
  }

  Future<void> updateWatchlist(String id, String name) async {
    final client = ref.read(watchlistApiClientProvider);
    await client.updateWatchlist(id, name);
    await refresh();
  }

  Future<void> deleteWatchlist(String id) async {
    final client = ref.read(watchlistApiClientProvider);
    await client.deleteWatchlist(id);
    await refresh();
  }

  Future<void> addStock(String watchlistId, String symbol) async {
    final client = ref.read(watchlistApiClientProvider);
    await client.addStock(watchlistId, symbol);
    await refresh();
  }

  Future<void> removeStock(String watchlistId, String symbol) async {
    final client = ref.read(watchlistApiClientProvider);
    await client.removeStock(watchlistId, symbol);
    await refresh();
  }

  Future<void> moveStock(String sourceWatchlistId, String targetWatchlistId, String symbol) async {
    final client = ref.read(watchlistApiClientProvider);
    await client.removeStock(sourceWatchlistId, symbol);
    await client.addStock(targetWatchlistId, symbol);
    await refresh();
  }
}

final watchlistCheckStatusProvider = FutureProvider.family<List<WatchlistCheckStatus>, String>((ref, symbol) async {
  final client = ref.watch(watchlistApiClientProvider);
  return await client.checkStockInWatchlists(symbol);
});

final watchlistQuotesProvider = FutureProvider.family<Map<String, WatchlistStockQuote>, String>((ref, symbolsKey) async {
  if (symbolsKey.isEmpty) return {};
  final symbols = symbolsKey.split(',').where((s) => s.isNotEmpty).toList();
  if (symbols.isEmpty) return {};

  final client = ref.watch(watchlistApiClientProvider);

  // Fetch live LTP and company names in parallel
  final results = await Future.wait([
    client.getLiveLTP(symbols),
    client.getInstrumentNames(symbols),
  ]);

  final ltpMap = results[0] as Map<String, Map<String, dynamic>>;
  final namesMap = results[1] as Map<String, String>;

  final quotes = <String, WatchlistStockQuote>{};
  for (final sym in symbols) {
    final symUpper = sym.toUpperCase();
    final ltpData = ltpMap[symUpper] ?? ltpMap[sym];
    String companyName = namesMap[symUpper] ?? namesMap[sym] ?? symUpper;

    double lastPrice = 0.0;
    double change = 0.0;
    double changePercent = 0.0;

    if (ltpData != null) {
      final lp = ltpData['lastPrice'] ?? ltpData['ltp'] ?? ltpData['price'] ?? ltpData['currentPrice'];
      if (lp != null) {
        lastPrice = (lp as num).toDouble();
      }

      final chg = ltpData['change'] ?? ltpData['dayChange'] ?? ltpData['netChange'] ?? ltpData['chg'];
      if (chg != null) {
        change = (chg as num).toDouble();
      }

      final pct = ltpData['changePercent'] ?? ltpData['dayChangePercent'] ?? ltpData['pChange'] ?? ltpData['percentChange'] ?? ltpData['pctChange'];
      if (pct != null) {
        changePercent = (pct as num).toDouble();
      }
    }

    // If change data is missing or zero, or lastPrice is 0, or companyName is unpopulated,
    // enrich from fundamentalProfileProvider
    if (lastPrice == 0.0 || (change == 0.0 && changePercent == 0.0) || companyName == symUpper) {
      try {
        final profile = await ref.watch(fundamentalProfileProvider(symUpper).future);
        if (profile != null) {
          if (lastPrice == 0.0 && profile.currentPrice != null && profile.currentPrice! > 0) {
            lastPrice = profile.currentPrice!;
          }
          if (change == 0.0 && profile.dayChange != null) {
            change = profile.dayChange!;
          }
          if (changePercent == 0.0 && profile.dayChangePercent != null) {
            changePercent = profile.dayChangePercent!;
          }
          if (companyName == symUpper && profile.companyName != null && profile.companyName!.isNotEmpty) {
            companyName = profile.companyName!;
          }
        }
      } catch (_) {}
    }

    quotes[symUpper] = WatchlistStockQuote(
      symbol: symUpper,
      companyName: companyName,
      lastPrice: lastPrice,
      change: change,
      changePercent: changePercent,
    );
  }

  return quotes;
});



