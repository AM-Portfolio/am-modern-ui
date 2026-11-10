import 'package:am_common/am_common.dart';
import 'package:am_news_ui/data/repositories/news_repository.dart';
import 'package:am_news_ui/domain/models/news_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final newsRepositoryProvider = FutureProvider<NewsRepository>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final newsBase = config.api.news?.baseUrl ?? EnvDomains.news;
  return NewsRepository(
    newsClient: ApiClient(baseUrl: newsBase),
    portfolioClient: ApiClient(baseUrl: config.api.portfolio.baseUrl),
    holdingsResource: config.api.portfolio.holdingsResource,
    // Dig insight routinely needs >3s when symbols are attached.
    timeout: const Duration(seconds: 20),
  );
});

/// Dashboard Market Intelligence.
///
/// Load current affairs first (`symbols: []`) — that is the payload dig already
/// returns successfully — then optionally merge holdings-scoped news. Never
/// surface AsyncError when affaires are available.
final newsInsightProvider = FutureProvider<InsightNews>((ref) async {
  if (!ref.watch(newsUiSurfaceEnabledProvider(NewsUiSurface.dashboard))) {
    return const InsightNews();
  }

  final repo = await ref.watch(newsRepositoryProvider.future);

  InsightNews base;
  try {
    base = await repo.insight(const []);
  } catch (e, st) {
    AppLogger.warning(
      'newsInsightProvider: affaires insight failed: $e',
      tag: 'News',
      error: e,
      stackTrace: st,
    );
    return const InsightNews();
  }

  // Best-effort holdings enrichment; keep affaires if this fails.
  try {
    final symbols = await repo.holdingsSymbols(cap: 25);
    if (symbols.isEmpty) return base;
    final enriched = await repo.insight(symbols);
    if (enriched.currentAffairs.isEmpty && enriched.holdings.isEmpty) {
      return base;
    }
    return InsightNews(
      currentAffairs: enriched.currentAffairs.isNotEmpty
          ? enriched.currentAffairs
          : base.currentAffairs,
      holdings: enriched.holdings,
      pendingIngest: enriched.pendingIngest,
      missingSymbols: enriched.missingSymbols,
    );
  } catch (_) {
    return base;
  }
});

String _symbolsKey(List<String> symbols) {
  final normalized = symbols
      .map((s) => s.trim().toUpperCase())
      .where((s) => s.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return normalized.join(',');
}

/// Insight for an explicit symbol list (host supplies symbols).
final newsInsightForSymbolsProvider =
    FutureProvider.family<InsightNews, String>((ref, key) async {
  if (key.isEmpty) return const InsightNews();
  final repo = await ref.watch(newsRepositoryProvider.future);
  final symbols = key.split(',').where((s) => s.isNotEmpty).toList();
  try {
    return await repo.insight(symbols);
  } catch (_) {
    try {
      return await repo.insight(const []);
    } catch (_) {
      return const InsightNews();
    }
  }
});

/// Helper for hosts: stable family key from symbols.
String newsSymbolsProviderKey(List<String> symbols) => _symbolsKey(symbols);
