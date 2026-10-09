import 'package:am_common/am_common.dart' hide ApiClient;
import 'package:am_market_sdk/market/api.dart';
import 'package:get_it/get_it.dart';

class SecuritiesHit {
  const SecuritiesHit({
    required this.symbol,
    required this.name,
    this.category = 'STOCKS',
  });

  final String symbol;
  final String name;
  final String category;
}

/// Live instrument search via market gateway (same path as SmartSearchAnchor).
class SecuritiesSearchAdapter {
  SecuritiesSearchAdapter({this.limit = 8});

  final int limit;

  Future<List<SecuritiesHit>> search(
    String query, {
    String category = 'ALL',
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final client = ApiClient(basePath: EnvDomains.market);
    try {
      if (GetIt.I.isRegistered<SecureStorageService>()) {
        final token = await GetIt.I<SecureStorageService>().getAccessToken();
        if (token != null && token.isNotEmpty) {
          client.addDefaultHeader('Authorization', 'Bearer $token');
        }
      }
    } catch (_) {}

    try {
      final results = await SecurityExplorerApi(client).search(
        trimmed,
        smartRecommendations: true,
        category: category,
        limit: limit,
      );
      if (results == null) return const [];
      return results
          .map((doc) {
            final symbol = doc.key?.symbol?.trim() ?? '';
            if (symbol.isEmpty) return null;
            final name = doc.metadata?.companyName?.trim();
            return SecuritiesHit(
              symbol: symbol.toUpperCase(),
              name: (name == null || name.isEmpty) ? symbol : name,
            );
          })
          .whereType<SecuritiesHit>()
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Securities search failed: $e',
        tag: 'SecuritiesSearchAdapter',
      );
      return const [];
    }
  }
}
