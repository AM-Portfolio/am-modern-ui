import 'package:am_common/am_common.dart';
import 'package:am_market_sdk/market/api.dart' as market;
import 'package:get_it/get_it.dart';

/// GICS-style + common AM/X-Ray sector labels for typeahead beyond holdings.
const List<String> kMarketSectorCatalog = [
  'Energy',
  'Materials',
  'Industrials',
  'Consumer Discretionary',
  'Consumer Staples',
  'Health Care',
  'Healthcare',
  'Financials',
  'Financial Services',
  'Information Technology',
  'Communication Services',
  'Utilities',
  'Real Estate',
  'Commodities',
  'Banking',
  'IT',
  'Pharmaceuticals',
  'Automobiles',
  'Telecommunications',
  'Metals & Mining',
  'Infrastructure',
  'Manufacturing',
  'Agriculture',
  'Technology',
  'Consumer Goods (FMCG)',
  'Consumer Services',
];

List<String> marketSectorCatalogLabels() {
  final set = <String>{};
  for (final s in kMarketSectorCatalog) {
    if (s.trim().isNotEmpty) set.add(s.trim());
  }
  for (final t in SectorType.allSectors) {
    if (t == SectorType.all || t == SectorType.other || t == SectorType.noGroup) {
      continue;
    }
    final name = t.displayName.trim();
    if (name.isNotEmpty) set.add(name);
  }
  final list = set.toList()..sort();
  return list;
}

bool labelMatchesQuery(String label, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return false;
  return label.toLowerCase().contains(q);
}

List<String> filterLabelsByQuery(Iterable<String> labels, String query) {
  return [
    for (final label in labels)
      if (labelMatchesQuery(label, query)) label.trim(),
  ];
}

/// Prefer [preferred] order, then [rest], case-insensitive dedupe, capped.
List<String> mergePreferFirst(
  Iterable<String> preferred,
  Iterable<String> rest, {
  int limit = 8,
}) {
  final out = <String>[];
  final seen = <String>{};

  void addAll(Iterable<String> source) {
    for (final raw in source) {
      final label = raw.trim();
      if (label.isEmpty) continue;
      final key = label.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(label);
      if (out.length >= limit) return;
    }
  }

  addAll(preferred);
  if (out.length < limit) addAll(rest);
  return out;
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

List<market.SecurityDocument> labelsToSecurityDocuments(Iterable<String> labels) {
  return [for (final label in labels) labelToSecurityDocument(label)];
}

/// Holdings-first symbol suggestions, then market securities search.
Future<List<market.SecurityDocument>> searchSymbolsHoldingsFirst({
  required String query,
  required List<({String symbol, String name})> holdings,
  Future<List<market.SecurityDocument>?> Function(String query)? marketSearch,
  int limit = 8,
}) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final fromHoldings = <market.SecurityDocument>[];
  final seen = <String>{};
  for (final h in holdings) {
    final sym = h.symbol.trim().toUpperCase();
    if (sym.isEmpty) continue;
    final name = h.name.trim();
    if (!labelMatchesQuery(sym, q) &&
        (name.isEmpty || !labelMatchesQuery(name, q))) {
      continue;
    }
    if (seen.contains(sym)) continue;
    seen.add(sym);
    fromHoldings.add(
      labelToSecurityDocument(sym, companyName: name.isEmpty ? sym : name),
    );
    if (fromHoldings.length >= limit) {
      return fromHoldings;
    }
  }

  List<market.SecurityDocument> fromMarket = const [];
  try {
    final search = marketSearch ?? searchMarketSecurities;
    final results = await search(q);
    fromMarket = results ?? const [];
  } catch (_) {
    fromMarket = const [];
  }

  final merged = <market.SecurityDocument>[...fromHoldings];
  for (final doc in fromMarket) {
    final sym = (doc.key?.symbol ?? '').trim().toUpperCase();
    if (sym.isEmpty || seen.contains(sym)) continue;
    seen.add(sym);
    merged.add(doc);
    if (merged.length >= limit) break;
  }
  return merged;
}

Future<List<market.SecurityDocument>> searchSectorsHoldingsFirst({
  required String query,
  required Iterable<String> holdingsSectors,
  Iterable<String>? marketCatalog,
  int limit = 8,
}) async {
  final q = query.trim();
  if (q.isEmpty) return const [];

  final preferred = filterLabelsByQuery(holdingsSectors, q);
  final catalog = marketCatalog ?? marketSectorCatalogLabels();
  final rest = filterLabelsByQuery(catalog, q);
  return labelsToSecurityDocuments(
    mergePreferFirst(preferred, rest, limit: limit),
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
