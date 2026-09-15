import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cache for option chain responses to ensure instant tab switching (< 10ms)
final _optionChainCache = <String, Map<String, dynamic>>{};

/// Fetches the option chain for the active symbol with instant cached responses.
final optionChainProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final symbol = ref.watch(foActiveSymbolProvider);
  if (symbol == null || symbol.trim().isEmpty) return null;
  final expiryDate = ref.watch(foSelectedExpiryProvider);

  final cacheKey = '${symbol.toUpperCase().trim()}_${expiryDate ?? ''}';

  // Return cached result immediately if available to prevent UI delay
  if (_optionChainCache.containsKey(cacheKey)) {
    // Background refresh in un-blocking manner if needed
    _fetchAndCacheOptionChain(symbol, expiryDate, cacheKey);
    return _optionChainCache[cacheKey];
  }

  return await _fetchAndCacheOptionChain(symbol, expiryDate, cacheKey);
});

Future<Map<String, dynamic>?> _fetchAndCacheOptionChain(
    String symbol, String? expiryDate, String cacheKey) async {
  try {
    final sdkService = MarketDataSdkService();
    final result = await sdkService.marketDataApi.getOptionChain(symbol, expiryDate: expiryDate);
    if (result != null && result.isNotEmpty) {
      final cleanSym = symbol.toUpperCase().trim();
      _optionChainCache[cacheKey] = result;
      _optionChainCache['${cleanSym}_'] = result;
      final retExp = result['expiry']?.toString();
      if (retExp != null && retExp.isNotEmpty) {
        _optionChainCache['${cleanSym}_$retExp'] = result;
      }
    }
    return result ?? _optionChainCache[cacheKey];
  } catch (_) {
    return _optionChainCache[cacheKey];
  }
}

