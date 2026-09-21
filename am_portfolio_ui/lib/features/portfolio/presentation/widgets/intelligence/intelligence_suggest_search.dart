import 'package:am_common/am_common.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:get_it/get_it.dart';

import '../../../internal/data/datasources/portfolio_remote_data_source.dart';
import '../../../internal/domain/entities/portfolio_intelligence.dart';

/// Backend suggest contexts (must match IntelligenceSuggestService).
const kSuggestCtxStressSector = 'STRESS_SECTOR';
const kSuggestCtxWhatIfSymbol = 'WHAT_IF_SYMBOL';
const kSuggestCtxWhatIfSector = 'WHAT_IF_SECTOR';
const kSuggestCtxClassAddName = 'CLASS_ADD_NAME';

String classAddNameHint(String wire) {
  switch (wire) {
    case 'bonds':
      return 'e.g. Sovereign Gold Bond';
    case 'commodities':
      return 'e.g. Sovereign Gold';
    case 'cash':
      return 'e.g. Liquid Fund';
    default:
      return 'Search name…';
  }
}

market.SecurityDocument labelToSecurityDocument(
  String symbol, {
  String? companyName,
}) {
  final sym = symbol.trim();
  final name =
      companyName != null && companyName.trim().isNotEmpty ? companyName.trim() : sym;
  return market.SecurityDocument(
    key: market.SecurityKey(symbol: sym),
    metadata: market.SecurityMetadata(companyName: name),
  );
}

/// Maps backend suggestions into [SecurityDocument]s for [SmartSearchAnchor].
///
/// When [selectLabel] is true (sectors / class names), [key.symbol] is the label
/// and the overlay shows label + optional subtitle. When false (tickers), symbol
/// is selected and subtitle renders as the company line.
List<market.SecurityDocument> suggestItemsToDocuments(
  Iterable<IntelligenceSuggestItem> items, {
  bool selectLabel = true,
}) {
  final out = <market.SecurityDocument>[];
  for (final item in items) {
    final label = item.label.trim();
    if (label.isEmpty) continue;
    final subtitle = item.subtitle?.trim();
    if (selectLabel) {
      out.add(
        labelToSecurityDocument(
          label,
          companyName: subtitle != null && subtitle.isNotEmpty
              ? '$label  ·  $subtitle'
              : label,
        ),
      );
    } else {
      final sym =
          item.symbol?.trim().isNotEmpty == true ? item.symbol!.trim() : label;
      out.add(
        labelToSecurityDocument(
          sym,
          companyName: subtitle != null && subtitle.isNotEmpty ? subtitle : label,
        ),
      );
    }
  }
  return out;
}

/// Context-aware typeahead via GET …/suggest (not a shared UI catalog).
Future<List<market.SecurityDocument>> searchIntelligenceSuggest({
  required PortfolioRemoteDataSource remote,
  required String portfolioId,
  required String context,
  required String query,
  String? wire,
  int limit = 8,
  bool selectLabel = true,
}) async {
  final q = query.trim();
  if (q.isEmpty) return const [];
  try {
    final items = await remote.getIntelligenceSuggest(
      portfolioId,
      context: context,
      query: q,
      wire: wire,
      limit: limit,
    );
    return suggestItemsToDocuments(items, selectLabel: selectLabel);
  } catch (_) {
    return const [];
  }
}

/// Stress custom sector — portfolio + canonical stress labels from backend.
Future<List<market.SecurityDocument>> searchStressSectors({
  required PortfolioRemoteDataSource remote,
  required String portfolioId,
  required String query,
  int limit = 8,
}) {
  return searchIntelligenceSuggest(
    remote: remote,
    portfolioId: portfolioId,
    context: kSuggestCtxStressSector,
    query: query,
    limit: limit,
  );
}

/// What-If switch allocation — only sectors that exist on the book.
Future<List<market.SecurityDocument>> searchWhatIfSectors({
  required PortfolioRemoteDataSource remote,
  required String portfolioId,
  required String query,
  int limit = 8,
}) {
  return searchIntelligenceSuggest(
    remote: remote,
    portfolioId: portfolioId,
    context: kSuggestCtxWhatIfSector,
    query: query,
    limit: limit,
  );
}

/// What-If Add/Modify symbol.
///
/// Holdings come from backend. For **Add**, market search fills remaining slots
/// so new tickers outside the book remain discoverable.
Future<List<market.SecurityDocument>> searchWhatIfSymbols({
  required PortfolioRemoteDataSource remote,
  required String portfolioId,
  required String query,
  bool includeMarket = false,
  Future<List<market.SecurityDocument>?> Function(String query)? marketSearch,
  int limit = 8,
}) async {
  final fromBackend = await searchIntelligenceSuggest(
    remote: remote,
    portfolioId: portfolioId,
    context: kSuggestCtxWhatIfSymbol,
    query: query,
    limit: limit,
    selectLabel: false,
  );
  if (!includeMarket || fromBackend.length >= limit) {
    return fromBackend;
  }

  final seen = <String>{
    for (final d in fromBackend)
      (d.key?.symbol ?? '').trim().toUpperCase(),
  }..removeWhere((s) => s.isEmpty);

  List<market.SecurityDocument> fromMarket = const [];
  try {
    final search = marketSearch ?? searchMarketSecurities;
    fromMarket = await search(query) ?? const [];
  } catch (_) {
    fromMarket = const [];
  }

  final merged = [...fromBackend];
  for (final doc in fromMarket) {
    final sym = (doc.key?.symbol ?? '').trim().toUpperCase();
    if (sym.isEmpty || seen.contains(sym)) continue;
    seen.add(sym);
    merged.add(doc);
    if (merged.length >= limit) break;
  }
  return merged;
}

/// Class Add name — wire-specific templates + matching holdings from backend.
Future<List<market.SecurityDocument>> searchClassAddNames({
  required PortfolioRemoteDataSource remote,
  required String portfolioId,
  required String query,
  required String wire,
  int limit = 8,
}) {
  return searchIntelligenceSuggest(
    remote: remote,
    portfolioId: portfolioId,
    context: kSuggestCtxClassAddName,
    query: query,
    wire: wire,
    limit: limit,
  );
}

Future<List<market.SecurityDocument>?> searchMarketSecurities(String query) async {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const [];

  try {
    final token = await GetIt.I<SecureStorageService>().getAccessToken();
    final client = market.ApiClient(basePath: EnvDomains.market);
    if (token != null && token.isNotEmpty) {
      client.addDefaultHeader('Authorization', 'Bearer $token');
    }
    return await market.SecurityExplorerApi(client).search(
      trimmed,
      smartRecommendations: true,
      category: 'STOCKS',
      limit: 8,
    );
  } catch (_) {
    return null;
  }
}
