import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';

// State for the currently selected F&O symbol
class FoActiveSymbolNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  @override
  set state(String? value) => super.state = value;
}
final foActiveSymbolProvider = NotifierProvider<FoActiveSymbolNotifier, String?>(FoActiveSymbolNotifier.new);

// State for the currently selected F&O expiry date
class FoSelectedExpiryNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  @override
  set state(String? value) => super.state = value;
}
final foSelectedExpiryProvider = NotifierProvider<FoSelectedExpiryNotifier, String?>(FoSelectedExpiryNotifier.new);

// State for recent F&O searches (in a real app, this should be persisted)
class RecentlyViewedFoSymbolsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String symbol) {
    if (!state.contains(symbol)) {
      state = [symbol, ...state].take(10).toList();
    }
  }

  void remove(String symbol) {
    state = state.where((s) => s != symbol).toList();
  }

  void clear() {
    state = const [];
  }
}

final recentlyViewedFoSymbolsProvider =
    NotifierProvider<RecentlyViewedFoSymbolsNotifier, List<String>>(
  RecentlyViewedFoSymbolsNotifier.new,
);

/// Fetches dynamic major index/F&O recommendations from security search API.
final dynamicFoRecommendationsProvider = FutureProvider<List<String>>((ref) async {
  final sdkService = MarketDataSdkService();
  try {
    final results = await sdkService.securityApi.search(
      '',
      smartRecommendations: true,
      category: 'ALL',
      limit: 8,
    );
    if (results != null && results.isNotEmpty) {
      final symbols = results.map((d) => d.key?.symbol).whereType<String>().where((s) => s.isNotEmpty).toList();
      if (symbols.isNotEmpty) return symbols;
    }
  } catch (_) {}
  return const [];
});

