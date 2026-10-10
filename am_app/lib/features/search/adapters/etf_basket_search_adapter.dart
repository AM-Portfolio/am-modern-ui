import 'package:am_portfolio_ui/features/basket/data/services/etf_search_service.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/etf_search_result.dart';

class EtfBasketHit {
  const EtfBasketHit({
    required this.title,
    required this.subtitle,
    required this.result,
  });

  final String title;
  final String subtitle;
  final EtfSearchResult result;
}

/// ETF / theme search for Baskets context (reuses portfolio ETF client).
class EtfBasketSearchAdapter {
  EtfBasketSearchAdapter({EtfSearchService? service}) : _service = service;

  EtfSearchService? _service;

  EtfSearchService get _resolvedService => _service ??= EtfSearchService();

  Future<List<EtfBasketHit>> search(String query, {int limit = 8}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    try {
      final results = await _resolvedService.searchEtfs(trimmed, limit: limit);
      return results
          .map(
            (r) => EtfBasketHit(
              title: r.name.isNotEmpty ? r.name : r.symbol,
              subtitle: [
                if (r.symbol.isNotEmpty) r.symbol,
                if (r.assetClass != null && r.assetClass!.isNotEmpty)
                  r.assetClass!,
              ].join(' · '),
              result: r,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
